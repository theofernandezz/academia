-- =============================================
-- demo_guion.sql
-- Secuencia sugerida para demostrar el proyecto en vivo.
-- Ejecutar estos bloques en orden, con la base ya inicializada:
--   1) creacion.SQL
--   2) 02_procedimientos_carga.sql ... 10_transacciones.sql
--   3) 04_datos_prueba.sql
-- =============================================

USE gestion_academica;

-- =============================================
-- 1. Matricular estudiante 1 (muestra matriculacion + factura + movimiento)
-- =============================================
CALL SP_TX_MatricularYGenerarFactura(1, 2024, 5000);
SELECT * FROM Matriculacion WHERE id_estudiante = 1 ORDER BY id_matriculacion DESC LIMIT 1;
SELECT * FROM Factura WHERE id_estudiante = 1 ORDER BY id_factura DESC LIMIT 1;
SELECT * FROM CuentaCorriente WHERE id_estudiante = 1 ORDER BY id_movimiento DESC LIMIT 1;

-- =============================================
-- 2. Matricular estudiante 2 (mismo proceso con otro alumno)
-- =============================================
CALL SP_TX_MatricularYGenerarFactura(2, 2024, 4500);
SELECT * FROM Matriculacion WHERE id_estudiante = 2 ORDER BY id_matriculacion DESC LIMIT 1;
SELECT * FROM Factura WHERE id_estudiante = 2 ORDER BY id_factura DESC LIMIT 1;
SELECT * FROM CuentaCorriente WHERE id_estudiante = 2 ORDER BY id_movimiento DESC LIMIT 1;

-- =============================================
-- 3. Inscribir estudiante 1 a un curso (solo valida vacantes, sin factura)
-- =============================================
CALL SP_TX_InscribirConVacantes(1, 1, 1);
SELECT * FROM Inscripciones WHERE id_estudiante = 1 AND id_curso = 1;

-- =============================================
-- 4. Inscribir estudiante 2 y generar factura del curso
-- =============================================
CALL SP_TX_InscribirYGenerarItemFactura(2, 3, 1);
SELECT * FROM Factura WHERE id_estudiante = 2 ORDER BY id_factura DESC LIMIT 1;
SELECT * FROM CuentaCorriente WHERE id_estudiante = 2 ORDER BY id_movimiento DESC LIMIT 1;

-- =============================================
-- 5. Generar cuotas del cuatrimestre actual (aplica a ambos si tienen inscripciones)
-- =============================================
CALL SP_TX_GenerarCuotasMasivas(3, 2024);
SELECT * FROM Cuota WHERE id_estudiante = 1 AND anio = 2024 AND mes = 3;
SELECT * FROM Cuota WHERE id_estudiante = 2 AND anio = 2024 AND mes = 3;

-- =============================================
-- 6. Forzar mora y calcular intereses para el estudiante 1
-- =============================================
UPDATE Cuota
SET estado_pago = 'Vencido', fecha_vencimiento = DATE_SUB(CURRENT_DATE, INTERVAL 15 DAY)
WHERE id_estudiante = 1 AND anio = 2024 AND mes = 3
LIMIT 1;
CALL SP_TX_GenerarInteresesMora(2024);
SELECT id_factura, monto_total, estado_pago
FROM Factura
WHERE id_estudiante = 1
ORDER BY id_factura DESC;

-- =============================================
-- 7. Emitir factura de cuotas impagas de 1 (solo si el SELECT siguiente devuelve filas)
-- =============================================
SELECT id_cuota, estado_pago
FROM Cuota
WHERE id_estudiante = 1
  AND anio = 2024
  AND mes = 3
  AND estado_pago = 'Pendiente';

-- Si hay cuotas pendientes, ejecutar manualmente:
-- CALL SP_TX_EmitirFacturaCuotasImpagas(1, 3, 2024);
-- SELECT * FROM Factura WHERE id_estudiante = 1 ORDER BY id_factura DESC LIMIT 1;

-- =============================================
-- 8. Registrar pagos pendientes de ambos estudiantes
-- =============================================
SET @factura_ultima := (SELECT id_factura FROM Factura WHERE id_estudiante = 1 ORDER BY id_factura DESC LIMIT 1);
SET @monto_ultima := (SELECT monto_total FROM Factura WHERE id_factura = @factura_ultima);
CALL SP_TX_RegistrarPagoCompleto(1, @factura_ultima, @monto_ultima);

