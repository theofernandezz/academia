-- =============================================
-- CURSORES Y LISTADOS (10 PROCEDIMIENTOS)
-- Actividad 2: Gestion Academica (Cursor desde procedimiento almacenado)
-- Cada procedimiento utiliza un cursor para recorrer datos y devolver un listado.
-- =============================================

DELIMITER $$

-- =============================================
-- 4.1 SP_ListadoEstudiantesNotasFinales
-- =============================================
DROP PROCEDURE IF EXISTS SP_ListadoEstudiantesNotasFinales$$
CREATE PROCEDURE SP_ListadoEstudiantesNotasFinales(
    IN p_id_curso INT,
    IN p_id_cuatrimestre INT
)
BEGIN
    DECLARE v_id_estudiante INT;
    DECLARE v_nombre VARCHAR(100);
    DECLARE v_apellido VARCHAR(100);
    DECLARE v_id_curso INT;
    DECLARE v_nombre_curso VARCHAR(100);
    DECLARE v_id_cuatrimestre INT;
    DECLARE v_nota_final DECIMAL(4,2);
    DECLARE done INT DEFAULT 0;

    DECLARE cur_estudiantes CURSOR FOR
        SELECT e.id_estudiante,
               e.nombre,
               e.apellido,
               c.id_curso,
               c.nombre_curso,
               i.id_cuatrimestre,
               i.nota_final
        FROM Inscripciones i
        INNER JOIN Estudiantes e ON e.id_estudiante = i.id_estudiante
        INNER JOIN Cursos c ON c.id_curso = i.id_curso
        WHERE (p_id_curso IS NULL OR c.id_curso = p_id_curso)
          AND (p_id_cuatrimestre IS NULL OR i.id_cuatrimestre = p_id_cuatrimestre);

    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = 1;

    DROP TEMPORARY TABLE IF EXISTS TMP_ListadoEstudiantesNotas;
    CREATE TEMPORARY TABLE TMP_ListadoEstudiantesNotas (
        id_estudiante INT,
        nombre VARCHAR(100),
        apellido VARCHAR(100),
        id_curso INT,
        nombre_curso VARCHAR(100),
        id_cuatrimestre INT,
        nota_final DECIMAL(4,2)
    );

    SET done = 0;
    OPEN cur_estudiantes;

    read_loop: LOOP
        FETCH cur_estudiantes INTO v_id_estudiante, v_nombre, v_apellido,
                                   v_id_curso, v_nombre_curso,
                                   v_id_cuatrimestre, v_nota_final;
        IF done THEN
            LEAVE read_loop;
        END IF;

        INSERT INTO TMP_ListadoEstudiantesNotas
        VALUES (v_id_estudiante, v_nombre, v_apellido,
                v_id_curso, v_nombre_curso,
                v_id_cuatrimestre, v_nota_final);
    END LOOP;

    CLOSE cur_estudiantes;

    SELECT *
    FROM TMP_ListadoEstudiantesNotas
    ORDER BY nombre_curso, apellido, nombre;
END$$

-- =============================================
-- 4.2 SP_HistorialPagosEstudiante
-- =============================================
DROP PROCEDURE IF EXISTS SP_HistorialPagosEstudiante$$
CREATE PROCEDURE SP_HistorialPagosEstudiante(
    IN p_id_estudiante INT
)
BEGIN
    DECLARE v_id_movimiento INT;
    DECLARE v_fecha DATE;
    DECLARE v_concepto VARCHAR(100);
    DECLARE v_debe DECIMAL(10,2);
    DECLARE v_haber DECIMAL(10,2);
    DECLARE v_saldo DECIMAL(10,2);
    DECLARE v_id_factura INT;
    DECLARE done INT DEFAULT 0;

    DECLARE cur_pagos CURSOR FOR
        SELECT cc.id_movimiento,
               cc.fecha_movimiento,
               cc.concepto,
               cc.debe,
               cc.haber,
               cc.saldo,
               cc.id_factura
        FROM CuentaCorriente cc
        WHERE cc.id_estudiante = p_id_estudiante
          AND cc.haber > 0
        ORDER BY cc.fecha_movimiento DESC, cc.id_movimiento DESC;

    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = 1;

    DROP TEMPORARY TABLE IF EXISTS TMP_HistorialPagos;
    CREATE TEMPORARY TABLE TMP_HistorialPagos (
        id_movimiento INT,
        fecha DATE,
        concepto VARCHAR(100),
        debe DECIMAL(10,2),
        haber DECIMAL(10,2),
        saldo DECIMAL(10,2),
        id_factura INT
    );

    SET done = 0;
    OPEN cur_pagos;

    read_loop: LOOP
        FETCH cur_pagos INTO v_id_movimiento, v_fecha, v_concepto,
                             v_debe, v_haber, v_saldo, v_id_factura;
        IF done THEN
            LEAVE read_loop;
        END IF;

        INSERT INTO TMP_HistorialPagos
        VALUES (v_id_movimiento, v_fecha, v_concepto,
                v_debe, v_haber, v_saldo, v_id_factura);
    END LOOP;

    CLOSE cur_pagos;

    SELECT *
    FROM TMP_HistorialPagos
    ORDER BY fecha DESC, id_movimiento DESC;
