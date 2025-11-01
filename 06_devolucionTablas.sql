-- =============================================
-- FUNCIONES CON DEVOLUCION EN FORMATO JSON
-- Actividad 2: Gestion Academica (Funciones 3.x)
-- Nota: MySQL/MariaDB no permiten funciones que retornen sets de filas.
--       Cada funcion devuelve un JSON_ARRAY con los registros pedidos.
--       Uso: SELECT FN_...(...) AS resultado;
-- =============================================

DELIMITER $$

-- =============================================
-- 3.1 FN_ListarCursosPorEstudiante
-- =============================================
DROP FUNCTION IF EXISTS FN_ListarCursosPorEstudiante$$
CREATE FUNCTION FN_ListarCursosPorEstudiante(
    p_id_estudiante INT,
    p_anio INT,
    p_id_cuatrimestre INT
)
RETURNS JSON
READS SQL DATA
DETERMINISTIC
BEGIN
    RETURN IFNULL((
        SELECT JSON_ARRAYAGG(
            JSON_OBJECT(
                'id_curso', datos.id_curso,
                'nombre_curso', datos.nombre_curso,
                'descripcion', datos.descripcion,
                'anio', datos.anio,
                'id_materia', datos.id_materia,
                'nombre_materia', datos.nombre_materia,
                'id_profesor', datos.id_profesor,
                'profesor', datos.profesor,
                'fecha_inscripcion', datos.fecha_inscripcion,
                'id_cuatrimestre', datos.id_cuatrimestre
            )
        )
        FROM (
            SELECT
                c.id_curso,
                c.nombre_curso,
                c.descripcion,
                c.anio,
                m.id_materia,
                m.nombre AS nombre_materia,
                p.id_profesor,
                CONCAT(p.nombre, ' ', p.apellido) AS profesor,
                i.fecha_inscripcion,
                i.id_cuatrimestre
            FROM Inscripciones i
            JOIN Cursos c     ON c.id_curso = i.id_curso
            JOIN Materias m   ON m.id_materia = c.id_materia
            JOIN Profesores p ON p.id_profesor = c.id_profesor
            WHERE i.id_estudiante = p_id_estudiante
              AND (p_anio IS NULL OR c.anio = p_anio)
              AND (p_id_cuatrimestre IS NULL OR i.id_cuatrimestre = p_id_cuatrimestre)
            ORDER BY c.anio DESC, m.nombre, c.nombre_curso
        ) AS datos
    ), JSON_ARRAY());
END$$

-- =============================================
-- 3.2 FN_CuotasImpagasPorEstudiante
-- =============================================
DROP FUNCTION IF EXISTS FN_CuotasImpagasPorEstudiante$$
CREATE FUNCTION FN_CuotasImpagasPorEstudiante(
    p_id_estudiante INT,
    p_anio INT
)
RETURNS JSON
READS SQL DATA
DETERMINISTIC
BEGIN
    RETURN IFNULL((
        SELECT JSON_ARRAYAGG(
            JSON_OBJECT(
                'id_cuota', datos.id_cuota,
                'id_estudiante', datos.id_estudiante,
                'id_curso', datos.id_curso,
                'mes', datos.mes,
                'anio', datos.anio,
                'monto_cuota', datos.monto_cuota,
                'fecha_vencimiento', datos.fecha_vencimiento,
                'estado_pago', datos.estado_pago,
                'id_factura', datos.id_factura,
                'nombre_curso', datos.nombre_curso,
                'nombre_materia', datos.nombre_materia
            )
        )
        FROM (
            SELECT
                q.id_cuota,
                q.id_estudiante,
                q.id_curso,
                q.mes,
                q.anio,
                q.monto_cuota,
                q.fecha_vencimiento,
                q.estado_pago,
                q.id_factura,
                c.nombre_curso,
                m.nombre AS nombre_materia
            FROM Cuota q
            JOIN Cursos c   ON c.id_curso = q.id_curso
            JOIN Materias m ON m.id_materia = c.id_materia
            WHERE q.id_estudiante = p_id_estudiante
              AND (p_anio IS NULL OR q.anio = p_anio)
              AND q.estado_pago IN ('Pendiente', 'Vencido')
            ORDER BY q.anio DESC, q.mes DESC, q.fecha_vencimiento DESC
        ) AS datos
    ), JSON_ARRAY());
