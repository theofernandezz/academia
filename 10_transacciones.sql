-- =============================================
-- TRANSACCIONES - 10 PROCEDIMIENTOS
-- Actividad 2: Gestion Academica
-- Cada procedimiento utiliza COMMIT/ROLLBACK para garantizar atomicidad.
-- =============================================

DELIMITER $$

-- =============================================
-- 7.1 SP_TX_MatricularYGenerarFactura
-- Registra una matricula, factura e impacto en cuenta corriente.
-- =============================================
DROP PROCEDURE IF EXISTS SP_TX_MatricularYGenerarFactura$$
CREATE PROCEDURE SP_TX_MatricularYGenerarFactura(
    IN p_id_estudiante INT,
    IN p_anio INT,
    IN p_monto DECIMAL(10,2)
)
BEGIN
    DECLARE v_id_factura INT;
    DECLARE v_saldo_anterior DECIMAL(10,2);
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    START TRANSACTION;

    INSERT INTO Factura (id_estudiante, fecha_emision, monto_total, estado_pago)
    VALUES (p_id_estudiante, CURRENT_DATE, p_monto, 'Pendiente');
    SET v_id_factura = LAST_INSERT_ID();

    INSERT INTO ItemFactura (id_factura, concepto, monto)
    VALUES (v_id_factura, CONCAT('Matricula ', p_anio), p_monto);

    INSERT INTO Matriculacion (id_estudiante, anio, monto_matricula, fecha_matriculacion, id_factura)
    VALUES (p_id_estudiante, p_anio, p_monto, CURRENT_DATE, v_id_factura);

    SET v_saldo_anterior = 0;
    SELECT COALESCE(saldo,0)
    INTO v_saldo_anterior
    FROM CuentaCorriente
    WHERE id_estudiante = p_id_estudiante
    ORDER BY fecha_movimiento DESC, id_movimiento DESC
    LIMIT 1;
    SET v_saldo_anterior = COALESCE(v_saldo_anterior, 0);

    INSERT INTO CuentaCorriente (
        id_estudiante, fecha_movimiento, concepto,
        debe, haber, saldo, id_factura
    ) VALUES (
        p_id_estudiante, CURRENT_DATE, CONCAT('Matricula ', p_anio),
        p_monto, 0, v_saldo_anterior + p_monto, v_id_factura
    );

    COMMIT;
END$$

-- =============================================
-- 7.2 SP_TX_InscribirConVacantes
-- Inscribe a un estudiante validando cupos disponibles.
-- =============================================
DROP PROCEDURE IF EXISTS SP_TX_InscribirConVacantes$$
CREATE PROCEDURE SP_TX_InscribirConVacantes(
    IN p_id_estudiante INT,
    IN p_id_curso INT,
    IN p_id_cuatrimestre INT
)
BEGIN
    DECLARE v_cupo_maximo INT;
    DECLARE v_inscriptos INT;
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    START TRANSACTION;

    SELECT cupo_maximo INTO v_cupo_maximo
    FROM Cursos
    WHERE id_curso = p_id_curso
    FOR UPDATE;

    SELECT COUNT(*) INTO v_inscriptos
    FROM Inscripciones
    WHERE id_curso = p_id_curso
      AND id_cuatrimestre = p_id_cuatrimestre;

    IF v_inscriptos >= v_cupo_maximo THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'No hay vacantes disponibles';
    END IF;

    INSERT INTO Inscripciones (
        id_estudiante, id_curso, fecha_inscripcion,
        id_cuatrimestre
    ) VALUES (
        p_id_estudiante, p_id_curso, CURRENT_DATE,
        p_id_cuatrimestre
    );

    COMMIT;
END$$

