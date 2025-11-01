-- =============================================
-- 11_simulacion_pruebas.sql
-- Escenario integral para validar procedimientos, triggers y funciones
-- Ejecutar despues de cargar 04_datos_prueba.sql y crear todos los objetos.
-- =============================================

USE gestion_academica;

-- Limpiar datos previos del escenario
SET FOREIGN_KEY_CHECKS = 0;
TRUNCATE TABLE CuentaCorriente;
TRUNCATE TABLE ItemFactura;
TRUNCATE TABLE Cuota;
TRUNCATE TABLE Matriculacion;
TRUNCATE TABLE Factura;
TRUNCATE TABLE Inscripciones;
SET FOREIGN_KEY_CHECKS = 1;

-- =============================================
-- Paso 1: Matricular al estudiante 1 en 2024 (genera factura + movimiento)
-- =============================================
CALL SP_TX_MatricularYGenerarFactura(1, 2024, 5000.00);
SELECT * FROM Matriculacion WHERE id_estudiante = 1 ORDER BY id_matriculacion DESC LIMIT 1;
SELECT * FROM Factura WHERE id_estudiante = 1 ORDER BY id_factura DESC LIMIT 1;
SELECT * FROM CuentaCorriente WHERE id_estudiante = 1 ORDER BY id_movimiento DESC LIMIT 3;

-- =============================================
-- Paso 2: Inscribir al estudiante en cursos (con validacion de vacantes y factura automatica)
-- =============================================
CALL SP_TX_InscribirConVacantes(1, 1, 1);
CALL SP_TX_InscribirYGenerarItemFactura(1, 2, 1);
SELECT * FROM Inscripciones WHERE id_estudiante = 1 ORDER BY id_inscripcion DESC;
SELECT * FROM Factura WHERE id_estudiante = 1 ORDER BY id_factura DESC LIMIT 2;
SELECT * FROM CuentaCorriente WHERE id_estudiante = 1 ORDER BY id_movimiento DESC LIMIT 5;

SET @factura_matricula := (
    SELECT id_factura FROM Factura
    WHERE id_estudiante = 1
    ORDER BY id_factura ASC LIMIT 1
);

SET @factura_inscripcion := (
    SELECT id_factura FROM Factura
    WHERE id_estudiante = 1
    ORDER BY id_factura DESC LIMIT 1
);

-- =============================================
-- Paso 3: Generar cuotas masivas para marzo 2024
-- =============================================
CALL SP_TX_GenerarCuotasMasivas(3, 2024);
SELECT * FROM Cuota WHERE id_estudiante = 1 AND mes = 3 AND anio = 2024;

-- Forzamos una cuota a estado vencido para evaluar interes por mora
UPDATE Cuota
SET estado_pago = 'Vencido', fecha_vencimiento = DATE_SUB(CURRENT_DATE, INTERVAL 15 DAY)
WHERE id_estudiante = 1 AND mes = 3 AND anio = 2024
ORDER BY id_cuota ASC
LIMIT 1;

-- =============================================
-- Paso 4: Generar intereses de mora para cuotas vencidas
-- =============================================
CALL SP_TX_GenerarInteresesMora(2024);
SELECT * FROM CuentaCorriente WHERE id_estudiante = 1 ORDER BY id_movimiento DESC LIMIT 5;

-- =============================================
-- Paso 5: Emitir una factura agrupando cuotas impagas de marzo 2024
-- =============================================
SET @cuotas_pendientes := (
    SELECT COUNT(*)
    FROM Cuota
    WHERE id_estudiante = 1
      AND estado_pago = 'Pendiente'
      AND mes = 3
      AND anio = 2024
);

SET @sql_emitir_cuotas := IF(@cuotas_pendientes > 0,
    'CALL SP_TX_EmitirFacturaCuotasImpagas(1, 3, 2024);',
    'SELECT ''No hay cuotas impagas para facturar'' AS aviso;');
PREPARE stmt_emitir_cuotas FROM @sql_emitir_cuotas;
EXECUTE stmt_emitir_cuotas;
DEALLOCATE PREPARE stmt_emitir_cuotas;

SET @factura_cuotas := IF(@cuotas_pendientes > 0,
    (SELECT id_factura FROM Factura
     WHERE id_estudiante = 1
     ORDER BY id_factura DESC LIMIT 1),
    NULL);