END$$

-- =============================================
-- 4.3 SP_MateriasProfesoresCursos
-- =============================================
DROP PROCEDURE IF EXISTS SP_MateriasProfesoresCursos$$
CREATE PROCEDURE SP_MateriasProfesoresCursos()
BEGIN
    DECLARE v_id_materia INT;
    DECLARE v_nombre_materia VARCHAR(100);
    DECLARE v_id_curso INT;
    DECLARE v_nombre_curso VARCHAR(100);
    DECLARE v_anio INT;
    DECLARE v_id_profesor INT;
    DECLARE v_profesor VARCHAR(200);
    DECLARE done INT DEFAULT 0;

    DECLARE cur_listado CURSOR FOR
        SELECT m.id_materia,
               m.nombre,
               c.id_curso,
               c.nombre_curso,
               c.anio,
               p.id_profesor,
               CONCAT(p.nombre, ' ', p.apellido) AS profesor
        FROM Materias m
        LEFT JOIN Cursos c ON c.id_materia = m.id_materia
        LEFT JOIN Profesores p ON p.id_profesor = c.id_profesor
        ORDER BY m.nombre, c.nombre_curso;

    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = 1;

    DROP TEMPORARY TABLE IF EXISTS TMP_MateriasProfesoresCursos;
    CREATE TEMPORARY TABLE TMP_MateriasProfesoresCursos (
        id_materia INT,
        nombre_materia VARCHAR(100),
        id_curso INT,
        nombre_curso VARCHAR(100),
        anio INT,
        id_profesor INT,
        profesor VARCHAR(200)
    );

    SET done = 0;
    OPEN cur_listado;

    read_loop: LOOP
        FETCH cur_listado INTO v_id_materia, v_nombre_materia,
                              v_id_curso, v_nombre_curso,
                              v_anio, v_id_profesor, v_profesor;
        IF done THEN
            LEAVE read_loop;
        END IF;

        INSERT INTO TMP_MateriasProfesoresCursos
        VALUES (v_id_materia, v_nombre_materia,
                v_id_curso, v_nombre_curso,
                v_anio, v_id_profesor, v_profesor);
    END LOOP;

    CLOSE cur_listado;

    SELECT *
    FROM TMP_MateriasProfesoresCursos
    ORDER BY nombre_materia, nombre_curso;
END$$

-- =============================================
-- 4.4 SP_InscripcionesPorCuatrimestreCurso
-- =============================================
DROP PROCEDURE IF EXISTS SP_InscripcionesPorCuatrimestreCurso$$
CREATE PROCEDURE SP_InscripcionesPorCuatrimestreCurso(
    IN p_id_cuatrimestre INT,
    IN p_id_curso INT
)
BEGIN
    DECLARE v_id_cuatrimestre INT;
    DECLARE v_id_curso INT;
    DECLARE v_nombre_curso VARCHAR(100);
    DECLARE v_id_estudiante INT;
    DECLARE v_estudiante VARCHAR(200);
    DECLARE v_fecha DATE;
    DECLARE done INT DEFAULT 0;

    DECLARE cur_inscripciones CURSOR FOR
        SELECT i.id_cuatrimestre,
               c.id_curso,
               c.nombre_curso,
               e.id_estudiante,
               CONCAT(e.nombre, ' ', e.apellido) AS estudiante,
               i.fecha_inscripcion
        FROM Inscripciones i
        INNER JOIN Cursos c ON c.id_curso = i.id_curso
        INNER JOIN Estudiantes e ON e.id_estudiante = i.id_estudiante
        WHERE (p_id_cuatrimestre IS NULL OR i.id_cuatrimestre = p_id_cuatrimestre)
          AND (p_id_curso IS NULL OR c.id_curso = p_id_curso)
        ORDER BY i.id_cuatrimestre, c.nombre_curso, estudiante;

    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = 1;

    DROP TEMPORARY TABLE IF EXISTS TMP_InscripcionesCuatrimestre;
    CREATE TEMPORARY TABLE TMP_InscripcionesCuatrimestre (
        id_cuatrimestre INT,
        id_curso INT,
        nombre_curso VARCHAR(100),
        id_estudiante INT,
        estudiante VARCHAR(200),
        fecha_inscripcion DATE
    );

    SET done = 0;
    OPEN cur_inscripciones;

    read_loop: LOOP
        FETCH cur_inscripciones INTO v_id_cuatrimestre, v_id_curso,
                                     v_nombre_curso, v_id_estudiante,
                                     v_estudiante, v_fecha;
        IF done THEN
            LEAVE read_loop;
        END IF;

        INSERT INTO TMP_InscripcionesCuatrimestre
        VALUES (v_id_cuatrimestre, v_id_curso,
                v_nombre_curso, v_id_estudiante,
                v_estudiante, v_fecha);
    END LOOP;

    CLOSE cur_inscripciones;

    SELECT *
    FROM TMP_InscripcionesCuatrimestre
    ORDER BY id_cuatrimestre, nombre_curso, estudiante;
