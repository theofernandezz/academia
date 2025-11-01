-- =============================================
-- DATOS DE PRUEBA
-- Actividad 2: Gestion Academica
-- SQL Estandar (compatible MySQL)
-- =============================================

-- =============================================
-- 1. CARGAR PROFESORES
-- =============================================
CALL SP_CargarProfesor('20123456', 'Juan', 'Perez', 'Matematicas', 'juan.perez@universidad.edu', '1122334455');
CALL SP_CargarProfesor('20234567', 'Maria', 'Gonzalez', 'Fisica', 'maria.gonzalez@universidad.edu', '1122334456');
CALL SP_CargarProfesor('20345678', 'Carlos', 'Rodriguez', 'Programacion', 'carlos.rodriguez@universidad.edu', '1122334457');
CALL SP_CargarProfesor('20456789', 'Ana', 'Martinez', 'Base de Datos', 'ana.martinez@universidad.edu', '1122334458');
CALL SP_CargarProfesor('20567890', 'Luis', 'Fernandez', 'Redes', 'luis.fernandez@universidad.edu', '1122334459');

-- =============================================
-- 2. CARGAR MATERIAS
-- =============================================
CALL SP_CargarMateria('Analisis Matematico I', 'Introduccion al calculo diferencial e integral', 6, 15000.00);
CALL SP_CargarMateria('Algebra Lineal', 'Estudio de vectores, matrices y espacios vectoriales', 6, 15000.00);
CALL SP_CargarMateria('Programacion I', 'Fundamentos de programacion y algoritmos', 8, 18000.00);
CALL SP_CargarMateria('Base de Datos I', 'Diseno y modelado de bases de datos relacionales', 7, 20000.00);
CALL SP_CargarMateria('Fisica I', 'Mecanica clasica y cinematica', 6, 16000.00);
CALL SP_CargarMateria('Redes y Comunicaciones', 'Protocolos de red y arquitecturas', 7, 19000.00);

-- =============================================
-- 3. CARGAR CUATRIMESTRES
-- =============================================
CALL SP_CargarCuatrimestre(2024, 1, '2024-03-01', '2024-06-30');
CALL SP_CargarCuatrimestre(2024, 2, '2024-08-01', '2024-11-30');
CALL SP_CargarCuatrimestre(2025, 1, '2025-03-01', '2025-06-30');

-- =============================================
-- 4. CARGAR ESTUDIANTES
-- =============================================
CALL SP_CargarEstudiante('30111111', 'Pedro', 'Gomez', '2000-05-15', 'pedro.gomez@mail.com', '1155667788', 2024);
CALL SP_CargarEstudiante('30222222', 'Laura', 'Lopez', '2001-08-20', 'laura.lopez@mail.com', '1155667789', 2024);
CALL SP_CargarEstudiante('30333333', 'Diego', 'Sanchez', '2000-11-10', 'diego.sanchez@mail.com', '1155667790', 2024);
CALL SP_CargarEstudiante('30444444', 'Sofia', 'Ramirez', '2001-02-28', 'sofia.ramirez@mail.com', '1155667791', 2024);
CALL SP_CargarEstudiante('30555555', 'Martin', 'Torres', '2000-07-05', 'martin.torres@mail.com', '1155667792', 2024);
CALL SP_CargarEstudiante('30666666', 'Valentina', 'Flores', '2001-09-12', 'valentina.flores@mail.com', '1155667793', 2024);
CALL SP_CargarEstudiante('30777777', 'Facundo', 'Ruiz', '2000-12-30', 'facundo.ruiz@mail.com', '1155667794', 2024);
CALL SP_CargarEstudiante('30888888', 'Camila', 'Diaz', '2001-04-18', 'camila.diaz@mail.com', '1155667795', 2024);
CALL SP_CargarEstudiante('30999999', 'Nicolas', 'Moreno', '2000-06-22', 'nicolas.moreno@mail.com', '1155667796', 2024);
CALL SP_CargarEstudiante('31000000', 'Lucia', 'Herrera', '2001-10-08', 'lucia.herrera@mail.com', '1155667797', 2024);

-- =============================================
-- 5. CARGAR CURSOS
-- =============================================
-- Cursos del primer cuatrimestre 2024
CALL SP_CargarCurso(1, 1, 1, 35, 'Lunes y Miercoles 18:00-20:00');
CALL SP_CargarCurso(2, 1, 1, 35, 'Martes y Jueves 18:00-20:00');
CALL SP_CargarCurso(3, 3, 1, 35, 'Lunes y Miercoles 20:00-22:00');
CALL SP_CargarCurso(4, 4, 1, 35, 'Martes y Jueves 20:00-22:00');

-- Cursos del segundo cuatrimestre 2024
CALL SP_CargarCurso(5, 2, 2, 35, 'Lunes y Miercoles 18:00-20:00');
CALL SP_CargarCurso(6, 5, 2, 35, 'Martes y Jueves 18:00-20:00');
CALL SP_CargarCurso(1, 1, 2, 35, 'Viernes 18:00-22:00');

-- Cursos del primer cuatrimestre 2025
CALL SP_CargarCurso(3, 3, 3, 35, 'Lunes y Miercoles 18:00-20:00');
CALL SP_CargarCurso(4, 4, 3, 35, 'Martes y Jueves 18:00-20:00');

-- =============================================
-- 6. CARGAR INTERESES POR MORA
-- =============================================
CALL SP_CargarInteresMora(2023, 3.50);
CALL SP_CargarInteresMora(2024, 4.00);
CALL SP_CargarInteresMora(2025, 4.50);

-- Actualizar uno existente para probar la funcionalidad
CALL SP_CargarInteresMora(2024, 4.25);

-- =============================================
-- SCRIPT COMPLETADO
-- =============================================
-- Datos de prueba cargados correctamente.
-- Total: 5 profesores, 6 materias, 10 estudiantes, 3 cuatrimestres, 9 cursos, 3 tasas de interes.
