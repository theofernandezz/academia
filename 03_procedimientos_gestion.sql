-- =============================================
-- PROCEDIMIENTOS ALMACENADOS - GESTIÓN ACADÉMICA
-- Actividad 2: Gestión Académica
-- SQL Estándar (compatible MySQL)
-- =============================================
-- Procedimientos 1.2 al 1.9

DELIMITER $$

-- =============================================
-- 1.2 SP: Dar de Baja Alumno
-- =============================================
DROP PROCEDURE IF EXISTS SP_BajaAlumno$$
CREATE PROCEDURE SP_BajaAlumno(
    IN p_id_estudiante INT
)
BEGIN
    DECLARE v_error_msg VARCHAR(500);
    DECLARE v_saldo DECIMAL(10,2);
    DECLARE v_estado_baja TINYINT;
    
    -- Verificar que el estudiante existe
    IF NOT EXISTS (SELECT 1 FROM Estudiantes WHERE id_estudiante = p_id_estudiante) THEN
        SET v_error_msg = CONCAT('No existe el estudiante con ID: ', p_id_estudiante);
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = v_error_msg;
    END IF;
    
    -- Verificar si ya está de baja
    SELECT estado_baja INTO v_estado_baja 
    FROM Estudiantes 
    WHERE id_estudiante = p_id_estudiante;
    
    IF v_estado_baja = 1 THEN
        SET v_error_msg = 'El estudiante ya se encuentra dado de baja';
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = v_error_msg;
    END IF;
    
    -- Calcular saldo de cuenta corriente
    SELECT COALESCE(SUM(debe - haber), 0) INTO v_saldo
    FROM CuentaCorriente
    WHERE id_estudiante = p_id_estudiante;
    
    -- Validar que la cuenta corriente esté en cero
    IF v_saldo != 0 THEN
        SET v_error_msg = CONCAT('No se puede dar de baja. Saldo pendiente: $', v_saldo);
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = v_error_msg;
    END IF;
    
    -- Dar de baja al estudiante
    UPDATE Estudiantes 
    SET estado_baja = 1 
    WHERE id_estudiante = p_id_estudiante;
    
    SELECT CONCAT('Estudiante ID ', p_id_estudiante, ' dado de baja correctamente') AS mensaje;
END$$

-- =============================================
-- 1.3 SP: Dar de Alta Alumno
-- =============================================
DROP PROCEDURE IF EXISTS SP_AltaAlumno$$
CREATE PROCEDURE SP_AltaAlumno(
    IN p_id_estudiante INT
)
BEGIN
    DECLARE v_error_msg VARCHAR(500);
    DECLARE v_estado_baja TINYINT;
    
    -- Verificar que el estudiante existe
    IF NOT EXISTS (SELECT 1 FROM Estudiantes WHERE id_estudiante = p_id_estudiante) THEN
        SET v_error_msg = CONCAT('No existe el estudiante con ID: ', p_id_estudiante);
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = v_error_msg;
    END IF;
    
    -- Verificar si está de baja
    SELECT estado_baja INTO v_estado_baja 
    FROM Estudiantes 
    WHERE id_estudiante = p_id_estudiante;
    
    IF v_estado_baja = 0 THEN
        SET v_error_msg = 'El estudiante ya se encuentra activo';
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = v_error_msg;
    END IF;
    
    -- Dar de alta al estudiante
    UPDATE Estudiantes 
    SET estado_baja = 0 
    WHERE id_estudiante = p_id_estudiante;
    
    SELECT CONCAT('Estudiante ID ', p_id_estudiante, ' dado de alta correctamente') AS mensaje;
END$$

