-- =============================================
-- MODIFICACIONES A LA BASE DE DATOS EXISTENTE
-- Actividad 2: Gestión Académica
-- SQL Estándar (compatible MySQL/PostgreSQL)
-- =============================================
-- Este script adapta la estructura de la Actividad 1 al nuevo modelo completo
-- Ejecutar sobre la base de datos creada con creacion.SQL

-- =============================================
-- 1. MODIFICACIONES A TABLAS EXISTENTES
-- =============================================

-- Modificar tabla Estudiantes: agregar campos nuevos
ALTER TABLE Estudiantes 
    ADD COLUMN anio_ingreso INT NOT NULL DEFAULT 2024,
    ADD COLUMN estado_baja TINYINT NOT NULL DEFAULT 0;

-- Modificar tabla Materias: agregar costo de curso mensual
ALTER TABLE Materias 
    ADD COLUMN costo_curso_mensual DECIMAL(10,2) NOT NULL DEFAULT 0;

-- Modificar tabla Inscripciones: agregar estructura de notas
ALTER TABLE Inscripciones 
    ADD COLUMN nota_evaluacion_1 DECIMAL(4,2) NULL,
    ADD COLUMN nota_evaluacion_2 DECIMAL(4,2) NULL,
    ADD COLUMN nota_evaluacion_3 DECIMAL(4,2) NULL,
    ADD COLUMN nota_recuperatorio DECIMAL(4,2) NULL,
    ADD COLUMN nota_final DECIMAL(4,2) NULL,
    ADD COLUMN id_cuatrimestre INT NOT NULL DEFAULT 1;

-- =============================================
-- 2. CREACIÓN DE NUEVAS TABLAS
-- =============================================

-- Tabla Cuatrimestre
CREATE TABLE Cuatrimestre (
    id_cuatrimestre INT PRIMARY KEY AUTO_INCREMENT,
    anio INT NOT NULL,
    numero_cuatrimestre INT NOT NULL CHECK (numero_cuatrimestre IN (1,2,3)),
    fecha_inicio DATE NOT NULL,
    fecha_fin DATE NOT NULL,
    CONSTRAINT UQ_Cuatrimestre_Anio_Numero UNIQUE (anio, numero_cuatrimestre),
    CONSTRAINT CHK_Cuatrimestre_Fechas CHECK (fecha_fin > fecha_inicio)
);

-- Tabla Factura
CREATE TABLE Factura (
    id_factura INT PRIMARY KEY AUTO_INCREMENT,
    id_estudiante INT NOT NULL,
    fecha_emision DATE NOT NULL DEFAULT (CURRENT_DATE),
    monto_total DECIMAL(10,2) NOT NULL DEFAULT 0,
    estado_pago VARCHAR(20) NOT NULL DEFAULT 'Pendiente' CHECK (estado_pago IN ('Pendiente', 'Pagado', 'Vencido')),
    CONSTRAINT FK_Factura_Estudiante FOREIGN KEY (id_estudiante) REFERENCES Estudiantes(id_estudiante)
);

-- Tabla Matriculacion
CREATE TABLE Matriculacion (
    id_matriculacion INT PRIMARY KEY AUTO_INCREMENT,
    id_estudiante INT NOT NULL,
    anio INT NOT NULL,
    monto_matricula DECIMAL(10,2) NOT NULL,
    fecha_matriculacion DATE NOT NULL DEFAULT (CURRENT_DATE),
    id_factura INT NULL,
    CONSTRAINT FK_Matriculacion_Estudiante FOREIGN KEY (id_estudiante) REFERENCES Estudiantes(id_estudiante),
    CONSTRAINT FK_Matriculacion_Factura FOREIGN KEY (id_factura) REFERENCES Factura(id_factura),
    CONSTRAINT UQ_Matriculacion_Estudiante_Anio UNIQUE (id_estudiante, anio)
);