END$$

-- =============================================
-- 3.3 FN_ProfesoresPorCuatrimestre
-- =============================================
DROP FUNCTION IF EXISTS FN_ProfesoresPorCuatrimestre$$
CREATE FUNCTION FN_ProfesoresPorCuatrimestre(
    p_id_cuatrimestre INT
)
RETURNS JSON
READS SQL DATA
DETERMINISTIC
BEGIN
    RETURN IFNULL((
        SELECT JSON_ARRAYAGG(
            JSON_OBJECT(
                'id_profesor', datos.id_profesor,
                'profesor', datos.profesor,
                'id_materia', datos.id_materia,
                'nombre_materia', datos.nombre_materia
            )
        )
        FROM (
            SELECT DISTINCT
                pr.id_profesor,
                CONCAT(pr.nombre, ' ', pr.apellido) AS profesor,
                ma.id_materia,
                ma.nombre AS nombre_materia
            FROM Inscripciones i
            JOIN Cursos cu     ON cu.id_curso = i.id_curso
            JOIN Profesores pr ON pr.id_profesor = cu.id_profesor
            JOIN Materias ma   ON ma.id_materia = cu.id_materia
            WHERE i.id_cuatrimestre = p_id_cuatrimestre
            ORDER BY profesor, ma.nombre
        ) AS datos
    ), JSON_ARRAY());
END$$

-- =============================================
-- 3.4 FN_MateriasConMasDeTresCursos
-- =============================================
DROP FUNCTION IF EXISTS FN_MateriasConMasDeTresCursos$$
CREATE FUNCTION FN_MateriasConMasDeTresCursos(
    p_anio INT
)
RETURNS JSON
READS SQL DATA
DETERMINISTIC
BEGIN
    RETURN IFNULL((
        SELECT JSON_ARRAYAGG(
            JSON_OBJECT(
                'id_materia', datos.id_materia,
                'nombre_materia', datos.nombre_materia,
                'cantidad_cursos', datos.cantidad_cursos
            )
        )
        FROM (
            SELECT
                m.id_materia,
                m.nombre AS nombre_materia,
                COUNT(*) AS cantidad_cursos
            FROM Cursos c
            JOIN Materias m ON m.id_materia = c.id_materia
            WHERE (p_anio IS NULL OR c.anio = p_anio)
            GROUP BY m.id_materia, m.nombre
            HAVING COUNT(*) > 3
            ORDER BY cantidad_cursos DESC, m.nombre
        ) AS datos
    ), JSON_ARRAY());
END$$

-- =============================================
-- 3.5 FN_EstudiantesConMatriculaActiva
-- =============================================
DROP FUNCTION IF EXISTS FN_EstudiantesConMatriculaActiva$$
CREATE FUNCTION FN_EstudiantesConMatriculaActiva(
    p_anio INT
)
RETURNS JSON
READS SQL DATA
DETERMINISTIC
BEGIN
    RETURN IFNULL((
        SELECT JSON_ARRAYAGG(
            JSON_OBJECT(
                'id_estudiante', datos.id_estudiante,
                'nombre', datos.nombre,
                'apellido', datos.apellido,
                'anio_matricula', datos.anio_matricula,
                'fecha_matriculacion', datos.fecha_matriculacion,
                'monto_matricula', datos.monto_matricula,
                'id_factura', datos.id_factura
            )
        )
        FROM (
            SELECT
                e.id_estudiante,
                e.nombre,
                e.apellido,
                m.anio AS anio_matricula,
                m.fecha_matriculacion,
                m.monto_matricula,
                m.id_factura
            FROM Matriculacion m
            JOIN Estudiantes e ON e.id_estudiante = m.id_estudiante
            WHERE (p_anio IS NULL OR m.anio = p_anio)
            ORDER BY e.apellido, e.nombre
        ) AS datos
    ), JSON_ARRAY());
END$$