-- =============================================
-- 1.4 SP: Matricular Alumno
-- =============================================
DROP PROCEDURE IF EXISTS SP_MatricularAlumno$$
CREATE PROCEDURE SP_MatricularAlumno(
    IN p_id_estudiante INT,
    IN p_anio INT,
    IN p_monto_matricula DECIMAL(10,2)
)
BEGIN
    DECLARE v_error_msg VARCHAR(500);
    DECLARE v_estado_baja TINYINT;
    DECLARE v_id_factura INT;
    DECLARE v_saldo_anterior DECIMAL(10,2);
    
    -- Validaciones básicas
    IF p_monto_matricula <= 0 THEN
        SET v_error_msg = 'El monto de matrícula debe ser mayor a cero';
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = v_error_msg;
    END IF;
    
    -- Verificar que el estudiante existe
    IF NOT EXISTS (SELECT 1 FROM Estudiantes WHERE id_estudiante = p_id_estudiante) THEN
        SET v_error_msg = CONCAT('No existe el estudiante con ID: ', p_id_estudiante);
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = v_error_msg;
    END IF;
    
    -- Verificar que el estudiante no esté de baja
    SELECT estado_baja INTO v_estado_baja 
    FROM Estudiantes 
    WHERE id_estudiante = p_id_estudiante;
    
    IF v_estado_baja = 1 THEN
        SET v_error_msg = 'No se puede matricular un estudiante dado de baja';
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = v_error_msg;
    END IF;
    
    -- Verificar que no exista matrícula para ese año
    IF EXISTS (SELECT 1 FROM Matriculacion 
               WHERE id_estudiante = p_id_estudiante AND anio = p_anio) THEN
        SET v_error_msg = CONCAT('El estudiante ya tiene una matrícula para el año ', p_anio);
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = v_error_msg;
    END IF;
    
    -- Crear factura
    INSERT INTO Factura (id_estudiante, fecha_emision, monto_total, estado_pago)
    VALUES (p_id_estudiante, CURRENT_DATE, p_monto_matricula, 'Pendiente');
    
    SET v_id_factura = LAST_INSERT_ID();
    
    -- Crear ítem de factura
    INSERT INTO ItemFactura (id_factura, concepto, monto)
    VALUES (v_id_factura, CONCAT('Matrícula año ', p_anio), p_monto_matricula);
    
    -- Crear matrícula
    INSERT INTO Matriculacion (id_estudiante, anio, monto_matricula, fecha_matriculacion, id_factura)
    VALUES (p_id_estudiante, p_anio, p_monto_matricula, CURRENT_DATE, v_id_factura);
    
    -- Obtener saldo anterior de cuenta corriente
    SELECT COALESCE(saldo, 0) INTO v_saldo_anterior
    FROM CuentaCorriente
    WHERE id_estudiante = p_id_estudiante
    ORDER BY id_movimiento DESC
    LIMIT 1;
    
    -- Registrar en cuenta corriente (DEBE = cargo)
    INSERT INTO CuentaCorriente (id_estudiante, fecha_movimiento, concepto, debe, haber, saldo, id_factura)
    VALUES (p_id_estudiante, CURRENT_DATE, CONCAT('Matrícula año ', p_anio), 
            p_monto_matricula, 0, v_saldo_anterior + p_monto_matricula, v_id_factura);
    
    SELECT LAST_INSERT_ID() AS id_matriculacion, 
           v_id_factura AS id_factura,
           'Matrícula registrada correctamente' AS mensaje;
END$$

