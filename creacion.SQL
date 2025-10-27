
CREATE TABLE Estudiantes (
	id_estudiante INT PRIMARY KEY,
	nombre VARCHAR(50) NOT NULL,
	apellido VARCHAR(50) NOT NULL,
	email VARCHAR(50) NOT NULL,
);

CREATE TABLE Profesores (
	id_profesor INT PRIMARY KEY,
	nombre VARCHAR(50) NOT NULL,
	apellido VARCHAR(50) NOT NULL,
	especialidad VARCHAR(50) NOT NULL,
);

CREATE TABLE Materias (
	id_materia INT PRIMARY KEY,
	nombre_materia VARCHAR(50) NOT NULL,
	creditos INT NOT NULL
);

CREATE TABLE Cursos (
	id_curso INT PRIMARY KEY,
	nombre_curso VARCHAR(50),
	descripcion VARCHAR(100),
	anio INT NOT NULL,
	id_profesor INT NOT NULL,
	id_materia INT NOT NULL,
	CONSTRAINT FK_Cursos_Profesores FOREIGN KEY (id_profesor) REFERENCES Profesores(id_profesor),
    CONSTRAINT FK_Cursos_Materias FOREIGN KEY (id_materia) REFERENCES Materias(id_materia)
);

CREATE TABLE Inscripciones (
    id_estudiante INT NOT NULL,
    id_curso INT NOT NULL,
    fecha_inscripcion DATE NOT NULL,
    nota_teorica FLOAT,
    nota_practica FLOAT,
    nota_final FLOAT,
    CONSTRAINT PK_Inscripciones PRIMARY KEY (id_estudiante, id_curso),
    CONSTRAINT FK_Inscripciones_Estudiantes FOREIGN KEY (id_estudiante) REFERENCES Estudiantes(id_estudiante),
    CONSTRAINT FK_Inscripciones_Cursos FOREIGN KEY (id_curso) REFERENCES Cursos(id_curso)
);