-- =============================================
-- 7.3 SP_TX_RegistrarPagoCompleto
-- Registra el pago de una factura, actualiza estado y cuenta corriente.
-- =============================================
DROP PROCEDURE IF EXISTS SP_TX_RegistrarPagoCompleto$$
CREATE PROCEDURE SP_TX_RegistrarPagoCompleto(
    IN p_id_estudiante INT,
    IN p_id_factura INT,
    IN p_monto DECIMAL(10,2)
)
BEGIN
    DECLARE v_total_pendiente DECIMAL(10,2);
    DECLARE v_saldo_anterior DECIMAL(10,2);
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    START TRANSACTION;

    SELECT monto_total INTO v_total_pendiente
    FROM Factura
    WHERE id_factura = p_id_factura
      AND id_estudiante = p_id_estudiante
    FOR UPDATE;

    IF v_total_pendiente IS NULL THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Factura no encontrada';
    END IF;

    SET v_saldo_anterior = 0;
    SELECT COALESCE(saldo,0)
    INTO v_saldo_anterior
    FROM CuentaCorriente
    WHERE id_estudiante = p_id_estudiante
    ORDER BY fecha_movimiento DESC, id_movimiento DESC
    LIMIT 1;
    SET v_saldo_anterior = COALESCE(v_saldo_anterior, 0);

    INSERT INTO CuentaCorriente(
        id_estudiante, fecha_movimiento, concepto,
        debe, haber, saldo, id_factura
    ) VALUES (
        p_id_estudiante, CURRENT_DATE, CONCAT('Pago factura ', p_id_factura),
        0, p_monto, v_saldo_anterior - p_monto, p_id_factura
    );

    UPDATE Factura
    SET estado_pago = CASE
        WHEN p_monto >= v_total_pendiente THEN 'Pagado'
        ELSE 'Pendiente'
    END
    WHERE id_factura = p_id_factura;

    UPDATE Cuota
    SET estado_pago = 'Pagado'
    WHERE id_factura = p_id_factura
      AND p_monto >= v_total_pendiente;

    COMMIT;
END$$

-- =============================================
-- 7.4 SP_TX_GenerarCuotasMasivas
-- Genera cuotas para todos los estudiantes en el mes indicado.
-- =============================================
DROP PROCEDURE IF EXISTS SP_TX_GenerarCuotasMasivas$$
CREATE PROCEDURE SP_TX_GenerarCuotasMasivas(
    IN p_mes INT,
    IN p_anio INT
)
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    START TRANSACTION;

    CALL SP_GenerarCuotasMensuales(p_mes, p_anio);

    COMMIT;
END$$

-- =============================================
-- 7.5 SP_TX_BajaEstudianteSaldoCero
-- Da de baja a un estudiante siempre que la cuenta corriente este al dia.
-- =============================================
DROP PROCEDURE IF EXISTS SP_TX_BajaEstudianteSaldoCero$$
CREATE PROCEDURE SP_TX_BajaEstudianteSaldoCero(
    IN p_id_estudiante INT
)
BEGIN
    DECLARE v_saldo DECIMAL(10,2);
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    START TRANSACTION;

    SELECT COALESCE(SUM(debe - haber),0)
    INTO v_saldo
    FROM CuentaCorriente
    WHERE id_estudiante = p_id_estudiante
    FOR UPDATE;

    IF v_saldo <> 0 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'La cuenta corriente no esta en cero';
    END IF;

    UPDATE Estudiantes
    SET estado_baja = 1
    WHERE id_estudiante = p_id_estudiante;

    COMMIT;
END$$

-- =============================================
-- 7.6 SP_TX_RegistrarNotaYActualizar
-- Registra una nota y actualiza nota_final dentro de la misma transaccion.
-- =============================================
DROP PROCEDURE IF EXISTS SP_TX_RegistrarNotaYActualizar$$
CREATE PROCEDURE SP_TX_RegistrarNotaYActualizar(
    IN p_id_estudiante INT,
    IN p_id_curso INT,
    IN p_tipo VARCHAR(20),
    IN p_nota DECIMAL(4,2)
)
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    START TRANSACTION;

    CALL SP_CargarNota(p_id_estudiante, p_id_curso, p_tipo, p_nota);

    COMMIT;
END$$

-- =============================================
-- 7.7 SP_TX_GenerarInteresesMora
-- Genera intereses en cuenta corriente para cuotas vencidas.
-- =============================================
DROP PROCEDURE IF EXISTS SP_TX_GenerarInteresesMora$$
CREATE PROCEDURE SP_TX_GenerarInteresesMora(
    IN p_anio INT
)
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    START TRANSACTION;

    CALL SP_CalcularInteresesMora();

    COMMIT;
END$$