SELECT * FROM Factura
WHERE id_factura = @factura_cuotas
  AND @factura_cuotas IS NOT NULL;

SELECT * FROM ItemFactura
WHERE id_factura = @factura_cuotas
  AND @factura_cuotas IS NOT NULL;

SELECT * FROM CuentaCorriente
WHERE id_estudiante = 1
  AND @factura_cuotas IS NOT NULL
ORDER BY id_movimiento DESC
LIMIT 5;

-- =============================================
-- Paso 6: Registrar pago completo de la ultima factura emitida
-- =============================================
SET @monto_factura := IF(@factura_cuotas IS NOT NULL,
    (SELECT monto_total FROM Factura WHERE id_factura = @factura_cuotas),
    0);

SET @sql_pago_cuotas := IF(@factura_cuotas IS NOT NULL,
    CONCAT('CALL SP_TX_RegistrarPagoCompleto(1, ', @factura_cuotas, ', ', @monto_factura, ');'),
    'SELECT ''No se genero factura de cuotas'' AS aviso;');
PREPARE stmt_pago_cuotas FROM @sql_pago_cuotas;
EXECUTE stmt_pago_cuotas;
DEALLOCATE PREPARE stmt_pago_cuotas;

SELECT * FROM CuentaCorriente
WHERE id_estudiante = 1
  AND @factura_cuotas IS NOT NULL
ORDER BY id_movimiento DESC
LIMIT 5;

SELECT estado_pago AS estado_factura_cuotas
FROM Factura
WHERE id_factura = @factura_cuotas
  AND @factura_cuotas IS NOT NULL;

SELECT id_cuota, estado_pago
FROM Cuota
WHERE id_factura = @factura_cuotas
  AND @factura_cuotas IS NOT NULL;

SET @monto_matricula := (SELECT monto_total FROM Factura WHERE id_factura = @factura_matricula);
CALL SP_TX_RegistrarPagoCompleto(1, @factura_matricula, @monto_matricula);

SET @monto_inscripcion := (SELECT monto_total FROM Factura WHERE id_factura = @factura_inscripcion);
CALL SP_TX_RegistrarPagoCompleto(1, @factura_inscripcion, @monto_inscripcion);

SELECT id_factura, estado_pago FROM Factura WHERE id_estudiante = 1;
SELECT COALESCE(SUM(debe - haber),0) AS saldo_actual
FROM CuentaCorriente WHERE id_estudiante = 1;

-- =============================================
-- Paso 7: Dar de baja al estudiante y luego reactivarlo
-- =============================================
CALL SP_TX_BajaEstudianteSaldoCero(1);
SELECT id_estudiante, estado_baja FROM Estudiantes WHERE id_estudiante = 1;
CALL SP_TX_ReinscribirEstudiante(1);
SELECT id_estudiante, estado_baja FROM Estudiantes WHERE id_estudiante = 1;

-- =============================================
-- Paso 8: Registrar una nota de examen (se delega en SP_CargarNota y triggers recalculan)
-- =============================================
CALL SP_TX_RegistrarNotaYActualizar(1, 1, 'Evaluacion1', 8.50);
CALL SP_TX_RegistrarNotaYActualizar(1, 1, 'Evaluacion2', 7.25);
CALL SP_TX_RegistrarNotaYActualizar(1, 1, 'Evaluacion3', 9.10);
CALL SP_TX_RegistrarNotaYActualizar(1, 1, 'Recuperatorio', 8.80);
SELECT id_estudiante, id_curso, nota_evaluacion_1, nota_evaluacion_2,
       nota_evaluacion_3, nota_recuperatorio, nota_final
FROM Inscripciones
WHERE id_estudiante = 1 AND id_curso = 1;

-- =============================================
-- Paso 9: Ejemplos de funciones escalares y dinamicas
-- =============================================
SELECT FN_SaldoCuentaCorriente(1) AS saldo_actual;
SELECT FN_VacantesDisponibles(1) AS vacantes_curso_1;
SELECT FN_PromedioFinalCurso(1, 1) AS promedio_final_curso_1;
SELECT FN_ListarCursosPorEstudiante(1, NULL, NULL) AS cursos_json;
SELECT FN_CuotasImpagasPorEstudiante(1, 2024) AS cuotas_impagas_json;

-- =============================================
-- Fin del escenario de pruebas
-- =============================================