-- =============================================
-- 1.5 SP: Inscribir Alumno a Curso
-- =============================================
DROP PROCEDURE IF EXISTS SP_InscribirAlumno$$
CREATE PROCEDURE SP_InscribirAlumno(
    IN p_id_estudiante INT,
    IN p_id_curso INT
)
BEGIN
    DECLARE v_error_msg VARCHAR(500);
    DECLARE v_estado_baja TINYINT;
    DECLARE v_id_materia INT;
    DECLARE v_id_cuatrimestre INT;
    DECLARE v_inscriptos INT;
    DECLARE v_cupo_maximo INT;
    
    -- Verificar que el estudiante existe
    IF NOT EXISTS (SELECT 1 FROM Estudiantes WHERE id_estudiante = p_id_estudiante) THEN
        SET v_error_msg = CONCAT('No existe el estudiante con ID: ', p_id_estudiante);
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = v_error_msg;
    END IF;
    
    -- Verificar que el curso existe
    IF NOT EXISTS (SELECT 1 FROM Cursos WHERE id_curso = p_id_curso) THEN
        SET v_error_msg = CONCAT('No existe el curso con ID: ', p_id_curso);
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = v_error_msg;
    END IF;
    
    -- Verificar que el estudiante no esté de baja
    SELECT estado_baja INTO v_estado_baja 
    FROM Estudiantes 
    WHERE id_estudiante = p_id_estudiante;
    
    IF v_estado_baja = 1 THEN
        SET v_error_msg = 'No se puede inscribir un estudiante dado de baja';
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = v_error_msg;
    END IF;
    
    -- Obtener materia del curso
    SELECT id_materia INTO v_id_materia
    FROM Cursos
    WHERE id_curso = p_id_curso;
    
    -- Obtener cuatrimestre actual (asumimos el más reciente)
    SELECT id_cuatrimestre INTO v_id_cuatrimestre
    FROM Cuatrimestre
    WHERE CURRENT_DATE BETWEEN fecha_inicio AND fecha_fin
    LIMIT 1;
    
    IF v_id_cuatrimestre IS NULL THEN
        SET v_error_msg = 'No existe un cuatrimestre activo en este momento';
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = v_error_msg;
    END IF;
    
    -- Verificar que no esté inscripto en ese mismo curso
    IF EXISTS (SELECT 1 FROM Inscripciones 
               WHERE id_estudiante = p_id_estudiante 
               AND id_curso = p_id_curso) THEN
        SET v_error_msg = 'El estudiante ya está inscripto en este curso';
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = v_error_msg;
    END IF;
    
    -- Verificar que no esté inscripto en otro curso de la misma materia en ese cuatrimestre
    IF EXISTS (
        SELECT 1 
        FROM Inscripciones i
        INNER JOIN Cursos c ON i.id_curso = c.id_curso
        WHERE i.id_estudiante = p_id_estudiante
        AND c.id_materia = v_id_materia
        AND i.id_cuatrimestre = v_id_cuatrimestre
    ) THEN
        SET v_error_msg = 'El estudiante ya está inscripto en otro curso de esta materia en el cuatrimestre actual';
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = v_error_msg;
    END IF;
    
    -- Verificar cupo disponible
    SELECT COUNT(*) INTO v_inscriptos
    FROM Inscripciones
    WHERE id_curso = p_id_curso;
    
    SELECT cupo_maximo INTO v_cupo_maximo
    FROM Cursos
    WHERE id_curso = p_id_curso;
    
    IF v_inscriptos >= v_cupo_maximo THEN
        SET v_error_msg = CONCAT('El curso ha alcanzado el cupo máximo (', v_cupo_maximo, ')');
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = v_error_msg;
    END IF;
    
    -- Inscribir al estudiante
    INSERT INTO Inscripciones (
        id_estudiante, 
        id_curso, 
        fecha_inscripcion,
        id_cuatrimestre
    ) VALUES (
        p_id_estudiante,
        p_id_curso,
        CURRENT_DATE,
        v_id_cuatrimestre
    );
    
    SELECT LAST_INSERT_ID() AS id_inscripcion,
           'Estudiante inscripto correctamente' AS mensaje;
END$$