SET @factura_matricula := (SELECT id_factura FROM Factura WHERE id_estudiante = 1 ORDER BY id_factura ASC LIMIT 1);
CALL SP_TX_RegistrarPagoCompleto(1, @factura_matricula, (SELECT monto_total FROM Factura WHERE id_factura = @factura_matricula));

SET @factura_inscripcion := (
    SELECT id_factura
    FROM Factura
    WHERE id_estudiante = 1
      AND id_factura <> @factura_matricula
    ORDER BY id_factura ASC LIMIT 1
);
CALL SP_TX_RegistrarPagoCompleto(1, @factura_inscripcion, (SELECT monto_total FROM Factura WHERE id_factura = @factura_inscripcion));

SET @factura_matricula_2 := (SELECT id_factura FROM Factura WHERE id_estudiante = 2 ORDER BY id_factura ASC LIMIT 1);
CALL SP_TX_RegistrarPagoCompleto(2, @factura_matricula_2, (SELECT monto_total FROM Factura WHERE id_factura = @factura_matricula_2));

SET @factura_inscripcion_2 := (
    SELECT id_factura
    FROM Factura
    WHERE id_estudiante = 2
      AND id_factura <> @factura_matricula_2
    ORDER BY id_factura ASC LIMIT 1
);
CALL SP_TX_RegistrarPagoCompleto(2, @factura_inscripcion_2, (SELECT monto_total FROM Factura WHERE id_factura = @factura_inscripcion_2));

SELECT id_factura, estado_pago FROM Factura WHERE id_estudiante IN (1,2);
SELECT id_estudiante, COALESCE(SUM(debe - haber), 0) AS saldo_actual
FROM CuentaCorriente
GROUP BY id_estudiante;

-- =============================================
-- 9. Baja y reactivacion (muestra validacion de saldo) para estudiante 1
-- =============================================
CALL SP_TX_BajaEstudianteSaldoCero(1);
SELECT id_estudiante, estado_baja FROM Estudiantes WHERE id_estudiante = 1;
CALL SP_TX_ReinscribirEstudiante(1);
SELECT id_estudiante, estado_baja FROM Estudiantes WHERE id_estudiante = 1;

-- =============================================
-- 10. Carga de notas (sin recuperatorio) sobre estudiante 2
-- =============================================
CALL SP_TX_RegistrarNotaYActualizar(2, 3, 'Evaluacion1', 7.50);
CALL SP_TX_RegistrarNotaYActualizar(2, 3, 'Evaluacion2', 8.00);
CALL SP_TX_RegistrarNotaYActualizar(2, 3, 'Evaluacion3', 9.00);
SELECT nota_evaluacion_1, nota_evaluacion_2, nota_evaluacion_3, nota_final
FROM Inscripciones
WHERE id_estudiante = 2 AND id_curso = 3;

-- Para demostrar recuperatorio (cuando hay evaluacion < 4):
-- CALL SP_TX_RegistrarNotaYActualizar(1, 1, 'Evaluacion1', 3.00);
-- CALL SP_TX_RegistrarNotaYActualizar(1, 1, 'Recuperatorio', 8.50);

-- =============================================
-- 11. Funciones utilitarias (escalares y JSON) para ambos alumnos
-- =============================================
SELECT FN_SaldoCuentaCorriente(1) AS saldo_estudiante_1;
SELECT FN_SaldoCuentaCorriente(2) AS saldo_estudiante_2;
SELECT FN_VacantesDisponibles(1) AS vacantes_curso_1;
SELECT FN_VacantesDisponibles(3) AS vacantes_curso_3;
SELECT FN_NombreCompletoEstudiante(1) AS nombre_completo_1;
SELECT FN_NombreCompletoEstudiante(2) AS nombre_completo_2;
SELECT FN_ListarCursosPorEstudiante(1, NULL, NULL) AS cursos_json_est1;
SELECT FN_ListarCursosPorEstudiante(2, NULL, NULL) AS cursos_json_est2;
SELECT FN_CuotasImpagasPorEstudiante(1, 2024) AS cuotas_json_est1;
SELECT FN_CuotasImpagasPorEstudiante(2, 2024) AS cuotas_json_est2;

-- Fin del guion de demostracion
