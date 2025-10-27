-- =============================================
-- PROCEDIMIENTOS ALMACENADOS - CARGA DE DATOS BÁSICOS
-- Actividad 2: Gestión Académica (1.1)
-- SQL Estándar (compatible MySQL)
-- =============================================

DELIMITER $$

-- =============================================
-- 1.1.1 SP: Cargar Estudiante
-- =============================================
DROP PROCEDURE IF EXISTS SP_CargarEstudiante$$
CREATE PROCEDURE SP_CargarEstudiante(
    IN p_dni VARCHAR(20),
    IN p_nombre VARCHAR(100),
    IN p_apellido VARCHAR(100),
    IN p_fecha_nacimiento DATE,
    IN p_email VARCHAR(100),
    IN p_telefono VARCHAR(20),
    IN p_anio_ingreso INT
)
BEGIN
    DECLARE v_error_msg VARCHAR(500);
    
    -- Validaciones
    IF TRIM(p_dni) = '' THEN
        SET v_error_msg = 'El DNI no puede estar vacío';
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = v_error_msg;
    END IF;
    
    IF TRIM(p_nombre) = '' THEN
        SET v_error_msg = 'El nombre no puede estar vacío';
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = v_error_msg;
    END IF;
    
    IF TRIM(p_apellido) = '' THEN
        SET v_error_msg = 'El apellido no puede estar vacío';
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = v_error_msg;
    END IF;
    
    IF p_fecha_nacimiento >= CURRENT_DATE THEN
        SET v_error_msg = 'La fecha de nacimiento debe ser anterior a hoy';
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = v_error_msg;
    END IF;
    
    -- Verificar si el DNI ya existe
    IF EXISTS (SELECT 1 FROM Estudiantes WHERE dni = p_dni) THEN
        SET v_error_msg = CONCAT('Ya existe un estudiante con DNI: ', p_dni);
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = v_error_msg;
    END IF;
    
    -- Insertar estudiante
    INSERT INTO Estudiantes (
        dni, 
        nombre, 
        apellido, 
        fecha_nacimiento, 
        email, 
        telefono,
        anio_ingreso,
        estado_baja
    ) VALUES (
        TRIM(p_dni),
        TRIM(p_nombre),
        TRIM(p_apellido),
        p_fecha_nacimiento,
        TRIM(p_email),
        TRIM(p_telefono),
        p_anio_ingreso,
        0
    );
    
    SELECT LAST_INSERT_ID() AS id_estudiante;
END$$

-- =============================================
-- 1.1.2 SP: Cargar Profesor
-- =============================================
DROP PROCEDURE IF EXISTS SP_CargarProfesor$$
CREATE PROCEDURE SP_CargarProfesor(
    IN p_dni VARCHAR(20),
    IN p_nombre VARCHAR(100),
    IN p_apellido VARCHAR(100),
    IN p_especialidad VARCHAR(100),
    IN p_email VARCHAR(100),
    IN p_telefono VARCHAR(20)
)
BEGIN
    DECLARE v_error_msg VARCHAR(500);
    
    -- Validaciones
    IF TRIM(p_dni) = '' THEN
        SET v_error_msg = 'El DNI no puede estar vacío';
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = v_error_msg;
    END IF;
    
    IF TRIM(p_nombre) = '' THEN
        SET v_error_msg = 'El nombre no puede estar vacío';
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = v_error_msg;
    END IF;
    
    IF TRIM(p_apellido) = '' THEN
        SET v_error_msg = 'El apellido no puede estar vacío';
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = v_error_msg;
    END IF;
    
    -- Verificar si el DNI ya existe
    IF EXISTS (SELECT 1 FROM Profesores WHERE dni = p_dni) THEN
        SET v_error_msg = CONCAT('Ya existe un profesor con DNI: ', p_dni);
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = v_error_msg;
    END IF;
    
    -- Insertar profesor
    INSERT INTO Profesores (
        dni,
        nombre,
        apellido,
        especialidad,
        email,
        telefono
    ) VALUES (
        TRIM(p_dni),
        TRIM(p_nombre),
        TRIM(p_apellido),
        TRIM(p_especialidad),
        TRIM(p_email),
        TRIM(p_telefono)
    );
    
    SELECT LAST_INSERT_ID() AS id_profesor;
END$$

-- =============================================
-- 1.1.3 SP: Cargar Materia
-- =============================================
DROP PROCEDURE IF EXISTS SP_CargarMateria$$
CREATE PROCEDURE SP_CargarMateria(
    IN p_nombre VARCHAR(100),
    IN p_descripcion TEXT,
    IN p_costo_curso_mensual DECIMAL(10,2)
)
BEGIN
    DECLARE v_error_msg VARCHAR(500);
    
    -- Validaciones
    IF TRIM(p_nombre) = '' THEN
        SET v_error_msg = 'El nombre de la materia no puede estar vacío';
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = v_error_msg;
    END IF;
    
    IF p_costo_curso_mensual < 0 THEN
        SET v_error_msg = 'El costo del curso no puede ser negativo';
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = v_error_msg;
    END IF;
    
    -- Verificar si la materia ya existe
    IF EXISTS (SELECT 1 FROM Materias WHERE nombre = TRIM(p_nombre)) THEN
        SET v_error_msg = CONCAT('Ya existe una materia con el nombre: ', p_nombre);
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = v_error_msg;
    END IF;
    
    -- Insertar materia
    INSERT INTO Materias (
        nombre,
        descripcion,
        costo_curso_mensual
    ) VALUES (
        TRIM(p_nombre),
        p_descripcion,
        p_costo_curso_mensual
    );
    
    SELECT LAST_INSERT_ID() AS id_materia;