-- =============================================
-- 1.6 SP: Cargar Nota
-- =============================================
DROP PROCEDURE IF EXISTS SP_CargarNota$$
CREATE PROCEDURE SP_CargarNota(
    IN p_id_estudiante INT,
    IN p_id_curso INT,
    IN p_tipo_evaluacion VARCHAR(20), -- 'Evaluacion1', 'Evaluacion2', 'Evaluacion3', 'Recuperatorio'
    IN p_nota DECIMAL(4,2)
)
BEGIN
    DECLARE v_error_msg VARCHAR(500);
    DECLARE v_id_inscripcion INT;
    DECLARE v_nota_eval1 DECIMAL(4,2);
    DECLARE v_nota_eval2 DECIMAL(4,2);
    DECLARE v_nota_eval3 DECIMAL(4,2);
    DECLARE v_notas_menores_4 INT;
    DECLARE v_nota_final DECIMAL(4,2);
    
    -- Validar nota
    IF p_nota < 0 OR p_nota > 10 THEN
        SET v_error_msg = 'La nota debe estar entre 0 y 10';
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = v_error_msg;
    END IF;
    
    -- Verificar que existe la inscripción
    SELECT id_inscripcion INTO v_id_inscripcion
    FROM Inscripciones
    WHERE id_estudiante = p_id_estudiante AND id_curso = p_id_curso;
    
    IF v_id_inscripcion IS NULL THEN
        SET v_error_msg = 'No existe inscripción para ese estudiante en ese curso';
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = v_error_msg;
    END IF;
    
    -- Obtener notas existentes
    SELECT nota_evaluacion_1, nota_evaluacion_2, nota_evaluacion_3
    INTO v_nota_eval1, v_nota_eval2, v_nota_eval3
    FROM Inscripciones
    WHERE id_inscripcion = v_id_inscripcion;
    
    -- Procesar según tipo de evaluación
    IF p_tipo_evaluacion = 'Evaluacion1' THEN
        UPDATE Inscripciones 
        SET nota_evaluacion_1 = p_nota
        WHERE id_inscripcion = v_id_inscripcion;
        
    ELSEIF p_tipo_evaluacion = 'Evaluacion2' THEN
        UPDATE Inscripciones 
        SET nota_evaluacion_2 = p_nota
        WHERE id_inscripcion = v_id_inscripcion;
        
    ELSEIF p_tipo_evaluacion = 'Evaluacion3' THEN
        UPDATE Inscripciones 
        SET nota_evaluacion_3 = p_nota
        WHERE id_inscripcion = v_id_inscripcion;
        
    ELSEIF p_tipo_evaluacion = 'Recuperatorio' THEN
        -- Contar notas menores a 4
        SET v_notas_menores_4 = 0;
        IF v_nota_eval1 IS NOT NULL AND v_nota_eval1 < 4 THEN
            SET v_notas_menores_4 = v_notas_menores_4 + 1;
        END IF;
        IF v_nota_eval2 IS NOT NULL AND v_nota_eval2 < 4 THEN
            SET v_notas_menores_4 = v_notas_menores_4 + 1;
        END IF;
        IF v_nota_eval3 IS NOT NULL AND v_nota_eval3 < 4 THEN
            SET v_notas_menores_4 = v_notas_menores_4 + 1;
        END IF;
        
        -- Validar que al menos una evaluación sea menor a 4
        IF v_notas_menores_4 = 0 THEN
            SET v_error_msg = 'No se puede cargar recuperatorio. No hay evaluaciones menores a 4';
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = v_error_msg;
        END IF;
        
        -- Validar que no haya 2 o más evaluaciones menores a 4
        IF v_notas_menores_4 >= 2 THEN
            SET v_error_msg = 'No se puede cargar recuperatorio. Hay 2 o más evaluaciones menores a 4';
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = v_error_msg;
        END IF;
        
        UPDATE Inscripciones 
        SET nota_recuperatorio = p_nota
        WHERE id_inscripcion = v_id_inscripcion;
        
    ELSE
        SET v_error_msg = 'Tipo de evaluación inválido. Usar: Evaluacion1, Evaluacion2, Evaluacion3, Recuperatorio';
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = v_error_msg;
    END IF;
    
    -- Calcular nota final (promedio de las 3 evaluaciones, reemplazando la menor por el recuperatorio si existe)
    SELECT nota_evaluacion_1, nota_evaluacion_2, nota_evaluacion_3, nota_recuperatorio
    INTO v_nota_eval1, v_nota_eval2, v_nota_eval3, @v_recuperatorio
    FROM Inscripciones
    WHERE id_inscripcion = v_id_inscripcion;
    
    IF v_nota_eval1 IS NOT NULL AND v_nota_eval2 IS NOT NULL AND v_nota_eval3 IS NOT NULL THEN
        IF @v_recuperatorio IS NOT NULL THEN
            -- Reemplazar la nota más baja con el recuperatorio
            SET v_nota_final = (
                GREATEST(v_nota_eval1, @v_recuperatorio) +
                GREATEST(v_nota_eval2, @v_recuperatorio) +
                GREATEST(v_nota_eval3, @v_recuperatorio) -
                @v_recuperatorio
            ) / 3;
        ELSE
            SET v_nota_final = (v_nota_eval1 + v_nota_eval2 + v_nota_eval3) / 3;
        END IF;
        
        UPDATE Inscripciones 
        SET nota_final = v_nota_final
        WHERE id_inscripcion = v_id_inscripcion;
    END IF;
    
    SELECT CONCAT('Nota cargada correctamente para ', p_tipo_evaluacion) AS mensaje,
           v_nota_final AS nota_final_calculada;
END$$