-- =============================================
-- 7.8 SP_TX_EmitirFacturaCuotasImpagas
-- Agrupa cuotas impagas de un mes y genera una factura con cargo correspondiente.
-- =============================================
DROP PROCEDURE IF EXISTS SP_TX_EmitirFacturaCuotasImpagas$$
CREATE PROCEDURE SP_TX_EmitirFacturaCuotasImpagas(
    IN p_id_estudiante INT,
    IN p_mes INT,
    IN p_anio INT
)
BEGIN
    DECLARE v_total DECIMAL(10,2);
    DECLARE v_id_factura INT;
    DECLARE v_saldo_anterior DECIMAL(10,2);
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    START TRANSACTION;

    SELECT COALESCE(SUM(monto_cuota),0)
    INTO v_total
    FROM Cuota
    WHERE id_estudiante = p_id_estudiante
      AND estado_pago = 'Pendiente'
      AND mes = p_mes
      AND anio = p_anio
    FOR UPDATE;

    IF v_total = 0 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'No hay cuotas impagas para facturar';
    END IF;

    INSERT INTO Factura(id_estudiante, fecha_emision, monto_total, estado_pago)
    VALUES (p_id_estudiante, CURRENT_DATE, v_total, 'Pendiente');
    SET v_id_factura = LAST_INSERT_ID();

    INSERT INTO ItemFactura(id_factura, concepto, monto)
    SELECT v_id_factura,
           CONCAT('Cuotas impagas ', p_mes, '/', p_anio),
           monto_cuota
    FROM Cuota
    WHERE id_estudiante = p_id_estudiante
      AND estado_pago = 'Pendiente'
      AND mes = p_mes
      AND anio = p_anio;

    UPDATE Cuota
    SET id_factura = v_id_factura
    WHERE id_estudiante = p_id_estudiante
      AND estado_pago = 'Pendiente'
      AND mes = p_mes
      AND anio = p_anio;

    SELECT COALESCE(saldo,0)
    INTO v_saldo_anterior
    FROM CuentaCorriente
    WHERE id_estudiante = p_id_estudiante
    ORDER BY fecha_movimiento DESC, id_movimiento DESC
    LIMIT 1;

    INSERT INTO CuentaCorriente(
        id_estudiante, fecha_movimiento, concepto,
        debe, haber, saldo, id_factura
    ) VALUES (
        p_id_estudiante, CURRENT_DATE,
        CONCAT('Cuotas impagas ', p_mes, '/', p_anio),
        v_total, 0, v_saldo_anterior + v_total, v_id_factura
    );

    COMMIT;
END$$

-- =============================================
-- 7.9 SP_TX_ReinscribirEstudiante
-- Reactiva a un estudiante dado de baja y actualiza estado.
-- =============================================
DROP PROCEDURE IF EXISTS SP_TX_ReinscribirEstudiante$$
CREATE PROCEDURE SP_TX_ReinscribirEstudiante(
    IN p_id_estudiante INT
)
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    START TRANSACTION;

    UPDATE Estudiantes
    SET estado_baja = 0
    WHERE id_estudiante = p_id_estudiante;

    COMMIT;
END$$

-- =============================================
-- 7.10 SP_TX_InscribirYGenerarItemFactura
-- Inscribe y crea el item correspondiente dentro de la misma transaccion.
-- =============================================
DROP PROCEDURE IF EXISTS SP_TX_InscribirYGenerarItemFactura$$
CREATE PROCEDURE SP_TX_InscribirYGenerarItemFactura(
    IN p_id_estudiante INT,
    IN p_id_curso INT,
    IN p_id_cuatrimestre INT
)
BEGIN
    DECLARE v_id_factura INT;
    DECLARE v_monto DECIMAL(10,2);
    DECLARE v_saldo_anterior DECIMAL(10,2);
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    START TRANSACTION;

    INSERT INTO Inscripciones (
        id_estudiante, id_curso, fecha_inscripcion, id_cuatrimestre
    ) VALUES (
        p_id_estudiante, p_id_curso, CURRENT_DATE, p_id_cuatrimestre
    );

    SELECT m.costo_curso_mensual
    INTO v_monto
    FROM Cursos c
    JOIN Materias m ON m.id_materia = c.id_materia
    WHERE c.id_curso = p_id_curso;

    INSERT INTO Factura(id_estudiante, fecha_emision, monto_total, estado_pago)
    VALUES (p_id_estudiante, CURRENT_DATE, v_monto, 'Pendiente');
    SET v_id_factura = LAST_INSERT_ID();

    INSERT INTO ItemFactura(id_factura, concepto, monto)
    VALUES (v_id_factura, CONCAT('Inscripcion curso ', p_id_curso), v_monto);

    SET v_saldo_anterior = 0;
    SELECT COALESCE(saldo,0)
    INTO v_saldo_anterior
    FROM CuentaCorriente
    WHERE id_estudiante = p_id_estudiante
    ORDER BY fecha_movimiento DESC, id_movimiento DESC
    LIMIT 1;
    SET v_saldo_anterior = COALESCE(v_saldo_anterior, 0);

    INSERT INTO CuentaCorriente(
        id_estudiante, fecha_movimiento, concepto,
        debe, haber, saldo, id_factura
    ) VALUES (
        p_id_estudiante, CURRENT_DATE,
        CONCAT('Inscripcion curso ', p_id_curso),
        v_monto, 0, v_saldo_anterior + v_monto, v_id_factura
    );

    COMMIT;
END$$

DELIMITER ;

-- =============================================
-- SCRIPT COMPLETADO
-- =============================================
-- 10 procedimientos transaccionales creados (revisar cada flujo antes de usar en produccion).
