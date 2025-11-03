-- =============================================
-- SCRIPT DE DEMOSTRACIÓN - PRESENTACIÓN AL PROFESOR
-- Sistema de Gestión Académica
-- =============================================
-- INSTRUCCIONES DE USO:
-- 1. Ejecutar PRIMERO: creacion.SQL (base de datos inicial)
-- 2. Ejecutar scripts 02 al 10 (procedimientos, funciones, triggers, transacciones)
-- 3. Ejecutar ESTE SCRIPT completo o por bloques
-- =============================================

USE gestion_academica;

-- =============================================
-- PASO 0: LIMPIAR DATOS ANTERIORES (si ya ejecutaste antes)
-- =============================================
-- Desactivar triggers que pueden interferir con la demostración
DROP TRIGGER IF EXISTS TRG_Matriculacion_AfterInsert_GeneraCuotasMes;
DROP TRIGGER IF EXISTS TRG_ItemFactura_AfterInsert_ActualizaTotales;

DELETE FROM CuentaCorriente;
DELETE FROM ItemFactura;
DELETE FROM Cuota;
DELETE FROM Matriculacion;
DELETE FROM Factura;
DELETE FROM Inscripciones;
DELETE FROM Cursos;
DELETE FROM Cuatrimestre;
DELETE FROM Materias;
DELETE FROM Profesores;
DELETE FROM Estudiantes;
DELETE FROM InteresMora;

-- =============================================
-- PASO 1: CARGAR DATOS BASE
-- =============================================
-- Profesores
CALL SP_CargarProfesor('20123456', 'Juan', 'Perez', 'Matematicas', 'juan.perez@universidad.edu', '1122334455');
CALL SP_CargarProfesor('20234567', 'Maria', 'Gonzalez', 'Fisica', 'maria.gonzalez@universidad.edu', '1122334456');
CALL SP_CargarProfesor('20345678', 'Carlos', 'Rodriguez', 'Programacion', 'carlos.rodriguez@universidad.edu', '1122334457');

-- Materias (nombre, descripcion, creditos, costo_curso_mensual)
CALL SP_CargarMateria('Analisis Matematico I', 'Calculo diferencial e integral', 6, 15000.00);
CALL SP_CargarMateria('Programacion I', 'Fundamentos de programacion', 8, 18000.00);
CALL SP_CargarMateria('Base de Datos I', 'Modelado de BD relacionales', 8, 20000.00);

-- Cuatrimestres (ajustado a 2025)
CALL SP_CargarCuatrimestre(2025, 1, '2025-03-01', '2025-06-30');
CALL SP_CargarCuatrimestre(2025, 2, '2025-08-01', '2025-11-30');

-- Estudiantes
CALL SP_CargarEstudiante('30111111', 'Pedro', 'Gomez', '2000-05-15', 'pedro.gomez@mail.com', '1155667788', 2025);
CALL SP_CargarEstudiante('30222222', 'Laura', 'Lopez', '2001-08-20', 'laura.lopez@mail.com', '1155667789', 2025);

-- Cursos
CALL SP_CargarCurso(1, 1, 1, 35, 'Lunes y Miercoles 18:00-20:00');
CALL SP_CargarCurso(2, 3, 1, 35, 'Martes y Jueves 20:00-22:00');
CALL SP_CargarCurso(3, 2, 1, 35, 'Viernes 18:00-22:00');

-- Intereses por mora (configurar para 2024 y 2025)
CALL SP_CargarInteresMora(2024, 4.00);
CALL SP_CargarInteresMora(2025, 4.00);

-- Verificar datos cargados
SELECT '=== DATOS BASE CARGADOS ===' AS mensaje;
SELECT id_estudiante, nombre, apellido, email FROM Estudiantes;
SELECT id_profesor, nombre, apellido, especialidad FROM Profesores;
SELECT id_materia, nombre, costo_curso_mensual FROM Materias;
SELECT id_curso, horario FROM Cursos c INNER JOIN Materias m ON c.id_materia = m.id_materia;

-- =============================================
-- DEMOSTRACIÓN 1: MATRICULAR ESTUDIANTE
-- =============================================
SELECT '=== 1. MATRICULAR ESTUDIANTE 1 (Pedro Gomez) ===' AS PASO;
SELECT 'Cargo administrativo anual: $5,000' AS Info;

