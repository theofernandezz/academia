-- =============================================
-- SQL DINAMICO - 10 PROCEDIMIENTOS
-- Actividad 2: Gestion Academica
-- Cada procedimiento construye y ejecuta SQL dinamico controlado.
-- =============================================

DELIMITER $$

-- =============================================
-- 5.1 SP_BuscarEstudiantesCampoVariable
-- =============================================
DROP PROCEDURE IF EXISTS SP_BuscarEstudiantesCampoVariable$$
CREATE PROCEDURE SP_BuscarEstudiantesCampoVariable(
    IN p_campo VARCHAR(50),
    IN p_valor VARCHAR(255)
)
BEGIN
    DECLARE v_sql TEXT;

    IF p_campo NOT IN ('nombre', 'apellido', 'email', 'anio_ingreso') THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Campo invalido. Use nombre, apellido, email o anio_ingreso';
    END IF;

    SET v_sql = CONCAT(
        'SELECT id_estudiante, nombre, apellido, email, anio_ingreso ',
        'FROM Estudiantes WHERE ', p_campo,
        ' LIKE ? ORDER BY ', p_campo, ', id_estudiante'
    );

    SET @sql := NULL;
    SELECT v_sql INTO @sql;
    PREPARE stmt FROM @sql;
    SET @p_valor = CONCAT('%', p_valor, '%');
    EXECUTE stmt USING @p_valor;
    DEALLOCATE PREPARE stmt;
END$$

-- =============================================
-- 5.2 SP_FiltrarInscripcionesPorNotas
-- =============================================
DROP PROCEDURE IF EXISTS SP_FiltrarInscripcionesPorNotas$$
CREATE PROCEDURE SP_FiltrarInscripcionesPorNotas(
    IN p_campo_nota VARCHAR(50),
    IN p_operador VARCHAR(10),
    IN p_valor DECIMAL(4,2)
)
BEGIN
    DECLARE v_sql TEXT;
    DECLARE v_op VARCHAR(10);

    IF p_campo_nota NOT IN ('nota_evaluacion_1', 'nota_evaluacion_2', 'nota_evaluacion_3', 'nota_recuperatorio', 'nota_final') THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Campo de nota invalido';
    END IF;

    SET v_op = UPPER(TRIM(p_operador));

    IF v_op NOT IN ('<', '<=', '>', '>=', '=', '<>', '!=') THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Operador invalido. Use <, <=, >, >=, =, <> o !=';
    END IF;

    SET v_sql = CONCAT(
        'SELECT i.id_estudiante, i.id_curso, i.fecha_inscripcion, ',
        'i.nota_evaluacion_1, i.nota_evaluacion_2, i.nota_evaluacion_3, ',
        'i.nota_recuperatorio, i.nota_final ',
        'FROM Inscripciones i WHERE ',
        p_campo_nota, ' ', v_op, ' ? ',
        'ORDER BY i.fecha_inscripcion DESC'
    );

    SET @sql := NULL;
    SELECT v_sql INTO @sql;
    PREPARE stmt FROM @sql;
    SET @p_valor = p_valor;
    EXECUTE stmt USING @p_valor;
    DEALLOCATE PREPARE stmt;
END$$

-- =============================================
-- 5.3 SP_ListarCursosConMasInscriptos
-- =============================================
DROP PROCEDURE IF EXISTS SP_ListarCursosConMasInscriptos$$
CREATE PROCEDURE SP_ListarCursosConMasInscriptos(
    IN p_min_inscriptos INT,
    IN p_agrupacion VARCHAR(20)
)
BEGIN
    DECLARE v_sql TEXT;
    DECLARE v_group VARCHAR(50);

    IF p_min_inscriptos < 0 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'El minimo de inscriptos debe ser mayor o igual a cero';
    END IF;

    SET v_group = LOWER(TRIM(p_agrupacion));

    CASE v_group
        WHEN 'anio' THEN SET v_group = 'c.anio';
        WHEN 'materia' THEN SET v_group = 'm.nombre';
        WHEN 'profesor' THEN SET v_group = "CONCAT(p.nombre, ' ', p.apellido)";
        ELSE SIGNAL SQLSTATE '45000'
             SET MESSAGE_TEXT = 'Agrupacion invalida. Use anio, materia o profesor';
    END CASE;

    SET v_sql = CONCAT(
        'SELECT ', v_group, ' AS agrupador, COUNT(i.id_estudiante) AS cantidad_inscriptos ',
        'FROM Cursos c ',
        'JOIN Inscripciones i ON i.id_curso = c.id_curso ',
        'JOIN Materias m ON m.id_materia = c.id_materia ',
        'JOIN Profesores p ON p.id_profesor = c.id_profesor ',
        'GROUP BY ', v_group, ' ',
        'HAVING COUNT(i.id_estudiante) > ? ',
        'ORDER BY cantidad_inscriptos DESC, agrupador'
    );

    SET @sql := NULL;
    SELECT v_sql INTO @sql;
    PREPARE stmt FROM @sql;
    SET @p_min = p_min_inscriptos;
    EXECUTE stmt USING @p_min;
    DEALLOCATE PREPARE stmt;
