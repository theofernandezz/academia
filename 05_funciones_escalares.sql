-- =============================================
-- FUNCIONES ESCALARES
-- Actividad 2: Gestión Académica (Funciones 2.x)
-- SQL Estándar (compatible MySQL)
-- =============================================

DELIMITER $$

-- =============================================
-- 2.1 FN_SaldoCuentaCorriente
-- Devuelve el saldo acumulado (debe - haber) de un estudiante
-- =============================================
DROP FUNCTION IF EXISTS FN_SaldoCuentaCorriente$$
CREATE FUNCTION FN_SaldoCuentaCorriente(
    p_id_estudiante INT
)
RETURNS DECIMAL(10,2)
READS SQL DATA
DETERMINISTIC
BEGIN
    DECLARE v_saldo DECIMAL(10,2);

    SELECT COALESCE(SUM(debe - haber), 0)
    INTO v_saldo
    FROM CuentaCorriente
    WHERE id_estudiante = p_id_estudiante;

    RETURN v_saldo;
END$$

-- =============================================
-- 2.2 FN_VacantesDisponibles
-- Calcula vacantes restantes suponiendo cupo máximo de 35 alumnos
-- =============================================
DROP FUNCTION IF EXISTS FN_VacantesDisponibles$$
CREATE FUNCTION FN_VacantesDisponibles(
    p_id_curso INT
)
RETURNS INT
READS SQL DATA
DETERMINISTIC
BEGIN
    DECLARE v_cupo_maximo INT;
    DECLARE v_inscriptos INT;

    SELECT cupo_maximo
    INTO v_cupo_maximo
    FROM Cursos
    WHERE id_curso = p_id_curso;

    IF v_cupo_maximo IS NULL OR v_cupo_maximo <= 0 THEN
        SET v_cupo_maximo = 35;
    ELSEIF v_cupo_maximo > 35 THEN
        SET v_cupo_maximo = 35;
    END IF;

    SELECT COUNT(*)
    INTO v_inscriptos
    FROM Inscripciones
    WHERE id_curso = p_id_curso;

    RETURN GREATEST(v_cupo_maximo - v_inscriptos, 0);
END$$

-- =============================================
-- 2.3 FN_NombreCompletoEstudiante
-- Retorna el nombre completo (Nombre + Apellido) de un estudiante
-- =============================================
DROP FUNCTION IF EXISTS FN_NombreCompletoEstudiante$$
CREATE FUNCTION FN_NombreCompletoEstudiante(
    p_id_estudiante INT
)
RETURNS VARCHAR(201)
READS SQL DATA
DETERMINISTIC
BEGIN
    DECLARE v_nombre VARCHAR(100);
    DECLARE v_apellido VARCHAR(100);

    SELECT nombre, apellido
    INTO v_nombre, v_apellido
    FROM Estudiantes
    WHERE id_estudiante = p_id_estudiante;

    IF v_nombre IS NULL OR v_apellido IS NULL THEN
        RETURN NULL;
    END IF;

    RETURN CONCAT(TRIM(v_nombre), ' ', TRIM(v_apellido));
END$$

-- =============================================
-- 2.4 FN_PromedioFinalCurso
-- Calcula el promedio final de un estudiante en un curso
-- =============================================
DROP FUNCTION IF EXISTS FN_PromedioFinalCurso$$
CREATE FUNCTION FN_PromedioFinalCurso(
    p_id_estudiante INT,
    p_id_curso INT
)
RETURNS DECIMAL(5,2)
READS SQL DATA
DETERMINISTIC
BEGIN
    DECLARE v_nota_eval1 DECIMAL(5,2);
    DECLARE v_nota_eval2 DECIMAL(5,2);
    DECLARE v_nota_eval3 DECIMAL(5,2);
    DECLARE v_nota_recup DECIMAL(5,2);
    DECLARE v_nota_final DECIMAL(5,2);
    DECLARE v_total DECIMAL(10,4) DEFAULT 0;
    DECLARE v_conteo INT DEFAULT 0;
    DECLARE v_min DECIMAL(5,2);

    SELECT nota_evaluacion_1,
           nota_evaluacion_2,
           nota_evaluacion_3,
           nota_recuperatorio,
           nota_final
    INTO v_nota_eval1,
         v_nota_eval2,
         v_nota_eval3,
         v_nota_recup,
         v_nota_final
    FROM Inscripciones
    WHERE id_estudiante = p_id_estudiante
      AND id_curso = p_id_curso;

    IF v_nota_final IS NOT NULL THEN
        RETURN v_nota_final;
    END IF;

    IF v_nota_eval1 IS NOT NULL THEN
        SET v_total = v_total + v_nota_eval1;
        SET v_conteo = v_conteo + 1;
    END IF;

    IF v_nota_eval2 IS NOT NULL THEN
        SET v_total = v_total + v_nota_eval2;
        SET v_conteo = v_conteo + 1;
    END IF;

    IF v_nota_eval3 IS NOT NULL THEN
        SET v_total = v_total + v_nota_eval3;
        SET v_conteo = v_conteo + 1;
    END IF;

    IF v_conteo = 0 THEN
        RETURN NULL;
    END IF;

    IF v_conteo = 3 AND v_nota_recup IS NOT NULL THEN
        SET v_min = v_nota_eval1;
        IF v_nota_eval2 < v_min THEN
            SET v_min = v_nota_eval2;
        END IF;
        IF v_nota_eval3 < v_min THEN
            SET v_min = v_nota_eval3;
        END IF;

        SET v_total = v_total - v_min + v_nota_recup;
    END IF;

    RETURN ROUND(v_total / v_conteo, 2);