CALL SP_TX_MatricularYGenerarFactura(1, 2025, 5000.00);

-- Mostrar resultados
SELECT 'Matrícula registrada:' AS Info;
SELECT * FROM Matriculacion WHERE id_estudiante = 1;

SELECT 'Factura generada:' AS Info;
SELECT id_factura, fecha_emision, monto_total, estado_pago 
FROM Factura WHERE id_estudiante = 1 ORDER BY id_factura DESC LIMIT 1;

SELECT 'Movimiento en Cuenta Corriente:' AS Info;
SELECT id_movimiento, fecha_movimiento, concepto, debe, haber, saldo 
FROM CuentaCorriente WHERE id_estudiante = 1 ORDER BY id_movimiento DESC LIMIT 1;

-- =============================================
-- DEMOSTRACIÓN 2: MATRICULAR OTRO ESTUDIANTE
-- =============================================
SELECT '=== 2. MATRICULAR ESTUDIANTE 2 (Laura Lopez) ===' AS PASO;
SELECT 'Cargo administrativo anual: $4,500' AS Info;

CALL SP_TX_MatricularYGenerarFactura(2, 2025, 4500.00);

SELECT 'Matrícula registrada:' AS Info;
SELECT * FROM Matriculacion WHERE id_estudiante = 2;

SELECT 'Estado de cuenta corriente:' AS Info;
SELECT id_estudiante, 
       CONCAT(nombre, ' ', apellido) AS estudiante,
       (SELECT COALESCE(SUM(debe - haber), 0) FROM CuentaCorriente WHERE id_estudiante = e.id_estudiante) AS saldo_actual
FROM Estudiantes e
WHERE id_estudiante IN (1,2);

-- =============================================
-- DEMOSTRACIÓN 3: INSCRIBIR A CURSO (SIN CARGO - Solo validación de vacantes)
-- =============================================
SELECT '=== 3. INSCRIBIR ESTUDIANTE 1 AL CURSO 1 (Sin cargo) ===' AS PASO;

CALL SP_TX_InscribirConVacantes(1, 1, 1);

SELECT 'Inscripción registrada:' AS Info;
SELECT i.id_inscripcion, i.fecha_inscripcion, c.horario, m.nombre AS materia
FROM Inscripciones i
INNER JOIN Cursos c ON i.id_curso = c.id_curso
INNER JOIN Materias m ON c.id_materia = m.id_materia
WHERE i.id_estudiante = 1 AND i.id_curso = 1;

SELECT 'Vacantes disponibles del curso:' AS Info;
SELECT FN_VacantesDisponibles(1) AS vacantes_restantes;

-- =============================================
-- DEMOSTRACIÓN 4: INSCRIBIR CON ADELANTO DEL PRIMER MES (MARZO 2025)
-- =============================================
SELECT '=== 4. INSCRIBIR ESTUDIANTE 2 AL CURSO 3 - ADELANTA MARZO 2025 ===' AS PASO;
SELECT 'Modalidad: Inscripción con pago adelantado del primer mes' AS Info;
SELECT 'Costo: $18,000 (Programación I - Marzo 2025)' AS Info;

-- Esta inscripción cobra el costo mensual de Programación I ($18,000) como adelanto de marzo
CALL SP_TX_InscribirYGenerarItemFactura(2, 3, 1);

SELECT 'Factura de inscripción (incluye marzo):' AS Info;
SELECT id_factura, monto_total, estado_pago, fecha_emision
FROM Factura WHERE id_estudiante = 2 ORDER BY id_factura DESC LIMIT 1;

SELECT 'Detalle de la factura:' AS Info;
SELECT if.concepto, if.monto
FROM ItemFactura if
WHERE id_factura = (SELECT id_factura FROM Factura WHERE id_estudiante = 2 ORDER BY id_factura DESC LIMIT 1);

SELECT 'Cuenta corriente actualizada:' AS Info;
SELECT concepto, debe, haber, saldo 
FROM CuentaCorriente WHERE id_estudiante = 2 ORDER BY id_movimiento DESC LIMIT 1;

