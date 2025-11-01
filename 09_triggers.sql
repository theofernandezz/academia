-- =============================================
-- TRIGGERS - 10 IMPLEMENTACIONES
-- Actividad 2: Gestion Academica
-- Cada trigger atiende una regla de negocio del enunciado.
-- =============================================

DELIMITER $$

-- =============================================
-- 6.1 TRG_CuentaCorriente_AfterInsert_ActualizaCuotas
-- Actualiza el estado de las cuotas asociadas a la factura cuando se registra un pago.
-- =============================================
DROP TRIGGER IF EXISTS TRG_CuentaCorriente_AfterInsert_ActualizaCuotas$$
CREATE TRIGGER TRG_CuentaCorriente_AfterInsert_ActualizaCuotas
AFTER INSERT ON CuentaCorriente
FOR EACH ROW
BEGIN
    DECLARE v_saldo DECIMAL(12,2);

    IF NEW.id_factura IS NOT NULL AND NEW.haber > 0 THEN
        SELECT COALESCE(SUM(debe),0) - COALESCE(SUM(haber),0)
        INTO v_saldo
        FROM CuentaCorriente
        WHERE id_factura = NEW.id_factura;

        IF v_saldo <= 0 THEN
            UPDATE Cuota
            SET estado_pago = 'Pagado'
            WHERE id_factura = NEW.id_factura;
        ELSE
            UPDATE Cuota
            SET estado_pago = 'Pendiente'
            WHERE id_factura = NEW.id_factura;
        END IF;
    END IF;
END$$

-- =============================================
-- 6.2 TRG_Inscripciones_BeforeUpdate_RecalculaNotaFinal
-- Recalcula la nota final cuando se carga/modifica el recuperatorio.
-- =============================================
DROP TRIGGER IF EXISTS TRG_Inscripciones_BeforeUpdate_RecalculaNotaFinal$$
CREATE TRIGGER TRG_Inscripciones_BeforeUpdate_RecalculaNotaFinal
BEFORE UPDATE ON Inscripciones
FOR EACH ROW
BEGIN
    DECLARE v_eval1 DECIMAL(4,2);
    DECLARE v_eval2 DECIMAL(4,2);
    DECLARE v_eval3 DECIMAL(4,2);
    DECLARE v_recup DECIMAL(4,2);
    DECLARE v_min DECIMAL(4,2);
    DECLARE v_sum DECIMAL(10,4);

    IF NEW.nota_recuperatorio IS NOT NULL AND
       (OLD.nota_recuperatorio IS NULL OR OLD.nota_recuperatorio <> NEW.nota_recuperatorio) THEN

        SET v_eval1 = NEW.nota_evaluacion_1;
        SET v_eval2 = NEW.nota_evaluacion_2;
        SET v_eval3 = NEW.nota_evaluacion_3;
        SET v_recup = NEW.nota_recuperatorio;

        IF v_eval1 IS NOT NULL AND v_eval2 IS NOT NULL AND v_eval3 IS NOT NULL THEN
            SET v_min = v_eval1;
            IF v_eval2 < v_min THEN SET v_min = v_eval2; END IF;
            IF v_eval3 < v_min THEN SET v_min = v_eval3; END IF;

            SET v_sum = v_eval1 + v_eval2 + v_eval3 - v_min + v_recup;
            SET NEW.nota_final = ROUND(v_sum / 3, 2);
        END IF;
    END IF;
END$$

-- =============================================
-- 6.3 TRG_Inscripciones_AfterDelete_BajaEstudiante
-- Marca al estudiante como dado de baja si ya no tiene inscripciones activas.
-- =============================================
DROP TRIGGER IF EXISTS TRG_Inscripciones_AfterDelete_BajaEstudiante$$
CREATE TRIGGER TRG_Inscripciones_AfterDelete_BajaEstudiante
AFTER DELETE ON Inscripciones
FOR EACH ROW
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM Inscripciones
        WHERE id_estudiante = OLD.id_estudiante
    ) THEN
        UPDATE Estudiantes
        SET estado_baja = 1
        WHERE id_estudiante = OLD.id_estudiante;
    END IF;
END$$

