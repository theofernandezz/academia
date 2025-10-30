DELIMITER //

-- 1) Listar todos los cursos en los que está inscripto un estudiante
DROP PROCEDURE IF EXISTS sp_listar_cursos_por_estudiante //
CREATE PROCEDURE sp_listar_cursos_por_estudiante(IN p_id_estudiante INT, IN p_anio INT, IN p_id_cuatrimestre INT)
BEGIN
    SELECT
        c.id_curso,
        c.nombre_curso,
        c.descripcion,
        c.anio,
        m.id_materia,
        m.nombre_materia,
        p.id_profesor,
        CONCAT(p.nombre, ' ', p.apellido) AS profesor,
        i.fecha_inscripcion,
        i.id_cuatrimestre
    FROM Inscripciones i
    JOIN Cursos c       ON c.id_curso = i.id_curso
    JOIN Materias m     ON m.id_materia = c.id_materia
    JOIN Profesores p   ON p.id_profesor = c.id_profesor
    WHERE i.id_estudiante = p_id_estudiante
      AND (p_anio IS NULL OR c.anio = p_anio)
      AND (p_id_cuatrimestre IS NULL OR i.id_cuatrimestre = p_id_cuatrimestre)
    ORDER BY c.anio DESC, m.nombre_materia, c.nombre_curso;
END //
 
-- 2) Obtener todas las cuotas impagas de un estudiante
-- "Impaga" = estado_pago IN ('Pendiente','Vencido')
DROP PROCEDURE IF EXISTS sp_cuotas_impagas_por_estudiante //
CREATE PROCEDURE sp_cuotas_impagas_por_estudiante(IN p_id_estudiante INT, IN p_anio INT)
BEGIN
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
        m.nombre_materia
    FROM Cuota q
    JOIN Cursos c   ON c.id_curso = q.id_curso
    JOIN Materias m ON m.id_materia = c.id_materia
    WHERE q.id_estudiante = p_id_estudiante
      AND (p_anio IS NULL OR q.anio = p_anio)
      AND q.estado_pago IN ('Pendiente','Vencido')
    ORDER BY q.anio DESC, q.mes DESC, q.fecha_vencimiento DESC;
END //

-- 3) Listar los profesores que dictan materias en un cuatrimestre específico
-- Dado que Cursos no referencia cuatrimestre directamente, se apalanca Inscripciones.id_cuatrimestre
DROP PROCEDURE IF EXISTS sp_profesores_por_cuatrimestre //
CREATE PROCEDURE sp_profesores_por_cuatrimestre(IN p_id_cuatrimestre INT)
BEGIN
    SELECT DISTINCT
        pr.id_profesor,
        CONCAT(pr.nombre, ' ', pr.apellido) AS profesor,
        ma.id_materia,
        ma.nombre_materia
    FROM Inscripciones i
    JOIN Cursos cu   ON cu.id_curso = i.id_curso
    JOIN Profesores pr ON pr.id_profesor = cu.id_profesor
    JOIN Materias ma ON ma.id_materia = cu.id_materia
    WHERE i.id_cuatrimestre = p_id_cuatrimestre
    ORDER BY profesor, ma.nombre_materia;
END //

-- 4) Mostrar todas las materias con más de 3 cursos activos
-- Interpretamos "activos" como cursos del año indicado
DROP PROCEDURE IF EXISTS sp_materias_con_mas_de_tres_cursos //
CREATE PROCEDURE sp_materias_con_mas_de_tres_cursos(IN p_anio INT)
BEGIN
    SELECT
        m.id_materia,
        m.nombre_materia,
        COUNT(*) AS cantidad_cursos
    FROM Cursos c
    JOIN Materias m ON m.id_materia = c.id_materia
    WHERE (p_anio IS NULL OR c.anio = p_anio)
    GROUP BY m.id_materia, m.nombre_materia
    HAVING COUNT(*) > 3
    ORDER BY cantidad_cursos DESC, m.nombre_materia;