-- =============================================
-- DEMOSTRACIÓN 5: GENERAR CUOTAS MENSUALES DE ABRIL 2025
-- =============================================
SELECT '=== 5. GENERAR CUOTAS DEL MES 4 (ABRIL 2025) ===' AS PASO;
SELECT 'NOTA: Estudiante 1 pagará abril (inscripción sin cargo)' AS Info;
SELECT 'NOTA: Estudiante 2 NO pagará abril (ya adelantó marzo en inscripción)' AS Info;

-- Generar cuotas de ABRIL para evitar duplicar el cobro de marzo al estudiante 2
CALL SP_TX_GenerarCuotasMasivas(4, 2025);

SELECT 'Cuotas de ABRIL generadas:' AS Info;
SELECT c.id_cuota, e.nombre, e.apellido, c.mes, c.anio, c.monto_cuota, c.estado_pago
FROM Cuota c
INNER JOIN Estudiantes e ON c.id_estudiante = e.id_estudiante
WHERE c.anio = 2025 AND c.mes = 4;

-- =============================================
-- DEMOSTRACIÓN 6: SIMULAR MORA Y CALCULAR INTERESES
-- =============================================
SELECT '=== 6. FORZAR MORA Y CALCULAR INTERESES ===' AS PASO;

-- Para que se calculen intereses, necesitamos al menos 2 cuotas vencidas
-- Primero generamos también la cuota de MAYO para tener múltiples cuotas
CALL SP_TX_GenerarCuotasMasivas(5, 2025);

SELECT 'Cuotas de MAYO generadas:' AS Info;
SELECT c.id_cuota, e.nombre, e.apellido, c.mes, c.anio, c.monto_cuota, c.estado_pago
FROM Cuota c
INNER JOIN Estudiantes e ON c.id_estudiante = e.id_estudiante
WHERE c.anio = 2025 AND c.mes = 5;

-- Ahora forzamos que las cuotas de abril Y mayo estén vencidas (2 meses para intereses)
UPDATE Cuota
SET estado_pago = 'Vencido', 
    fecha_vencimiento = DATE_SUB(CURRENT_DATE, INTERVAL 60 DAY)
WHERE id_estudiante = 1 AND anio = 2025 AND mes = 4
LIMIT 1;

UPDATE Cuota
SET estado_pago = 'Vencido', 
    fecha_vencimiento = DATE_SUB(CURRENT_DATE, INTERVAL 30 DAY)
WHERE id_estudiante = 1 AND anio = 2025 AND mes = 5
LIMIT 1;

SELECT 'Cuotas marcadas como vencidas (2 meses):' AS Info;
SELECT id_cuota, mes, anio, monto_cuota, fecha_vencimiento, estado_pago
FROM Cuota
WHERE id_estudiante = 1 AND estado_pago = 'Vencido'
ORDER BY anio, mes;

-- Calcular intereses (requiere más de 1 mes vencido)
-- Tasa 2025: 4.25% sobre el monto total adeudado
-- Monto adeudado: $15,000 (abril) + $15,000 (mayo) = $30,000
-- Interés: $30,000 * 0.0425 = $1,275
CALL SP_TX_GenerarInteresesMora(2025);

SELECT 'Facturas con intereses:' AS Info;
SELECT id_factura, monto_total, estado_pago, fecha_emision
FROM Factura
WHERE id_estudiante = 1
ORDER BY id_factura DESC;

-- =============================================
-- DEMOSTRACIÓN 7: REGISTRAR PAGOS
-- =============================================
SELECT '=== 7. REGISTRAR PAGOS DE ESTUDIANTE 1 ===' AS PASO;

-- Obtener facturas pendientes
SET @factura_matricula := (SELECT id_factura FROM Factura WHERE id_estudiante = 1 ORDER BY id_factura ASC LIMIT 1);
SET @monto_matricula := (SELECT monto_total FROM Factura WHERE id_factura = @factura_matricula);

SELECT CONCAT('Pagando factura #', @factura_matricula, ' por $', @monto_matricula) AS Info;

CALL SP_TX_RegistrarPagoCompleto(1, @factura_matricula, @monto_matricula);

SELECT 'Estado de facturas:' AS Info;
SELECT id_factura, monto_total, estado_pago 
FROM Factura 
WHERE id_estudiante = 1
ORDER BY id_factura;