-- =============================================
-- 6.4 TRG_Factura_AfterInsert_GeneraMovimiento
-- Inserta automaticamente el movimiento en cuenta corriente al emitir una factura.
-- =============================================
DROP TRIGGER IF EXISTS TRG_Factura_AfterInsert_GeneraMovimiento$$
CREATE TRIGGER TRG_Factura_AfterInsert_GeneraMovimiento
AFTER INSERT ON Factura
FOR EACH ROW
BEGIN
    DECLARE v_saldo_anterior DECIMAL(12,2);

    SET v_saldo_anterior = 0;
    SELECT COALESCE(saldo,0)
    INTO v_saldo_anterior
    FROM CuentaCorriente
    WHERE id_estudiante = NEW.id_estudiante
    ORDER BY fecha_movimiento DESC, id_movimiento DESC
    LIMIT 1;
    SET v_saldo_anterior = COALESCE(v_saldo_anterior, 0);

    INSERT INTO CuentaCorriente(
        id_estudiante,
        fecha_movimiento,
        concepto,
        debe,
        haber,
        saldo,
        id_factura
    ) VALUES (
        NEW.id_estudiante,
        NEW.fecha_emision,
        CONCAT('Factura ', NEW.id_factura),
        NEW.monto_total,
        0,
        v_saldo_anterior + NEW.monto_total,
        NEW.id_factura
    );
END$$

-- =============================================
-- 6.5 TRG_Inscripciones_BeforeInsert_NoDuplicadoMateria
-- Impide inscribir al estudiante dos veces en la misma materia y cuatrimestre.
-- =============================================
DROP TRIGGER IF EXISTS TRG_Inscripciones_BeforeInsert_NoDuplicadoMateria$$
CREATE TRIGGER TRG_Inscripciones_BeforeInsert_NoDuplicadoMateria
BEFORE INSERT ON Inscripciones
FOR EACH ROW
BEGIN
    DECLARE v_id_materia INT;

    SELECT id_materia INTO v_id_materia
    FROM Cursos
    WHERE id_curso = NEW.id_curso;

    IF EXISTS (
        SELECT 1
        FROM Inscripciones i
        JOIN Cursos c ON c.id_curso = i.id_curso
        WHERE i.id_estudiante = NEW.id_estudiante
          AND i.id_cuatrimestre = NEW.id_cuatrimestre
          AND c.id_materia = v_id_materia
    ) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'El estudiante ya esta inscripto en esa materia durante el cuatrimestre indicado';
    END IF;
END$$

-- =============================================
-- 6.6 TRG_CuentaCorriente_BeforeInsert_ActualizaFactura
-- Actualiza el estado de la factura segun los pagos registrados.
-- =============================================
DROP TRIGGER IF EXISTS TRG_CuentaCorriente_BeforeInsert_ActualizaFactura$$
CREATE TRIGGER TRG_CuentaCorriente_BeforeInsert_ActualizaFactura
BEFORE INSERT ON CuentaCorriente
FOR EACH ROW
BEGIN
    DECLARE v_total_debe DECIMAL(12,2);
    DECLARE v_total_haber DECIMAL(12,2);
    DECLARE v_estado VARCHAR(20);

    IF NEW.id_factura IS NOT NULL AND NEW.haber > 0 THEN
        SELECT COALESCE(SUM(debe),0), COALESCE(SUM(haber),0)
        INTO v_total_debe, v_total_haber
        FROM CuentaCorriente
        WHERE id_factura = NEW.id_factura;

        SET v_total_haber = v_total_haber + COALESCE(NEW.haber,0);
        SET v_total_debe  = v_total_debe  + COALESCE(NEW.debe,0);

        IF v_total_debe <= v_total_haber THEN
            SET v_estado = 'Pagado';
        ELSEIF v_total_haber > 0 THEN
            SET v_estado = 'Pendiente';
        ELSE
            SET v_estado = 'Pendiente';
        END IF;

        UPDATE Factura
        SET estado_pago = v_estado
        WHERE id_factura = NEW.id_factura;
    END IF;
END$$

-- =============================================
-- 6.7 TRG_Matriculacion_AfterInsert_GeneraCuotasMes
-- Genera automaticamente la cuota mensual si la matriculacion se registra el primer dia del mes.
-- =============================================
DROP TRIGGER IF EXISTS TRG_Matriculacion_AfterInsert_GeneraCuotasMes$$
CREATE TRIGGER TRG_Matriculacion_AfterInsert_GeneraCuotasMes
AFTER INSERT ON Matriculacion
FOR EACH ROW
BEGIN
    DECLARE v_mes INT;
    DECLARE v_anio INT;
    DECLARE v_fecha_venc DATE;

    IF DAY(NEW.fecha_matriculacion) = 1 THEN
        SET v_mes = MONTH(NEW.fecha_matriculacion);
        SET v_anio = YEAR(NEW.fecha_matriculacion);
        SET v_fecha_venc = DATE_ADD(MAKEDATE(v_anio, 1), INTERVAL v_mes-1 MONTH);
        SET v_fecha_venc = DATE_ADD(v_fecha_venc, INTERVAL 9 DAY); -- dia 10 del mes

        INSERT INTO Cuota (
            id_estudiante,
            id_curso,
            mes,
            anio,
            monto_cuota,
            fecha_vencimiento,
            estado_pago,
            id_factura
        )
        SELECT i.id_estudiante,
               i.id_curso,
               v_mes,
               v_anio,
               m.costo_curso_mensual,
               v_fecha_venc,
               'Pendiente',
               NULL
        FROM Inscripciones i
        JOIN Cursos c ON c.id_curso = i.id_curso
        JOIN Materias m ON m.id_materia = c.id_materia
        WHERE i.id_estudiante = NEW.id_estudiante
          AND NOT EXISTS (
              SELECT 1 FROM Cuota q
              WHERE q.id_estudiante = i.id_estudiante
                AND q.id_curso = i.id_curso
                AND q.mes = v_mes
                AND q.anio = v_anio
          );
    END IF;
