-- =============================================
-- CREACIÓN DE LA BASE (Actividad 1)
-- Estructura base previa a las modificaciones de la Actividad 2
-- SQL estándar compatible con MySQL/MariaDB
-- =============================================

-- Tabla Estudiantes
CREATE TABLE Estudiantes (
    id_estudiante INT PRIMARY KEY AUTO_INCREMENT,
    dni VARCHAR(20) NOT NULL UNIQUE,
    nombre VARCHAR(100) NOT NULL,
    apellido VARCHAR(100) NOT NULL,
    fecha_nacimiento DATE NOT NULL,
    email VARCHAR(100) NOT NULL UNIQUE,
    telefono VARCHAR(20) NULL
);

-- Tabla Profesores
CREATE TABLE Profesores (
    id_profesor INT PRIMARY KEY AUTO_INCREMENT,
    dni VARCHAR(20) NOT NULL UNIQUE,
    nombre VARCHAR(100) NOT NULL,
    apellido VARCHAR(100) NOT NULL,
    especialidad VARCHAR(100) NOT NULL,
    email VARCHAR(100) NOT NULL UNIQUE,
    telefono VARCHAR(20) NULL
);

-- Tabla Materias
CREATE TABLE Materias (
    id_materia INT PRIMARY KEY AUTO_INCREMENT,
    nombre VARCHAR(100) NOT NULL UNIQUE,
    descripcion TEXT NOT NULL,
    creditos INT NOT NULL
);

-- Tabla Cursos
CREATE TABLE Cursos (
    id_curso INT PRIMARY KEY AUTO_INCREMENT,
    id_materia INT NOT NULL,
    id_profesor INT NOT NULL,
    nombre_curso VARCHAR(100) NULL,
    descripcion TEXT NULL,
    anio INT NULL,
    cupo_maximo INT NOT NULL DEFAULT 35,
    horario VARCHAR(100) NULL,
    CONSTRAINT FK_Cursos_Profesores FOREIGN KEY (id_profesor) REFERENCES Profesores(id_profesor),
    CONSTRAINT FK_Cursos_Materias FOREIGN KEY (id_materia) REFERENCES Materias(id_materia)
);

-- Tabla Inscripciones
CREATE TABLE Inscripciones (
    id_inscripcion INT PRIMARY KEY AUTO_INCREMENT,
    id_estudiante INT NOT NULL,
    id_curso INT NOT NULL,
    fecha_inscripcion DATE NOT NULL,
    CONSTRAINT UQ_Inscripciones_Estudiante_Curso UNIQUE (id_estudiante, id_curso),
    CONSTRAINT FK_Inscripciones_Estudiantes FOREIGN KEY (id_estudiante) REFERENCES Estudiantes(id_estudiante),
    CONSTRAINT FK_Inscripciones_Cursos FOREIGN KEY (id_curso) REFERENCES Cursos(id_curso)
);