END$$

-- =============================================
-- 4.5 SP_EstudiantesConCuotasVencidas
-- =============================================
DROP PROCEDURE IF EXISTS SP_EstudiantesConCuotasVencidas$$
CREATE PROCEDURE SP_EstudiantesConCuotasVencidas()
BEGIN
    DECLARE v_id_estudiante INT;
    DECLARE v_estudiante VARCHAR(200);
    DECLARE v_id_cuota INT;
    DECLARE v_nombre_curso VARCHAR(100);
    DECLARE v_mes INT;
    DECLARE v_anio INT;
    DECLARE v_monto DECIMAL(10,2);
    DECLARE v_fecha DATE;
    DECLARE done INT DEFAULT 0;

    DECLARE cur_cuotas CURSOR FOR
        SELECT e.id_estudiante,
               CONCAT(e.nombre, ' ', e.apellido) AS estudiante,
               q.id_cuota,
               c.nombre_curso,
               q.mes,
               q.anio,
               q.monto_cuota,
               q.fecha_vencimiento
        FROM Cuota q
        INNER JOIN Estudiantes e ON e.id_estudiante = q.id_estudiante
        INNER JOIN Cursos c ON c.id_curso = q.id_curso
        WHERE q.estado_pago = 'Vencido'
        ORDER BY q.fecha_vencimiento ASC;

    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = 1;

    DROP TEMPORARY TABLE IF EXISTS TMP_CuotasVencidas;
    CREATE TEMPORARY TABLE TMP_CuotasVencidas (
        id_estudiante INT,
        estudiante VARCHAR(200),
        id_cuota INT,
        nombre_curso VARCHAR(100),
        mes INT,
        anio INT,
        monto_cuota DECIMAL(10,2),
        fecha_vencimiento DATE,
        dias_atraso INT
    );

    SET done = 0;
    OPEN cur_cuotas;

    read_loop: LOOP
        FETCH cur_cuotas INTO v_id_estudiante, v_estudiante,
                              v_id_cuota, v_nombre_curso,
                              v_mes, v_anio,
                              v_monto, v_fecha;
        IF done THEN
            LEAVE read_loop;
        END IF;

        INSERT INTO TMP_CuotasVencidas
        VALUES (v_id_estudiante, v_estudiante,
                v_id_cuota, v_nombre_curso,
                v_mes, v_anio,
                v_monto, v_fecha,
                DATEDIFF(CURRENT_DATE, v_fecha));
    END LOOP;

    CLOSE cur_cuotas;

    SELECT *
    FROM TMP_CuotasVencidas
    ORDER BY fecha_vencimiento, estudiante;
END$$