-- =============================================
-- 1.7a SP: Generar Cuotas Mensuales (TODOS los alumnos)
-- =============================================
DROP PROCEDURE IF EXISTS SP_GenerarCuotasMensuales$$
CREATE PROCEDURE SP_GenerarCuotasMensuales(
    IN p_mes INT,
    IN p_anio INT
)
BEGIN
    DECLARE v_error_msg VARCHAR(500);
    DECLARE v_id_cuatrimestre INT;
    DECLARE done INT DEFAULT FALSE;
    DECLARE v_id_estudiante INT;
    DECLARE v_total_generadas INT DEFAULT 0;
    
    DECLARE cur_estudiantes CURSOR FOR
        SELECT DISTINCT e.id_estudiante
        FROM Estudiantes e
        INNER JOIN Inscripciones i ON e.id_estudiante = i.id_estudiante
        WHERE e.estado_baja = 0
        AND i.id_cuatrimestre = v_id_cuatrimestre;
    
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;
    
    -- Validaciones
    IF p_mes < 1 OR p_mes > 12 THEN
        SET v_error_msg = 'El mes debe estar entre 1 y 12';
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = v_error_msg;
    END IF;
    
    -- Obtener cuatrimestre actual
    SELECT id_cuatrimestre INTO v_id_cuatrimestre
    FROM Cuatrimestre
    WHERE p_anio = anio
    AND DATE(CONCAT(p_anio, '-', LPAD(p_mes, 2, '0'), '-01')) BETWEEN fecha_inicio AND fecha_fin
    LIMIT 1;
    
    IF v_id_cuatrimestre IS NULL THEN
        SET v_error_msg = CONCAT('No existe cuatrimestre para el mes ', p_mes, '/', p_anio);
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = v_error_msg;
    END IF;
    
    -- Recorrer todos los estudiantes activos con inscripciones en el cuatrimestre
    OPEN cur_estudiantes;
    
    read_loop: LOOP
        FETCH cur_estudiantes INTO v_id_estudiante;
        IF done THEN
            LEAVE read_loop;
        END IF;
        
        -- Generar cuota individual para cada estudiante
        -- Usamos un bloque para capturar errores sin detener el proceso
        BEGIN
            DECLARE CONTINUE HANDLER FOR SQLEXCEPTION
            BEGIN
                -- Si hay error, continuar con el siguiente
            END;
            
            CALL SP_GenerarCuotaIndividual(v_id_estudiante, p_mes, p_anio);
            SET v_total_generadas = v_total_generadas + 1;
        END;
    END LOOP;
    
    CLOSE cur_estudiantes;
    
    SELECT CONCAT('Cuotas generadas para ', v_total_generadas, ' estudiantes') AS mensaje,
           v_total_generadas AS total_cuotas_generadas;
END$$