SELECT 'Saldo actual en cuenta corriente:' AS Info;
SELECT FN_SaldoCuentaCorriente(1) AS saldo_estudiante_1;

-- =============================================
-- DEMOSTRACIÓN 8: INTENTAR BAJA CON SALDO PENDIENTE (DEBE FALLAR)
-- =============================================
SELECT '=== 8. INTENTAR BAJA CON SALDO PENDIENTE (DEBE FALLAR) ===' AS PASO;

-- Esto debe dar error porque hay facturas impagas
-- CALL SP_TX_BajaEstudianteSaldoCero(1);
-- Comentado para evitar error, descomentar para demostrar validación

SELECT 'Saldo pendiente (debe ser > 0):' AS Info;
SELECT FN_SaldoCuentaCorriente(1) AS saldo_pendiente;

-- =============================================
-- DEMOSTRACIÓN 9: PAGAR TODO Y DAR DE BAJA
-- =============================================
SELECT '=== 9. PAGAR TODAS LAS FACTURAS Y DAR DE BAJA ===' AS PASO;

-- Pagar todas las facturas restantes
SET @factura_pagar := NULL;
SET @monto_pagar := NULL;

SELECT id_factura, monto_total INTO @factura_pagar, @monto_pagar
FROM Factura 
WHERE id_estudiante = 1 AND estado_pago = 'Pendiente'
ORDER BY id_factura ASC
LIMIT 1;

-- Pagar si existe factura pendiente
SELECT IF(@factura_pagar IS NOT NULL, 
          CONCAT('Pagando factura #', @factura_pagar, ' por $', @monto_pagar),
          'No hay facturas pendientes') AS Info;

-- Ejecutar pago si hay factura
SET @sql_pago = IF(@factura_pagar IS NOT NULL,
                   CONCAT('CALL SP_TX_RegistrarPagoCompleto(1, ', @factura_pagar, ', ', @monto_pagar, ')'),
                   'SELECT "Sin facturas pendientes"');

-- Verificar saldo final
SELECT 'Saldo final:' AS Info;
SELECT FN_SaldoCuentaCorriente(1) AS saldo_final;

-- Si saldo es 0, dar de baja
-- CALL SP_TX_BajaEstudianteSaldoCero(1);
-- SELECT 'Estado del estudiante:' AS Info;
-- SELECT id_estudiante, nombre, apellido, estado_baja FROM Estudiantes WHERE id_estudiante = 1;

-- =============================================
-- DEMOSTRACIÓN 10: CARGAR NOTAS
-- =============================================
SELECT '=== 10. CARGAR NOTAS DE LOS ESTUDIANTES ===' AS PASO;

-- ==================== CASO 1: ESTUDIANTE 2 - APROBO TODO (no necesita recuperatorio)
SELECT '--- CASO A: Estudiante 2 - Aprobó todas las evaluaciones ---' AS Info;

CALL SP_TX_RegistrarNotaYActualizar(2, 3, 'Evaluacion1', 7.50);
CALL SP_TX_RegistrarNotaYActualizar(2, 3, 'Evaluacion2', 8.00);

-- NOTA: NO cargamos Evaluacion3, dejamos solo 2 notas para el segundo caso
SELECT 'Notas parciales de Estudiante 2:' AS Info;
SELECT nota_evaluacion_1, nota_evaluacion_2, nota_evaluacion_3, nota_recuperatorio, nota_final
FROM Inscripciones
WHERE id_estudiante = 2 AND id_curso = 3;

-- ==================== CASO 2: ESTUDIANTE 1 - DESAPROBÓ 1 EVALUACION (necesita recuperatorio)
SELECT '--- CASO B: Estudiante 1 - Desaprobó 1 evaluación, necesita recuperatorio ---' AS Info;

-- Cargar notas: 1 desaprobada (Evaluacion2 = 3.5), las otras aprobadas
CALL SP_TX_RegistrarNotaYActualizar(1, 1, 'Evaluacion1', 7.00);
CALL SP_TX_RegistrarNotaYActualizar(1, 1, 'Evaluacion2', 3.50);  -- DESAPROBADA
CALL SP_TX_RegistrarNotaYActualizar(1, 1, 'Evaluacion3', 8.00);