-- =============================================
-- 4.6 SP_CursosCantidadInscriptos
-- =============================================
DROP PROCEDURE IF EXISTS SP_CursosCantidadInscriptos$$
CREATE PROCEDURE SP_CursosCantidadInscriptos(
    IN p_anio INT,
    IN p_id_cuatrimestre INT
)
BEGIN
    DECLARE v_id_curso INT;
    DECLARE v_nombre_curso VARCHAR(100);
    DECLARE v_nombre_materia VARCHAR(100);
    DECLARE v_cantidad INT;
    DECLARE done INT DEFAULT 0;

    DECLARE cur_cursos CURSOR FOR
        SELECT c.id_curso,
               c.nombre_curso,
               m.nombre AS nombre_materia,
               COUNT(i.id_estudiante) AS cantidad_inscriptos
        FROM Cursos c
        LEFT JOIN Inscripciones i ON i.id_curso = c.id_curso
        LEFT JOIN Materias m ON m.id_materia = c.id_materia
        WHERE (p_anio IS NULL OR c.anio = p_anio)
          AND (p_id_cuatrimestre IS NULL OR i.id_cuatrimestre = p_id_cuatrimestre)
        GROUP BY c.id_curso, c.nombre_curso, m.nombre
        ORDER BY cantidad_inscriptos DESC, c.nombre_curso;

    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = 1;

    DROP TEMPORARY TABLE IF EXISTS TMP_CursosInscriptos;
    CREATE TEMPORARY TABLE TMP_CursosInscriptos (
        id_curso INT,
        nombre_curso VARCHAR(100),
        nombre_materia VARCHAR(100),
        cantidad_inscriptos INT
    );

    SET done = 0;
    OPEN cur_cursos;

    read_loop: LOOP
        FETCH cur_cursos INTO v_id_curso, v_nombre_curso,
                               v_nombre_materia, v_cantidad;
        IF done THEN
            LEAVE read_loop;
        END IF;

        INSERT INTO TMP_CursosInscriptos
        VALUES (v_id_curso, v_nombre_curso, v_nombre_materia, v_cantidad);
    END LOOP;

    CLOSE cur_cursos;

    SELECT *
    FROM TMP_CursosInscriptos
    ORDER BY cantidad_inscriptos DESC, nombre_curso;
END$$

-- =============================================
-- 4.7 SP_FacturasAgrupadasPorEstado
-- =============================================
DROP PROCEDURE IF EXISTS SP_FacturasAgrupadasPorEstado$$
CREATE PROCEDURE SP_FacturasAgrupadasPorEstado()
BEGIN
    DECLARE v_estado VARCHAR(20);
    DECLARE v_cantidad INT;
    DECLARE v_monto_total DECIMAL(12,2);
    DECLARE done INT DEFAULT 0;

    DECLARE cur_facturas CURSOR FOR
        SELECT f.estado_pago,
               COUNT(*) AS cantidad,
               SUM(f.monto_total) AS monto_total
        FROM Factura f
        GROUP BY f.estado_pago
        ORDER BY f.estado_pago;

    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = 1;

    DROP TEMPORARY TABLE IF EXISTS TMP_FacturasEstado;
    CREATE TEMPORARY TABLE TMP_FacturasEstado (
        estado_pago VARCHAR(20),
        cantidad INT,
        monto_total DECIMAL(12,2)
    );

    SET done = 0;
    OPEN cur_facturas;

    read_loop: LOOP
        FETCH cur_facturas INTO v_estado, v_cantidad, v_monto_total;
        IF done THEN
            LEAVE read_loop;
        END IF;

        INSERT INTO TMP_FacturasEstado
        VALUES (v_estado, v_cantidad, IFNULL(v_monto_total, 0));
    END LOOP;

    CLOSE cur_facturas;

    SELECT *
    FROM TMP_FacturasEstado
    ORDER BY estado_pago;
END$$

-- =============================================
-- 4.8 SP_InteresesMoraPorAnio
-- =============================================
DROP PROCEDURE IF EXISTS SP_InteresesMoraPorAnio$$
CREATE PROCEDURE SP_InteresesMoraPorAnio()
BEGIN
    DECLARE v_anio INT;
    DECLARE v_tasa DECIMAL(5,2);
    DECLARE v_fecha DATE;
    DECLARE done INT DEFAULT 0;

    DECLARE cur_interes CURSOR FOR
        SELECT anio, tasa_mensual, fecha_vigencia
        FROM InteresMora
        ORDER BY anio;

    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = 1;

    DROP TEMPORARY TABLE IF EXISTS TMP_InteresMora;
    CREATE TEMPORARY TABLE TMP_InteresMora (
        anio INT,
        tasa_mensual DECIMAL(5,2),
        fecha_vigencia DATE
    );

    SET done = 0;
    OPEN cur_interes;

    read_loop: LOOP
        FETCH cur_interes INTO v_anio, v_tasa, v_fecha;
        IF done THEN
            LEAVE read_loop;
        END IF;

        INSERT INTO TMP_InteresMora
        VALUES (v_anio, v_tasa, v_fecha);
    END LOOP;

    CLOSE cur_interes;

    SELECT *
    FROM TMP_InteresMora
    ORDER BY anio;