-- =============================================
-- 1.7b SP: Generar Cuota Individual
-- =============================================
DROP PROCEDURE IF EXISTS SP_GenerarCuotaIndividual$$
CREATE PROCEDURE SP_GenerarCuotaIndividual(
    IN p_id_estudiante INT,
    IN p_mes INT,
    IN p_anio INT
)
BEGIN
    DECLARE v_error_msg VARCHAR(500);
    DECLARE v_estado_baja TINYINT;
    DECLARE v_id_factura INT;
    DECLARE v_monto_total DECIMAL(10,2);
    DECLARE v_id_cuatrimestre INT;
    DECLARE v_saldo_anterior DECIMAL(10,2);
    DECLARE v_fecha_vencimiento DATE;
    DECLARE done INT DEFAULT FALSE;
    DECLARE v_id_curso INT;
    DECLARE v_monto_cuota DECIMAL(10,2);
    
    DECLARE cur_cursos CURSOR FOR
        SELECT DISTINCT c.id_curso, m.costo_curso_mensual
        FROM Inscripciones i
        INNER JOIN Cursos c ON i.id_curso = c.id_curso
        INNER JOIN Materias m ON c.id_materia = m.id_materia
        WHERE i.id_estudiante = p_id_estudiante
        AND i.id_cuatrimestre = v_id_cuatrimestre;
    
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;
    
    -- Validaciones
    IF p_mes < 1 OR p_mes > 12 THEN
        SET v_error_msg = 'El mes debe estar entre 1 y 12';
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = v_error_msg;
    END IF;
    
    -- Verificar que el estudiante existe
    IF NOT EXISTS (SELECT 1 FROM Estudiantes WHERE id_estudiante = p_id_estudiante) THEN
        SET v_error_msg = CONCAT('No existe el estudiante con ID: ', p_id_estudiante);
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = v_error_msg;
    END IF;
    
    -- Verificar que el estudiante no esté de baja
    SELECT estado_baja INTO v_estado_baja 
    FROM Estudiantes 
    WHERE id_estudiante = p_id_estudiante;
    
    IF v_estado_baja = 1 THEN
        SET v_error_msg = 'No se puede generar cuota para un estudiante dado de baja';
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = v_error_msg;
    END IF;
    
    -- Obtener cuatrimestre actual
    SELECT id_cuatrimestre INTO v_id_cuatrimestre
    FROM Cuatrimestre
    WHERE p_anio = anio
    AND DATE(CONCAT(p_anio, '-', LPAD(p_mes, 2, '0'), '-01')) BETWEEN fecha_inicio AND fecha_fin
    LIMIT 1;
    
    IF v_id_cuatrimestre IS NULL THEN
        SET v_error_msg = CONCAT('No existe cuatrimestre para el mes ', p_mes, '/', p_anio);
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = v_error_msg;
    END IF;
    
    -- Verificar si tiene inscripciones en el cuatrimestre
    IF NOT EXISTS (
        SELECT 1 FROM Inscripciones 
        WHERE id_estudiante = p_id_estudiante 
        AND id_cuatrimestre = v_id_cuatrimestre
    ) THEN
        SET v_error_msg = 'El estudiante no tiene inscripciones en el cuatrimestre actual';
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = v_error_msg;
    END IF;
    
    -- Calcular fecha de vencimiento (día 10 del mes)
    SET v_fecha_vencimiento = DATE(CONCAT(p_anio, '-', LPAD(p_mes, 2, '0'), '-10'));
    
    -- Inicializar monto total
    SET v_monto_total = 0;
    
    -- Crear factura
    INSERT INTO Factura (id_estudiante, fecha_emision, monto_total, estado_pago)
    VALUES (p_id_estudiante, CURRENT_DATE, 0, 'Pendiente');
    
    SET v_id_factura = LAST_INSERT_ID();
    
    -- Generar cuotas por cada curso inscripto
    OPEN cur_cursos;
    
    read_loop: LOOP
        FETCH cur_cursos INTO v_id_curso, v_monto_cuota;
        IF done THEN
            LEAVE read_loop;
        END IF;
        
        -- Verificar que no exista ya la cuota
        IF NOT EXISTS (
            SELECT 1 FROM Cuota 
            WHERE id_estudiante = p_id_estudiante 
            AND id_curso = v_id_curso 
            AND mes = p_mes 
            AND anio = p_anio
        ) THEN
            -- Crear cuota
            INSERT INTO Cuota (
                id_estudiante, id_curso, mes, anio, 
                monto_cuota, fecha_vencimiento, estado_pago, id_factura
            ) VALUES (
                p_id_estudiante, v_id_curso, p_mes, p_anio,
                v_monto_cuota, v_fecha_vencimiento, 'Pendiente', v_id_factura
            );
            
            -- Agregar ítem a factura
            INSERT INTO ItemFactura (id_factura, concepto, monto)
            VALUES (v_id_factura, 
                    CONCAT('Cuota ', p_mes, '/', p_anio, ' - Curso ID ', v_id_curso),
                    v_monto_cuota);
            
            SET v_monto_total = v_monto_total + v_monto_cuota;
        END IF;
    END LOOP;
    
    CLOSE cur_cursos;
    
    -- Actualizar monto total de factura
    UPDATE Factura 
    SET monto_total = v_monto_total 
    WHERE id_factura = v_id_factura;
    
    -- Obtener saldo anterior
    SELECT COALESCE(saldo, 0) INTO v_saldo_anterior
    FROM CuentaCorriente
    WHERE id_estudiante = p_id_estudiante
    ORDER BY id_movimiento DESC
    LIMIT 1;
    
    -- Registrar en cuenta corriente
    INSERT INTO CuentaCorriente (
        id_estudiante, fecha_movimiento, concepto, 
        debe, haber, saldo, id_factura
    ) VALUES (
        p_id_estudiante, CURRENT_DATE, 
        CONCAT('Cuota ', p_mes, '/', p_anio),
        v_monto_total, 0, v_saldo_anterior + v_monto_total, v_id_factura
    );
    
    SELECT v_id_factura AS id_factura,
           v_monto_total AS monto_total,
           'Cuota generada correctamente' AS mensaje;