END //

-- 5) Listar los estudiantes con matrícula activa en un año determinado
-- "Activa" = existencia de registro en Matriculacion para ese año
DROP PROCEDURE IF EXISTS sp_estudiantes_con_matricula_activa //
CREATE PROCEDURE sp_estudiantes_con_matricula_activa(IN p_anio INT)
BEGIN
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
    ORDER BY e.apellido, e.nombre;
END //

-- 6) Obtener todas las facturas emitidas en un mes específico
DROP PROCEDURE IF EXISTS sp_facturas_por_mes //
CREATE PROCEDURE sp_facturas_por_mes(IN p_mes INT, IN p_anio INT)
BEGIN
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
    ORDER BY f.fecha_emision DESC, f.id_factura DESC;
END //

-- 7) Listar los cursos con más de 30 estudiantes inscriptos
DROP PROCEDURE IF EXISTS sp_cursos_con_mas_de_30_inscriptos //
CREATE PROCEDURE sp_cursos_con_mas_de_30_inscriptos(IN p_anio INT, IN p_id_cuatrimestre INT)
BEGIN
    SELECT
        c.id_curso,
        c.nombre_curso,
        m.nombre_materia,
        p.id_profesor,
        CONCAT(p.nombre, ' ', p.apellido) AS profesor,
        COUNT(i.id_estudiante) AS cantidad_inscriptos
    FROM Cursos c
    JOIN Inscripciones i ON i.id_curso = c.id_curso
    JOIN Materias m      ON m.id_materia = c.id_materia
    JOIN Profesores p    ON p.id_profesor = c.id_profesor
    WHERE (p_anio IS NULL OR c.anio = p_anio)
      AND (p_id_cuatrimestre IS NULL OR i.id_cuatrimestre = p_id_cuatrimestre)
    GROUP BY c.id_curso, c.nombre_curso, m.nombre_materia, p.id_profesor, profesor
    HAVING COUNT(i.id_estudiante) > 30
    ORDER BY cantidad_inscriptos DESC, c.nombre_curso;
END //

-- 8) Mostrar los movimientos de cuenta corriente de un estudiante
DROP PROCEDURE IF EXISTS sp_movimientos_cuenta_corriente //
CREATE PROCEDURE sp_movimientos_cuenta_corriente(IN p_id_estudiante INT, IN p_fecha_desde DATE, IN p_fecha_hasta DATE)
BEGIN
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
    ORDER BY cc.fecha_movimiento DESC, cc.id_movimiento DESC;
END //

-- 9) Listar los cursos dictados por un profesor en un año específico
DROP PROCEDURE IF EXISTS sp_cursos_por_profesor_y_anio //
CREATE PROCEDURE sp_cursos_por_profesor_y_anio(IN p_id_profesor INT, IN p_anio INT)
BEGIN
    SELECT
        c.id_curso,
        c.nombre_curso,
        c.descripcion,
        c.anio,
        m.id_materia,
        m.nombre_materia
    FROM Cursos c
    JOIN Materias m ON m.id_materia = c.id_materia
    WHERE c.id_profesor = p_id_profesor
      AND (p_anio IS NULL OR c.anio = p_anio)
    ORDER BY c.anio DESC, m.nombre_materia, c.nombre_curso;
END //

-- 10) Obtener todas las inscripciones con nota final mayor a 8
DROP PROCEDURE IF EXISTS sp_inscripciones_con_nota_final_mayor_a //
CREATE PROCEDURE sp_inscripciones_con_nota_final_mayor_a(IN p_min_nota DECIMAL(4,2), IN p_anio INT, IN p_id_cuatrimestre INT)
BEGIN
    SELECT
        i.id_estudiante,
        e.nombre,
        e.apellido,
        i.id_curso,
        c.nombre_curso,
        m.nombre_materia,
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
    ORDER BY i.nota_final DESC, e.apellido, e.nombre;
END //

DELIMITER ;