-- =============================================
-- 3.6 FN_FacturasPorMes
-- =============================================
DROP FUNCTION IF EXISTS FN_FacturasPorMes$$
CREATE FUNCTION FN_FacturasPorMes(
    p_mes INT,
    p_anio INT
)
RETURNS JSON
READS SQL DATA
DETERMINISTIC
BEGIN
    RETURN IFNULL((
        SELECT JSON_ARRAYAGG(
            JSON_OBJECT(
                'id_factura', datos.id_factura,
                'id_estudiante', datos.id_estudiante,
                'nombre', datos.nombre,
                'apellido', datos.apellido,
                'fecha_emision', datos.fecha_emision,
                'monto_total', datos.monto_total,
                'estado_pago', datos.estado_pago
            )
        )
        FROM (
            SELECT
                f.id_factura,
                f.id_estudiante,
                e.nombre,
                e.apellido,
                f.fecha_emision,
                f.monto_total,
                f.estado_pago
            FROM Factura f
            JOIN Estudiantes e ON e.id_estudiante = f.id_estudiante
            WHERE (p_mes IS NULL OR MONTH(f.fecha_emision) = p_mes)
              AND (p_anio IS NULL OR YEAR(f.fecha_emision) = p_anio)
            ORDER BY f.fecha_emision DESC, f.id_factura DESC
        ) AS datos
    ), JSON_ARRAY());
END$$

-- =============================================
-- 3.7 FN_CursosConMasDe30Inscriptos
-- =============================================
DROP FUNCTION IF EXISTS FN_CursosConMasDe30Inscriptos$$
CREATE FUNCTION FN_CursosConMasDe30Inscriptos(
    p_anio INT,
    p_id_cuatrimestre INT
)
RETURNS JSON
READS SQL DATA
DETERMINISTIC
BEGIN
    RETURN IFNULL((
        SELECT JSON_ARRAYAGG(
            JSON_OBJECT(
                'id_curso', datos.id_curso,
                'nombre_curso', datos.nombre_curso,
                'nombre_materia', datos.nombre_materia,
                'id_profesor', datos.id_profesor,
                'profesor', datos.profesor,
                'cantidad_inscriptos', datos.cantidad_inscriptos
            )
        )
        FROM (
            SELECT
                c.id_curso,
                c.nombre_curso,
                m.nombre AS nombre_materia,
                p.id_profesor,
                CONCAT(p.nombre, ' ', p.apellido) AS profesor,
                COUNT(i.id_estudiante) AS cantidad_inscriptos
            FROM Cursos c
            JOIN Inscripciones i ON i.id_curso = c.id_curso
            JOIN Materias m      ON m.id_materia = c.id_materia
            JOIN Profesores p    ON p.id_profesor = c.id_profesor
            WHERE (p_anio IS NULL OR c.anio = p_anio)
              AND (p_id_cuatrimestre IS NULL OR i.id_cuatrimestre = p_id_cuatrimestre)
            GROUP BY c.id_curso, c.nombre_curso, m.nombre, p.id_profesor, p.nombre, p.apellido
            HAVING COUNT(i.id_estudiante) > 30
            ORDER BY cantidad_inscriptos DESC, c.nombre_curso
        ) AS datos
    ), JSON_ARRAY());
END$$

-- =============================================
-- 3.8 FN_MovimientosCuentaCorriente
-- =============================================
DROP FUNCTION IF EXISTS FN_MovimientosCuentaCorriente$$
CREATE FUNCTION FN_MovimientosCuentaCorriente(
    p_id_estudiante INT,
    p_fecha_desde DATE,
    p_fecha_hasta DATE
)
RETURNS JSON
READS SQL DATA
DETERMINISTIC
BEGIN
    RETURN IFNULL((
        SELECT JSON_ARRAYAGG(
            JSON_OBJECT(
                'id_movimiento', datos.id_movimiento,
                'fecha_movimiento', datos.fecha_movimiento,
                'concepto', datos.concepto,
                'debe', datos.debe,
                'haber', datos.haber,
                'saldo', datos.saldo,
                'id_factura', datos.id_factura
            )
        )
        FROM (
            SELECT
                cc.id_movimiento,
                cc.fecha_movimiento,
                cc.concepto,
                cc.debe,
                cc.haber,
                cc.saldo,
                cc.id_factura
            FROM CuentaCorriente cc
            WHERE cc.id_estudiante = p_id_estudiante
              AND (p_fecha_desde IS NULL OR cc.fecha_movimiento >= p_fecha_desde)
              AND (p_fecha_hasta IS NULL OR cc.fecha_movimiento <= p_fecha_hasta)
            ORDER BY cc.fecha_movimiento DESC, cc.id_movimiento DESC
        ) AS datos
    ), JSON_ARRAY());