END$$

-- =============================================
-- 4.9 SP_CursosMayorCantidadInscriptos
-- =============================================
DROP PROCEDURE IF EXISTS SP_CursosMayorCantidadInscriptos$$
CREATE PROCEDURE SP_CursosMayorCantidadInscriptos()
BEGIN
    DECLARE v_id_curso INT;
    DECLARE v_nombre_curso VARCHAR(100);
    DECLARE v_nombre_materia VARCHAR(100);
    DECLARE v_cantidad INT;
    DECLARE done INT DEFAULT 0;

    DECLARE cur_top CURSOR FOR
        SELECT c.id_curso,
               c.nombre_curso,
               m.nombre AS nombre_materia,
               COUNT(i.id_estudiante) AS cantidad_inscriptos
        FROM Cursos c
        LEFT JOIN Inscripciones i ON i.id_curso = c.id_curso
        LEFT JOIN Materias m ON m.id_materia = c.id_materia
        GROUP BY c.id_curso, c.nombre_curso, m.nombre
        ORDER BY cantidad_inscriptos DESC, c.nombre_curso
        LIMIT 10;

    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = 1;

    DROP TEMPORARY TABLE IF EXISTS TMP_CursosTopInscriptos;
    CREATE TEMPORARY TABLE TMP_CursosTopInscriptos (
        id_curso INT,
        nombre_curso VARCHAR(100),
        nombre_materia VARCHAR(100),
        cantidad_inscriptos INT
    );

    SET done = 0;
    OPEN cur_top;

    read_loop: LOOP
        FETCH cur_top INTO v_id_curso, v_nombre_curso, v_nombre_materia, v_cantidad;
        IF done THEN
            LEAVE read_loop;
        END IF;

        INSERT INTO TMP_CursosTopInscriptos
        VALUES (v_id_curso, v_nombre_curso, v_nombre_materia, v_cantidad);
    END LOOP;

    CLOSE cur_top;

    SELECT *
    FROM TMP_CursosTopInscriptos
    ORDER BY cantidad_inscriptos DESC, nombre_curso;
END$$

-- =============================================
-- 4.10 SP_EstudiantesSinMatriculaAnioActual
-- =============================================
DROP PROCEDURE IF EXISTS SP_EstudiantesSinMatriculaAnioActual$$
CREATE PROCEDURE SP_EstudiantesSinMatriculaAnioActual(
    IN p_anio INT
)
BEGIN
    DECLARE v_anio INT;
    DECLARE v_id_estudiante INT;
    DECLARE v_nombre VARCHAR(100);
    DECLARE v_apellido VARCHAR(100);
    DECLARE done INT DEFAULT 0;

    DECLARE cur_estudiantes CURSOR FOR
        SELECT e.id_estudiante, e.nombre, e.apellido
        FROM Estudiantes e
        WHERE NOT EXISTS (
            SELECT 1
            FROM Matriculacion m
            WHERE m.id_estudiante = e.id_estudiante
              AND m.anio = v_anio
        )
        ORDER BY e.apellido, e.nombre;

    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = 1;

    SET v_anio = IFNULL(p_anio, YEAR(CURRENT_DATE));

    DROP TEMPORARY TABLE IF EXISTS TMP_EstudiantesSinMatricula;
    CREATE TEMPORARY TABLE TMP_EstudiantesSinMatricula (
        id_estudiante INT,
        nombre VARCHAR(100),
        apellido VARCHAR(100),
        anio INT
    );

    SET done = 0;
    OPEN cur_estudiantes;

    read_loop: LOOP
        FETCH cur_estudiantes INTO v_id_estudiante, v_nombre, v_apellido;
        IF done THEN
            LEAVE read_loop;
        END IF;

        INSERT INTO TMP_EstudiantesSinMatricula
        VALUES (v_id_estudiante, v_nombre, v_apellido, v_anio);
    END LOOP;

    CLOSE cur_estudiantes;

    SELECT *
    FROM TMP_EstudiantesSinMatricula
    ORDER BY apellido, nombre;
END$$

DELIMITER ;

-- =============================================
-- SCRIPT COMPLETADO
-- =============================================
-- 10 procedimientos con cursores creados correctamente.