END$$

-- =============================================
-- 2.5 FN_EstadoPagoCuota
-- Devuelve el estado de pago de una cuota de un estudiante
-- =============================================
DROP FUNCTION IF EXISTS FN_EstadoPagoCuota$$
CREATE FUNCTION FN_EstadoPagoCuota(
    p_id_estudiante INT,
    p_id_cuota INT
)
RETURNS VARCHAR(20)
READS SQL DATA
DETERMINISTIC
BEGIN
    DECLARE v_estado VARCHAR(20);

    SELECT estado_pago
    INTO v_estado
    FROM Cuota
    WHERE id_cuota = p_id_cuota
      AND id_estudiante = p_id_estudiante;

    RETURN COALESCE(v_estado, 'Desconocido');
END$$

-- =============================================
-- 2.6 FN_EspecialidadProfesor
-- Retorna la especialidad de un profesor dado su nombre completo
-- =============================================
DROP FUNCTION IF EXISTS FN_EspecialidadProfesor$$
CREATE FUNCTION FN_EspecialidadProfesor(
    p_nombre_completo VARCHAR(200)
)
RETURNS VARCHAR(100)
READS SQL DATA
DETERMINISTIC
BEGIN
    DECLARE v_especialidad VARCHAR(100);
    DECLARE v_coincidencias INT;

    SELECT COUNT(*)
    INTO v_coincidencias
    FROM Profesores
    WHERE CONCAT_WS(' ', TRIM(nombre), TRIM(apellido)) = TRIM(p_nombre_completo);

    IF v_coincidencias = 0 THEN
        RETURN NULL;
    ELSEIF v_coincidencias > 1 THEN
        RETURN 'AMBIGUO';
    END IF;

    SELECT especialidad
    INTO v_especialidad
    FROM Profesores
    WHERE CONCAT_WS(' ', TRIM(nombre), TRIM(apellido)) = TRIM(p_nombre_completo)
    LIMIT 1;

    RETURN v_especialidad;
END$$

-- =============================================
-- 2.7 FN_TotalAdeudadoPorNombre
-- Calcula el monto adeudado para un estudiante según su nombre
-- Devuelve -1 si hay duplicados para el nombre indicado
-- =============================================
DROP FUNCTION IF EXISTS FN_TotalAdeudadoPorNombre$$
CREATE FUNCTION FN_TotalAdeudadoPorNombre(
    p_nombre VARCHAR(100)
)
RETURNS DECIMAL(10,2)
READS SQL DATA
DETERMINISTIC
BEGIN
    DECLARE v_cantidad INT;
    DECLARE v_id_estudiante INT;
    DECLARE v_total DECIMAL(10,2);

    SELECT COUNT(*)
    INTO v_cantidad
    FROM Estudiantes
    WHERE LOWER(TRIM(nombre)) = LOWER(TRIM(p_nombre));

    IF v_cantidad = 0 THEN
        RETURN 0;
    ELSEIF v_cantidad > 1 THEN
        RETURN -1;
    END IF;

    SELECT id_estudiante
    INTO v_id_estudiante
    FROM Estudiantes
    WHERE LOWER(TRIM(nombre)) = LOWER(TRIM(p_nombre))
    LIMIT 1;

    SELECT COALESCE(SUM(debe - haber), 0)
    INTO v_total
    FROM CuentaCorriente
    WHERE id_estudiante = v_id_estudiante;

    RETURN v_total;
END$$

DELIMITER ;

-- =============================================
-- SCRIPT COMPLETADO
-- =============================================
-- 7 Funciones escalares creadas correctamente.