END$$

-- =============================================
-- 3.9 FN_CursosPorProfesorYAnio
-- =============================================
DROP FUNCTION IF EXISTS FN_CursosPorProfesorYAnio$$
CREATE FUNCTION FN_CursosPorProfesorYAnio(
    p_id_profesor INT,
    p_anio INT
)
RETURNS JSON
READS SQL DATA
DETERMINISTIC
BEGIN
    RETURN IFNULL((
        SELECT JSON_ARRAYAGG(
            JSON_OBJECT(
                'id_curso', datos.id_curso,
                'nombre_curso', datos.nombre_curso,
                'descripcion', datos.descripcion,
                'anio', datos.anio,
                'id_materia', datos.id_materia,
                'nombre_materia', datos.nombre_materia
            )
        )
        FROM (
            SELECT
                c.id_curso,
                c.nombre_curso,
                c.descripcion,
                c.anio,
                m.id_materia,
                m.nombre AS nombre_materia
            FROM Cursos c
            JOIN Materias m ON m.id_materia = c.id_materia
            WHERE c.id_profesor = p_id_profesor
              AND (p_anio IS NULL OR c.anio = p_anio)
            ORDER BY c.anio DESC, m.nombre, c.nombre_curso
        ) AS datos
    ), JSON_ARRAY());
END$$

-- =============================================
-- 3.10 FN_InscripcionesConNotaFinalMayorA
-- =============================================
DROP FUNCTION IF EXISTS FN_InscripcionesConNotaFinalMayorA$$
CREATE FUNCTION FN_InscripcionesConNotaFinalMayorA(
    p_min_nota DECIMAL(4,2),
    p_anio INT,
    p_id_cuatrimestre INT
)
RETURNS JSON
READS SQL DATA
DETERMINISTIC
BEGIN
    RETURN IFNULL((
        SELECT JSON_ARRAYAGG(
            JSON_OBJECT(
                'id_estudiante', datos.id_estudiante,
                'nombre', datos.nombre,
                'apellido', datos.apellido,
                'id_curso', datos.id_curso,
                'nombre_curso', datos.nombre_curso,
                'nombre_materia', datos.nombre_materia,
                'anio', datos.anio,
                'id_cuatrimestre', datos.id_cuatrimestre,
                'nota_final', datos.nota_final
            )
        )
        FROM (
            SELECT
                i.id_estudiante,
                e.nombre,
                e.apellido,
                i.id_curso,
                c.nombre_curso,
                m.nombre AS nombre_materia,
                c.anio,
                i.id_cuatrimestre,
                i.nota_final
            FROM Inscripciones i
            JOIN Estudiantes e ON e.id_estudiante = i.id_estudiante
            JOIN Cursos c      ON c.id_curso = i.id_curso
            JOIN Materias m    ON m.id_materia = c.id_materia
            WHERE i.nota_final IS NOT NULL
              AND i.nota_final > IFNULL(p_min_nota, 8.00)
              AND (p_anio IS NULL OR c.anio = p_anio)
              AND (p_id_cuatrimestre IS NULL OR i.id_cuatrimestre = p_id_cuatrimestre)
            ORDER BY i.nota_final DESC, e.apellido, e.nombre
        ) AS datos
    ), JSON_ARRAY());
END$$

DELIMITER ;

-- =============================================
-- SCRIPT COMPLETADO
-- =============================================
-- 10 funciones que devuelven los listados requeridos en formato JSON.