-- Tabla Cuota
CREATE TABLE Cuota (
    id_cuota INT PRIMARY KEY AUTO_INCREMENT,
    id_estudiante INT NOT NULL,
    id_curso INT NOT NULL,
    mes INT NOT NULL CHECK (mes BETWEEN 1 AND 12),
    anio INT NOT NULL,
    monto_cuota DECIMAL(10,2) NOT NULL,
    fecha_vencimiento DATE NOT NULL,
    estado_pago VARCHAR(20) NOT NULL DEFAULT 'Pendiente' CHECK (estado_pago IN ('Pendiente', 'Pagado', 'Vencido')),
    id_factura INT NULL,
    CONSTRAINT FK_Cuota_Estudiante FOREIGN KEY (id_estudiante) REFERENCES Estudiantes(id_estudiante),
    CONSTRAINT FK_Cuota_Curso FOREIGN KEY (id_curso) REFERENCES Cursos(id_curso),
    CONSTRAINT FK_Cuota_Factura FOREIGN KEY (id_factura) REFERENCES Factura(id_factura),
    CONSTRAINT UQ_Cuota_Estudiante_Curso_Periodo UNIQUE (id_estudiante, id_curso, mes, anio)
);

-- Tabla CuentaCorriente
CREATE TABLE CuentaCorriente (
    id_movimiento INT PRIMARY KEY AUTO_INCREMENT,
    id_estudiante INT NOT NULL,
    fecha_movimiento DATE NOT NULL DEFAULT (CURRENT_DATE),
    concepto VARCHAR(100) NOT NULL,
    debe DECIMAL(10,2) NOT NULL DEFAULT 0,
    haber DECIMAL(10,2) NOT NULL DEFAULT 0,
    saldo DECIMAL(10,2) NOT NULL DEFAULT 0,
    id_factura INT NULL,
    CONSTRAINT FK_CuentaCorriente_Estudiante FOREIGN KEY (id_estudiante) REFERENCES Estudiantes(id_estudiante),
    CONSTRAINT FK_CuentaCorriente_Factura FOREIGN KEY (id_factura) REFERENCES Factura(id_factura),
    CONSTRAINT CHK_CuentaCorriente_Debe_Haber CHECK (debe >= 0 AND haber >= 0)
);

-- Tabla InteresMora
CREATE TABLE InteresMora (
    id_interes_mora INT PRIMARY KEY AUTO_INCREMENT,
    anio INT NOT NULL UNIQUE,
    tasa_mensual DECIMAL(5,2) NOT NULL CHECK (tasa_mensual >= 0),
    fecha_vigencia DATE NOT NULL DEFAULT (CURRENT_DATE)
);

-- Tabla ItemFactura (detalle de conceptos en cada factura)
CREATE TABLE ItemFactura (
    id_item_factura INT PRIMARY KEY AUTO_INCREMENT,
    id_factura INT NOT NULL,
    concepto VARCHAR(100) NOT NULL,
    monto DECIMAL(10,2) NOT NULL,
    CONSTRAINT FK_ItemFactura_Factura FOREIGN KEY (id_factura) REFERENCES Factura(id_factura)
);

-- =============================================
-- 3. ÍNDICES PARA OPTIMIZACIÓN
-- =============================================

-- Índices en tabla Inscripciones
CREATE INDEX IX_Inscripciones_Estudiante ON Inscripciones(id_estudiante);
CREATE INDEX IX_Inscripciones_Curso ON Inscripciones(id_curso);
CREATE INDEX IX_Inscripciones_Cuatrimestre ON Inscripciones(id_cuatrimestre);

-- Índices en tabla Cuota
CREATE INDEX IX_Cuota_Estudiante ON Cuota(id_estudiante);
CREATE INDEX IX_Cuota_Curso ON Cuota(id_curso);
CREATE INDEX IX_Cuota_Estado_Pago ON Cuota(estado_pago);

-- Índices en tabla CuentaCorriente
CREATE INDEX IX_CuentaCorriente_Estudiante ON CuentaCorriente(id_estudiante);
CREATE INDEX IX_CuentaCorriente_Fecha ON CuentaCorriente(fecha_movimiento);

-- Índices en tabla Factura
CREATE INDEX IX_Factura_Estudiante ON Factura(id_estudiante);
CREATE INDEX IX_Factura_Estado_Pago ON Factura(estado_pago);

-- Índices en tabla Matriculacion
CREATE INDEX IX_Matriculacion_Estudiante ON Matriculacion(id_estudiante);
CREATE INDEX IX_Matriculacion_Anio ON Matriculacion(anio);

-- =============================================
-- SCRIPT COMPLETADO
-- =============================================
-- Estructura de base de datos actualizada según requisitos de Actividad 2.