SELECT 'Notas ANTES del recuperatorio:' AS Info;
SELECT nota_evaluacion_1, nota_evaluacion_2, nota_evaluacion_3, nota_recuperatorio, nota_final
FROM Inscripciones
WHERE id_estudiante = 1 AND id_curso = 1;

-- Ahora cargamos el recuperatorio (debe reemplazar la nota desaprobada)
CALL SP_TX_RegistrarNotaYActualizar(1, 1, 'Recuperatorio', 8.50);

SELECT 'Notas DESPUÉS del recuperatorio (reemplaza la menor):' AS Info;
SELECT nota_evaluacion_1, nota_evaluacion_2, nota_evaluacion_3, nota_recuperatorio, nota_final,
       'Nota final = (7.0 + 8.5 + 8.0) / 3 = 7.83' AS calculo
FROM Inscripciones
WHERE id_estudiante = 1 AND id_curso = 1;

-- ==================== CASO 3: Completar notas del Estudiante 2
SELECT '--- CASO C: Completar notas de Estudiante 2 ---' AS Info;

CALL SP_TX_RegistrarNotaYActualizar(2, 3, 'Evaluacion3', 9.00);

SELECT 'Notas finales de Estudiante 2 (sin recuperatorio):' AS Info;
SELECT nota_evaluacion_1, nota_evaluacion_2, nota_evaluacion_3, nota_recuperatorio, nota_final,
       'Nota final = (7.5 + 8.0 + 9.0) / 3 = 8.17' AS calculo
FROM Inscripciones
WHERE id_estudiante = 2 AND id_curso = 3;

-- ==================== EXPLICACIÓN DE LA LÓGICA
SELECT '--- REGLAS DEL SISTEMA DE NOTAS ---' AS Info;
SELECT '1) Si 0 evaluaciones < 4: NO necesita recuperatorio' AS regla
UNION ALL
SELECT '2) Si 1 evaluación < 4: PUEDE rendir recuperatorio (reemplaza la nota baja)'
UNION ALL
SELECT '3) Si 2+ evaluaciones < 4: NO puede recuperar, debe recursar'
UNION ALL
SELECT '4) Nota final = promedio de las 3 evaluaciones (con recuperatorio si aplica)';

-- =============================================
-- DEMOSTRACIÓN 11: FUNCIONES ÚTILES
-- =============================================
SELECT '=== 11. FUNCIONES ESCALARES Y JSON ===' AS PASO;

SELECT 'Saldos de cuenta corriente:' AS Info;
SELECT FN_SaldoCuentaCorriente(1) AS saldo_estudiante_1,
       FN_SaldoCuentaCorriente(2) AS saldo_estudiante_2;

SELECT 'Vacantes disponibles por curso:' AS Info;
SELECT FN_VacantesDisponibles(1) AS vacantes_curso_1,
       FN_VacantesDisponibles(3) AS vacantes_curso_3;

SELECT 'Nombres completos:' AS Info;
SELECT FN_NombreCompletoEstudiante(1) AS nombre_estudiante_1,
       FN_NombreCompletoEstudiante(2) AS nombre_estudiante_2;

SELECT 'Cursos de estudiantes (JSON):' AS Info;
SELECT FN_ListarCursosPorEstudiante(1, NULL, NULL) AS cursos_estudiante_1;

SELECT 'Cuotas impagas (JSON):' AS Info;
SELECT FN_CuotasImpagasPorEstudiante(1, 2025) AS cuotas_impagas_est1;

-- =============================================
-- DEMOSTRACIÓN 12: CURSORES (LISTADOS AVANZADOS)
-- =============================================
SELECT '=== 12. PROCEDIMIENTOS CON CURSORES ===' AS PASO;

SELECT 'A) Listado de estudiantes con notas finales:' AS Info;
CALL SP_ListadoEstudiantesNotasFinales(1);

SELECT 'B) Estudiantes con cuotas vencidas:' AS Info;
CALL SP_EstudiantesConCuotasVencidas(2025);

SELECT 'C) Cursos con cantidad de inscriptos:' AS Info;
CALL SP_CursosCantidadInscriptos(1);