END$$

-- =============================================
-- 5.4 SP_ReporteFacturasAgrupado
-- =============================================
DROP PROCEDURE IF EXISTS SP_ReporteFacturasAgrupado$$
CREATE PROCEDURE SP_ReporteFacturasAgrupado(
    IN p_campo VARCHAR(20)
)
BEGIN
    DECLARE v_sql TEXT;
    DECLARE v_group VARCHAR(50);

    SET v_group = LOWER(TRIM(p_campo));

    CASE v_group
        WHEN 'mes' THEN SET v_group = 'MONTH(f.fecha_emision)';
        WHEN 'estado_pago' THEN SET v_group = 'f.estado_pago';
        WHEN 'estudiante' THEN SET v_group = "CONCAT(e.nombre, ' ', e.apellido)";
        ELSE SIGNAL SQLSTATE '45000'
             SET MESSAGE_TEXT = 'Campo invalido. Use mes, estado_pago o estudiante';
    END CASE;

    SET v_sql = CONCAT(
        'SELECT ', v_group, ' AS agrupador, ',
        'COUNT(*) AS cantidad_facturas, SUM(f.monto_total) AS monto_total ',
        'FROM Factura f ',
        'JOIN Estudiantes e ON e.id_estudiante = f.id_estudiante ',
        'GROUP BY ', v_group, ' ',
        'ORDER BY agrupador'
    );

    SET @sql := NULL;
    SELECT v_sql INTO @sql;
    PREPARE stmt FROM @sql;
    EXECUTE stmt;
    DEALLOCATE PREPARE stmt;
END$$

-- =============================================
-- 5.5 SP_ListarCuotasVencidasOrden
-- =============================================
DROP PROCEDURE IF EXISTS SP_ListarCuotasVencidasOrden$$
CREATE PROCEDURE SP_ListarCuotasVencidasOrden(
    IN p_campo_orden VARCHAR(30)
)
BEGIN
    DECLARE v_sql TEXT;
    DECLARE v_order VARCHAR(50);

    SET v_order = LOWER(TRIM(p_campo_orden));

    CASE v_order
        WHEN 'fecha_vencimiento' THEN SET v_order = 'c.fecha_vencimiento';
        WHEN 'monto' THEN SET v_order = 'c.monto_cuota';
        WHEN 'estado_pago' THEN SET v_order = 'c.estado_pago';
        ELSE SIGNAL SQLSTATE '45000'
             SET MESSAGE_TEXT = 'Campo de orden invalido';
    END CASE;

    SET v_sql = CONCAT(
        'SELECT c.id_cuota, c.id_estudiante, c.id_curso, c.mes, c.anio, ',
        'c.monto_cuota, c.fecha_vencimiento, c.estado_pago ',
        'FROM Cuota c ',
        "WHERE c.estado_pago = 'Vencido' ",
        'ORDER BY ', v_order, ', c.id_cuota'
    );

    SET @sql := NULL;
    SELECT v_sql INTO @sql;
    PREPARE stmt FROM @sql;
    EXECUTE stmt;
    DEALLOCATE PREPARE stmt;
END$$

-- =============================================
-- 5.6 SP_CursosCondicionDinamica
-- =============================================
DROP PROCEDURE IF EXISTS SP_CursosCondicionDinamica$$
CREATE PROCEDURE SP_CursosCondicionDinamica(
    IN p_condicion VARCHAR(255)
)
BEGIN
    DECLARE v_sql TEXT;

    IF p_condicion IS NULL OR TRIM(p_condicion) = '' THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Debe indicar una condicion';
    END IF;

    SET v_sql = CONCAT(
        'SELECT c.id_curso, c.nombre_curso, c.descripcion, c.anio, ',
        'm.nombre AS nombre_materia, m.creditos, m.costo_curso_mensual ',
        'FROM Cursos c ',
        'JOIN Materias m ON m.id_materia = c.id_materia ',
        'WHERE ', p_condicion,
        ' ORDER BY c.nombre_curso'
    );

    SET @sql := NULL;
    SELECT v_sql INTO @sql;
    PREPARE stmt FROM @sql;
    EXECUTE stmt;
    DEALLOCATE PREPARE stmt;
END$$