END$$

-- =============================================
-- 1.8 SP: Calcular Intereses por Mora
-- =============================================
DROP PROCEDURE IF EXISTS SP_CalcularInteresesMora$$
CREATE PROCEDURE SP_CalcularInteresesMora()
BEGIN
    DECLARE done INT DEFAULT FALSE;
    DECLARE v_id_estudiante INT;
    DECLARE v_meses_adeudados INT;
    DECLARE v_monto_adeudado DECIMAL(10,2);
    DECLARE v_tasa_anual DECIMAL(5,2);
    DECLARE v_interes_calculado DECIMAL(10,2);
    DECLARE v_saldo_anterior DECIMAL(10,2);
    DECLARE v_id_factura INT;
    
    DECLARE cur_deudores CURSOR FOR
        SELECT c.id_estudiante, 
               COUNT(DISTINCT CONCAT(c.anio, '-', c.mes)) as meses_adeudados,
               SUM(c.monto_cuota) as monto_adeudado
        FROM Cuota c
        WHERE c.estado_pago = 'Pendiente'
        AND c.fecha_vencimiento < CURRENT_DATE
        GROUP BY c.id_estudiante
        HAVING meses_adeudados > 1;
    
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;
    
    -- Obtener tasa de interés del año actual
    SELECT tasa_mensual INTO v_tasa_anual
    FROM InteresMora
    WHERE anio = YEAR(CURRENT_DATE);
    
    IF v_tasa_anual IS NULL THEN
        SIGNAL SQLSTATE '45000' 
        SET MESSAGE_TEXT = 'No existe tasa de interés configurada para el año actual';
    END IF;
    
    OPEN cur_deudores;
    
    read_loop: LOOP
        FETCH cur_deudores INTO v_id_estudiante, v_meses_adeudados, v_monto_adeudado;
        IF done THEN
            LEAVE read_loop;
        END IF;
        
        -- Calcular interés
        SET v_interes_calculado = v_monto_adeudado * (v_tasa_anual / 100);
        
        -- Crear factura de interés
        INSERT INTO Factura (id_estudiante, fecha_emision, monto_total, estado_pago)
        VALUES (v_id_estudiante, CURRENT_DATE, v_interes_calculado, 'Pendiente');
        
        SET v_id_factura = LAST_INSERT_ID();
        
        -- Agregar ítem
        INSERT INTO ItemFactura (id_factura, concepto, monto)
        VALUES (v_id_factura, 
                CONCAT('Interés por mora - ', v_meses_adeudados, ' meses adeudados'),
                v_interes_calculado);
        
        -- Obtener saldo anterior
        SELECT COALESCE(saldo, 0) INTO v_saldo_anterior
        FROM CuentaCorriente
        WHERE id_estudiante = v_id_estudiante
        ORDER BY id_movimiento DESC
        LIMIT 1;
        
        -- Registrar en cuenta corriente
        INSERT INTO CuentaCorriente (
            id_estudiante, fecha_movimiento, concepto, 
            debe, haber, saldo, id_factura
        ) VALUES (
            v_id_estudiante, CURRENT_DATE, 
            CONCAT('Interés por mora - ', v_meses_adeudados, ' meses'),
            v_interes_calculado, 0, v_saldo_anterior + v_interes_calculado, v_id_factura
        );
    END LOOP;
    
    CLOSE cur_deudores;
    
    SELECT 'Intereses por mora calculados correctamente' AS mensaje;
END$$