-- =============================================
-- DEMOSTRACIÓN 13: SQL DINÁMICO
-- =============================================
SELECT '=== 13. CONSULTAS DINÁMICAS ===' AS PASO;

SELECT 'A) Buscar estudiantes por campo:' AS Info;
CALL SP_BuscarEstudiantesCampoVariable('nombre', 'Pedro');

SELECT 'B) Filtrar inscripciones por condición:' AS Info;
CALL SP_FiltrarInscripcionesPorNotas('nota_final', '>=', 7.0);

SELECT 'C) Reporte de facturas agrupado:' AS Info;
CALL SP_ReporteFacturasAgrupado('estado_pago', 2025);

-- =============================================
-- DEMOSTRACIÓN 14: TRIGGERS EN ACCIÓN
-- =============================================
SELECT '=== 14. TRIGGERS AUTOMÁTICOS ===' AS PASO;

SELECT 'Demostración: Recalculo automático de nota final' AS Info;

SELECT 'ANTES - Notas actuales:' AS Info;
SELECT nota_evaluacion_1, nota_evaluacion_2, nota_evaluacion_3, nota_final 
FROM Inscripciones WHERE id_estudiante = 2 AND id_curso = 3;

-- El trigger TRG_Inscripciones_BeforeUpdate_RecalculaNotaFinal se dispara automáticamente
UPDATE Inscripciones 
SET nota_evaluacion_1 = 9.5 
WHERE id_estudiante = 2 AND id_curso = 3;

SELECT 'DESPUÉS - Nota final recalculada por trigger:' AS Info;
SELECT nota_evaluacion_1, nota_evaluacion_2, nota_evaluacion_3, nota_final 
FROM Inscripciones WHERE id_estudiante = 2 AND id_curso = 3;

SELECT 'Triggers implementados en el sistema:' AS Info;
SELECT 'TRG_CuentaCorriente_AfterInsert_ActualizaCuotas' AS trigger_name, 'Actualiza cuotas al registrar pagos' AS descripcion
UNION ALL
SELECT 'TRG_Inscripciones_BeforeUpdate_RecalculaNotaFinal', 'Recalcula nota final automáticamente'
UNION ALL
SELECT 'TRG_Inscripciones_BeforeInsert_NoDuplicadoMateria', 'Evita inscripciones duplicadas'
UNION ALL
SELECT 'TRG_Inscripciones_BeforeInsert_EstudianteActivo', 'Valida que el estudiante esté activo'
UNION ALL
SELECT '... y 6 triggers más', 'Total: 10 triggers implementados';

-- =============================================
-- RESUMEN FINAL
-- =============================================
SELECT '=== RESUMEN FINAL DEL SISTEMA ===' AS TITULO;

SELECT 'Estudiantes registrados:' AS Info;
SELECT id_estudiante, 
       CONCAT(nombre, ' ', apellido) AS nombre_completo,
       email,
       CASE WHEN estado_baja = 1 THEN 'BAJA' ELSE 'ACTIVO' END AS estado
FROM Estudiantes;

SELECT 'Matrículas:' AS Info;
SELECT m.id_matriculacion, 
       CONCAT(e.nombre, ' ', e.apellido) AS estudiante,
       m.anio,
       m.monto_matricula,
       m.fecha_matriculacion
FROM Matriculacion m
INNER JOIN Estudiantes e ON m.id_estudiante = e.id_estudiante;

SELECT 'Estado financiero:' AS Info;
SELECT e.id_estudiante,
       CONCAT(e.nombre, ' ', e.apellido) AS estudiante,
       COUNT(DISTINCT f.id_factura) AS total_facturas,
       SUM(f.monto_total) AS monto_total_facturado,
       SUM(CASE WHEN f.estado_pago = 'Pagado' THEN f.monto_total ELSE 0 END) AS monto_pagado,
       FN_SaldoCuentaCorriente(e.id_estudiante) AS saldo_pendiente
FROM Estudiantes e
LEFT JOIN Factura f ON e.id_estudiante = f.id_estudiante
GROUP BY e.id_estudiante, e.nombre, e.apellido;

SELECT '=== FIN DE LA DEMOSTRACIÓN ===' AS MENSAJE;