-- =============================================
-- 5.7 SP_ProfesoresPorCuatrimestreOrden
-- =============================================
DROP PROCEDURE IF EXISTS SP_ProfesoresPorCuatrimestreOrden$$
CREATE PROCEDURE SP_ProfesoresPorCuatrimestreOrden(
    IN p_id_cuatrimestre INT,
    IN p_orden VARCHAR(20)
)
BEGIN
    DECLARE v_sql TEXT;
    DECLARE v_order VARCHAR(50);

    IF p_id_cuatrimestre IS NULL THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Debe indicar un cuatrimestre';
    END IF;

    SET v_order = LOWER(TRIM(p_orden));

    CASE v_order
        WHEN 'nombre' THEN SET v_order = 'p.nombre';
        WHEN 'apellido' THEN SET v_order = 'p.apellido';
        WHEN 'especialidad' THEN SET v_order = 'p.especialidad';
        ELSE SIGNAL SQLSTATE '45000'
             SET MESSAGE_TEXT = 'Orden invalido. Use nombre, apellido o especialidad';
    END CASE;

    SET v_sql = CONCAT(
        'SELECT DISTINCT p.id_profesor, p.nombre, p.apellido, p.especialidad ',
        'FROM Cursos c ',
        'JOIN Profesores p ON p.id_profesor = c.id_profesor ',
        'JOIN Inscripciones i ON i.id_curso = c.id_curso ',
        'WHERE i.id_cuatrimestre = ? ',
        'ORDER BY ', v_order, ', p.id_profesor'
    );

    SET @sql := NULL;
    SELECT v_sql INTO @sql;
    PREPARE stmt FROM @sql;
    SET @p_cuatrimestre = p_id_cuatrimestre;
    EXECUTE stmt USING @p_cuatrimestre;
    DEALLOCATE PREPARE stmt;
END$$

-- =============================================
-- 5.8 SP_MovimientosPorConceptos
-- =============================================
DROP PROCEDURE IF EXISTS SP_MovimientosPorConceptos$$
CREATE PROCEDURE SP_MovimientosPorConceptos(
    IN p_id_estudiante INT,
    IN p_conceptos TEXT
)
BEGIN
    DECLARE v_sql TEXT;

    IF p_id_estudiante IS NULL THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Debe indicar un estudiante';
    END IF;

    IF p_conceptos IS NULL OR TRIM(p_conceptos) = '' THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Debe indicar al menos un concepto';
    END IF;

    SET v_sql = CONCAT(
        'SELECT cc.id_movimiento, cc.fecha_movimiento, cc.concepto, ',
        'cc.debe, cc.haber, cc.saldo, cc.id_factura ',
        'FROM CuentaCorriente cc ',
        'WHERE cc.id_estudiante = ? ',
        'AND cc.concepto IN (', p_conceptos, ') ',
        'ORDER BY cc.fecha_movimiento DESC, cc.id_movimiento DESC'
    );

    SET @sql := NULL;
    SELECT v_sql INTO @sql;
    PREPARE stmt FROM @sql;
    SET @p_est = p_id_estudiante;
    EXECUTE stmt USING @p_est;
    DEALLOCATE PREPARE stmt;
END$$

-- =============================================
-- 5.9 SP_ListarInscripcionesColumnas
-- =============================================
DROP PROCEDURE IF EXISTS SP_ListarInscripcionesColumnas$$
CREATE PROCEDURE SP_ListarInscripcionesColumnas(
    IN p_columnas TEXT
)
BEGIN
    DECLARE v_sql TEXT;

    IF p_columnas IS NULL OR TRIM(p_columnas) = '' THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Debe indicar las columnas a mostrar';
    END IF;

    SET v_sql = CONCAT(
        'SELECT ', p_columnas, ' FROM Inscripciones ORDER BY id_estudiante, id_curso'
    );

    SET @sql := NULL;
    SELECT v_sql INTO @sql;
    PREPARE stmt FROM @sql;
    EXECUTE stmt;
    DEALLOCATE PREPARE stmt;
END$$

-- =============================================
-- 5.10 SP_ListadoEstudiantesFiltrosDinamicos
-- =============================================
DROP PROCEDURE IF EXISTS SP_ListadoEstudiantesFiltrosDinamicos$$
CREATE PROCEDURE SP_ListadoEstudiantesFiltrosDinamicos(
    IN p_condicion VARCHAR(500)
)
BEGIN
    DECLARE v_sql TEXT;

    IF p_condicion IS NULL OR TRIM(p_condicion) = '' THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Debe indicar una condicion';
    END IF;

    SET v_sql = CONCAT(
        'SELECT id_estudiante, nombre, apellido, email, anio_ingreso ',
        'FROM Estudiantes WHERE ', p_condicion,
        ' ORDER BY apellido, nombre'
    );

    SET @sql := NULL;
    SELECT v_sql INTO @sql;
    PREPARE stmt FROM @sql;
    EXECUTE stmt;
    DEALLOCATE PREPARE stmt;
END$$

DELIMITER ;

-- =============================================
-- SCRIPT COMPLETADO
-- =============================================
-- 10 procedimientos con SQL dinamico creados correctamente.