-- =============================================
-- 1.9 SP: Registrar Pago
-- =============================================
DROP PROCEDURE IF EXISTS SP_RegistrarPago$$
CREATE PROCEDURE SP_RegistrarPago(
    IN p_id_estudiante INT,
    IN p_monto_pago DECIMAL(10,2),
    IN p_id_factura INT
)
BEGIN
    DECLARE v_error_msg VARCHAR(500);
    DECLARE v_saldo_anterior DECIMAL(10,2);
    DECLARE v_monto_factura DECIMAL(10,2);
    DECLARE v_monto_pendiente DECIMAL(10,2);
    
    -- Validaciones
    IF p_monto_pago <= 0 THEN
        SET v_error_msg = 'El monto del pago debe ser mayor a cero';
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = v_error_msg;
    END IF;
    
    -- Verificar que el estudiante existe
    IF NOT EXISTS (SELECT 1 FROM Estudiantes WHERE id_estudiante = p_id_estudiante) THEN
        SET v_error_msg = CONCAT('No existe el estudiante con ID: ', p_id_estudiante);
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = v_error_msg;
    END IF;
    
    -- Si se especifica factura, validar
    IF p_id_factura IS NOT NULL THEN
        -- Verificar que la factura existe y pertenece al estudiante
        IF NOT EXISTS (
            SELECT 1 FROM Factura 
            WHERE id_factura = p_id_factura 
            AND id_estudiante = p_id_estudiante
        ) THEN
            SET v_error_msg = 'La factura no existe o no pertenece al estudiante';
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = v_error_msg;
        END IF;
        
        -- Obtener monto de la factura
        SELECT monto_total INTO v_monto_factura
        FROM Factura
        WHERE id_factura = p_id_factura;
        
        -- Calcular monto ya pagado de esta factura
        SELECT COALESCE(SUM(haber), 0) INTO v_monto_pendiente
        FROM CuentaCorriente
        WHERE id_estudiante = p_id_estudiante
        AND id_factura = p_id_factura;
        
        SET v_monto_pendiente = v_monto_factura - v_monto_pendiente;
        
        -- Validar que el pago no exceda el monto pendiente
        IF p_monto_pago > v_monto_pendiente THEN
            SET v_error_msg = CONCAT('El pago excede el monto pendiente de la factura ($', v_monto_pendiente, ')');
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = v_error_msg;
        END IF;
        
        -- Si el pago cubre la factura completa, actualizar estado
        IF p_monto_pago = v_monto_pendiente THEN
            UPDATE Factura 
            SET estado_pago = 'Pagado' 
            WHERE id_factura = p_id_factura;
            
            -- Actualizar cuotas relacionadas
            UPDATE Cuota 
            SET estado_pago = 'Pagado' 
            WHERE id_factura = p_id_factura;
        END IF;
    END IF;
    
    -- Obtener saldo anterior
    SELECT COALESCE(saldo, 0) INTO v_saldo_anterior
    FROM CuentaCorriente
    WHERE id_estudiante = p_id_estudiante
    ORDER BY id_movimiento DESC
    LIMIT 1;
    
    -- Registrar pago en cuenta corriente (HABER = abono)
    INSERT INTO CuentaCorriente (
        id_estudiante, fecha_movimiento, concepto, 
        debe, haber, saldo, id_factura
    ) VALUES (
        p_id_estudiante, CURRENT_DATE,
        CONCAT('Pago', IF(p_id_factura IS NOT NULL, CONCAT(' - Factura ', p_id_factura), '')),
        0, p_monto_pago, v_saldo_anterior - p_monto_pago, p_id_factura
    );
    
    SELECT LAST_INSERT_ID() AS id_movimiento,
           v_saldo_anterior - p_monto_pago AS saldo_actual,
           'Pago registrado correctamente' AS mensaje;
END$$

DELIMITER ;

-- =============================================
-- SCRIPT COMPLETADO
-- =============================================
-- Procedimientos de gestión académica creados correctamente (1.2 al 1.9).
-- Total: 9 procedimientos
--   - SP_BajaAlumno (1.2)
--   - SP_AltaAlumno (1.3)
--   - SP_MatricularAlumno (1.4)
--   - SP_InscribirAlumno (1.5)
--   - SP_CargarNota (1.6)
--   - SP_GenerarCuotasMensuales (1.7a) - TODOS los alumnos
--   - SP_GenerarCuotaIndividual (1.7b) - UN alumno
--   - SP_CalcularInteresesMora (1.8)
--   - SP_RegistrarPago (1.9)