END$$

-- =============================================
-- 6.8 TRG_Inscripciones_BeforeInsert_EstudianteActivo
-- Impide inscribir a estudiantes dados de baja.
-- =============================================
DROP TRIGGER IF EXISTS TRG_Inscripciones_BeforeInsert_EstudianteActivo$$
CREATE TRIGGER TRG_Inscripciones_BeforeInsert_EstudianteActivo
BEFORE INSERT ON Inscripciones
FOR EACH ROW
BEGIN
    DECLARE v_estado_baja TINYINT;

    SELECT estado_baja INTO v_estado_baja
    FROM Estudiantes
    WHERE id_estudiante = NEW.id_estudiante;

    IF v_estado_baja = 1 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'El estudiante se encuentra dado de baja';
    END IF;
END$$

-- =============================================
-- 6.9 TRG_ItemFactura_AfterInsert_ActualizaTotales
-- Actualiza el monto total de la factura al agregar un item.
-- =============================================
DROP TRIGGER IF EXISTS TRG_ItemFactura_AfterInsert_ActualizaTotales$$
CREATE TRIGGER TRG_ItemFactura_AfterInsert_ActualizaTotales
AFTER INSERT ON ItemFactura
FOR EACH ROW
BEGIN
    UPDATE Factura
    SET monto_total = (
        SELECT COALESCE(SUM(monto),0)
        FROM ItemFactura
        WHERE id_factura = NEW.id_factura
    )
    WHERE id_factura = NEW.id_factura;
END$$

-- =============================================
-- 6.10 TRG_Cuota_AfterUpdate_GeneraInteresMora
-- Registra el interes por mora cuando una cuota pasa a estado Vencido.
-- =============================================
DROP TRIGGER IF EXISTS TRG_Cuota_AfterUpdate_GeneraInteresMora$$
CREATE TRIGGER TRG_Cuota_AfterUpdate_GeneraInteresMora
AFTER UPDATE ON Cuota
FOR EACH ROW
BEGIN
    DECLARE v_tasa DECIMAL(5,2);
    DECLARE v_interes DECIMAL(10,2);
    DECLARE v_saldo_anterior DECIMAL(10,2);

    IF OLD.estado_pago <> 'Vencido' AND NEW.estado_pago = 'Vencido' THEN
        SELECT tasa_mensual
        INTO v_tasa
        FROM InteresMora
        WHERE anio = NEW.anio
        LIMIT 1;

        IF v_tasa IS NULL THEN
            SET v_tasa = 2.50; -- tasa por defecto si no existe configuracion
        END IF;

        SET v_interes = ROUND(NEW.monto_cuota * v_tasa / 100, 2);

        SET v_saldo_anterior = 0;
        SELECT COALESCE(saldo,0)
        INTO v_saldo_anterior
        FROM CuentaCorriente
        WHERE id_estudiante = NEW.id_estudiante
        ORDER BY fecha_movimiento DESC, id_movimiento DESC
        LIMIT 1;
        SET v_saldo_anterior = COALESCE(v_saldo_anterior, 0);

        INSERT INTO CuentaCorriente(
            id_estudiante,
            fecha_movimiento,
            concepto,
            debe,
            haber,
            saldo,
            id_factura
        ) VALUES (
            NEW.id_estudiante,
            CURRENT_DATE,
            CONCAT('Interes por mora cuota ', NEW.mes, '/', NEW.anio),
            v_interes,
            0,
            v_saldo_anterior + v_interes,
            NEW.id_factura
        );
    END IF;
END$$

DELIMITER ;

-- =============================================
-- SCRIPT COMPLETADO
-- =============================================
-- 10 triggers creados conforme a los requisitos especificados.