END$$

-- =============================================
-- 1.1.4 SP: Cargar Curso
-- =============================================
DROP PROCEDURE IF EXISTS SP_CargarCurso$$
CREATE PROCEDURE SP_CargarCurso(
    IN p_id_materia INT,
    IN p_id_profesor INT,
    IN p_id_cuatrimestre INT,
    IN p_cupo_maximo INT,
    IN p_horario VARCHAR(100)
)
BEGIN
    DECLARE v_error_msg VARCHAR(500);
    
    -- Validaciones
    IF NOT EXISTS (SELECT 1 FROM Materias WHERE id_materia = p_id_materia) THEN
        SET v_error_msg = CONCAT('No existe la materia con ID: ', p_id_materia);
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = v_error_msg;
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM Profesores WHERE id_profesor = p_id_profesor) THEN
        SET v_error_msg = CONCAT('No existe el profesor con ID: ', p_id_profesor);
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = v_error_msg;
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM Cuatrimestre WHERE id_cuatrimestre = p_id_cuatrimestre) THEN
        SET v_error_msg = CONCAT('No existe el cuatrimestre con ID: ', p_id_cuatrimestre);
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = v_error_msg;
    END IF;
    
    IF p_cupo_maximo <= 0 THEN
        SET v_error_msg = 'El cupo máximo debe ser mayor a cero';
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = v_error_msg;
    END IF;
    
    -- Insertar curso
    INSERT INTO Cursos (
        id_materia,
        id_profesor,
        cupo_maximo,
        horario
    ) VALUES (
        p_id_materia,
        p_id_profesor,
        p_cupo_maximo,
        TRIM(p_horario)
    );
    
    SELECT LAST_INSERT_ID() AS id_curso;
END$$

-- =============================================
-- 1.1.5 SP: Cargar Cuatrimestre
-- =============================================
DROP PROCEDURE IF EXISTS SP_CargarCuatrimestre$$
CREATE PROCEDURE SP_CargarCuatrimestre(
    IN p_anio INT,
    IN p_numero_cuatrimestre INT,
    IN p_fecha_inicio DATE,
    IN p_fecha_fin DATE
)
BEGIN
    DECLARE v_error_msg VARCHAR(500);
    
    -- Validaciones
    IF p_numero_cuatrimestre NOT IN (1, 2, 3) THEN
        SET v_error_msg = 'El número de cuatrimestre debe ser 1, 2 o 3';
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = v_error_msg;
    END IF;
    
    IF p_fecha_fin <= p_fecha_inicio THEN
        SET v_error_msg = 'La fecha de fin debe ser posterior a la fecha de inicio';
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = v_error_msg;
    END IF;
    
    -- Verificar si ya existe ese cuatrimestre
    IF EXISTS (SELECT 1 FROM Cuatrimestre 
               WHERE anio = p_anio AND numero_cuatrimestre = p_numero_cuatrimestre) THEN
        SET v_error_msg = CONCAT('Ya existe el cuatrimestre ', p_numero_cuatrimestre, ' del año ', p_anio);
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = v_error_msg;
    END IF;
    
    -- Insertar cuatrimestre
    INSERT INTO Cuatrimestre (
        anio,
        numero_cuatrimestre,
        fecha_inicio,
        fecha_fin
    ) VALUES (
        p_anio,
        p_numero_cuatrimestre,
        p_fecha_inicio,
        p_fecha_fin
    );
    
    SELECT LAST_INSERT_ID() AS id_cuatrimestre;
END$$

-- =============================================
-- 1.1.6 SP: Cargar/Actualizar Interés por Mora
-- =============================================
DROP PROCEDURE IF EXISTS SP_CargarInteresMora$$
CREATE PROCEDURE SP_CargarInteresMora(
    IN p_anio INT,
    IN p_tasa_mensual DECIMAL(5,2)
)
BEGIN
    DECLARE v_error_msg VARCHAR(500);
    DECLARE v_existe INT;
    
    -- Validaciones
    IF p_tasa_mensual < 0 THEN
        SET v_error_msg = 'La tasa de interés no puede ser negativa';
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = v_error_msg;
    END IF;
    
    -- Verificar si ya existe el registro para ese año
    SELECT COUNT(*) INTO v_existe FROM InteresMora WHERE anio = p_anio;
    
    IF v_existe > 0 THEN
        -- Actualizar existente
        UPDATE InteresMora 
        SET tasa_mensual = p_tasa_mensual,
            fecha_vigencia = CURRENT_DATE
        WHERE anio = p_anio;
        
        SELECT CONCAT('Actualizado interés para el año ', p_anio) AS mensaje;
    ELSE
        -- Insertar nuevo
        INSERT INTO InteresMora (
            anio,
            tasa_mensual,
            fecha_vigencia
        ) VALUES (
            p_anio,
            p_tasa_mensual,
            CURRENT_DATE
        );
        
        SELECT LAST_INSERT_ID() AS id_interes_mora;
    END IF;
END$$

DELIMITER ;

-- =============================================
-- SCRIPT COMPLETADO
-- =============================================
-- Procedimientos de carga de datos básicos (1.1) creados correctamente.
-- Total: 6 procedimientos
--   - SP_CargarEstudiante (1.1.1)
--   - SP_CargarProfesor (1.1.2)
--   - SP_CargarMateria (1.1.3)
--   - SP_CargarCurso (1.1.4)
--   - SP_CargarCuatrimestre (1.1.5)
--   - SP_CargarInteresMora (1.1.6)
