# Sistema de Gestión Académica

**Actividad 2 - Base de Datos**

## 📁 Estructura del Proyecto

```
01_modificaciones.sql           → Estructura de BD (ALTER TABLE + CREATE TABLE)
02_procedimientos_carga.sql     → SPs de carga básica (1.1 - 6 procedimientos)
03_procedimientos_gestion.sql   → SPs de gestión académica (1.2 al 1.9 - 8 procedimientos)
04_datos_prueba.sql            → Datos de prueba iniciales
05_funciones_escalares.sql     → 7 funciones escalares (pendiente)
06_funciones_tabla.sql         → 10 funciones de tabla (pendiente)
07_cursores_listados.sql       → 10 listados con cursores (pendiente)
08_sql_dinamico.sql            → 10 consultas SQL dinámico (pendiente)
09_triggers.sql                → 10 triggers (pendiente)
10_transacciones.sql           → 10 transacciones (pendiente)
README.md                      → Este archivo
creacion.SQL                   → Script base de Actividad 1
requisitos.txt                 → Requisitos extraídos del PDF
```

## 🚀 Orden de Ejecución

1. **creacion.SQL** - Crear la base de datos inicial (de Actividad 1)
2. **01_modificaciones.sql** - Aplicar modificaciones y crear nuevas tablas
3. **02_procedimientos_carga.sql** - Crear procedimientos de carga básica
4. **03_procedimientos_gestion.sql** - Crear procedimientos de gestión académica
5. **04_datos_prueba.sql** - Cargar datos de prueba
6. **05_funciones_escalares.sql** - Crear funciones escalares (próximo)
7. **06_funciones_tabla.sql** - Crear funciones de tabla (próximo)
8. **07_cursores_listados.sql** - Crear listados con cursores (próximo)
9. **08_sql_dinamico.sql** - Crear consultas SQL dinámico (próximo)
10. **09_triggers.sql** - Crear triggers (próximo)
11. **10_transacciones.sql** - Crear transacciones (próximo)

## 📋 Procedimientos Almacenados Implementados

### Archivo: 02_procedimientos_carga.sql

**Carga de Datos Básicos (1.1)** - 6 procedimientos

1. **SP_CargarEstudiante** - Registrar nuevos estudiantes
2. **SP_CargarProfesor** - Registrar nuevos profesores
3. **SP_CargarMateria** - Registrar nuevas materias con costo mensual
4. **SP_CargarCurso** - Crear cursos con profesor y cuatrimestre
5. **SP_CargarCuatrimestre** - Definir cuatrimestres del año
6. **SP_CargarInteresMora** - Configurar tasas de interés (actualiza si existe)

### Archivo: 03_procedimientos_gestion.sql

**Gestión Académica (1.2 al 1.9)** - 8 procedimientos 7. **SP_BajaAlumno** (1.2) - Dar de baja alumno (valida saldo en $0) 8. **SP_AltaAlumno** (1.3) - Reactivar alumno dado de baja 9. **SP_MatricularAlumno** (1.4) - Matricular alumno (genera factura + cuenta corriente) 10. **SP_InscribirAlumno** (1.5) - Inscribir a curso (valida cupo y duplicados) 11. **SP_CargarNota** (1.6) - Cargar notas (3 evaluaciones + recuperatorio con validaciones) 12. **SP_GenerarCuotaIndividual** (1.7) - Generar cuota mensual de un alumno 13. **SP_CalcularInteresesMora** (1.8) - Calcular intereses para deudores 14. **SP_RegistrarPago** (1.9) - Registrar pago de alumno

## 🎯 Estado del Proyecto

### ✅ Completado

- ✅ **01_modificaciones.sql** - Estructura de BD completa

  - 3 tablas modificadas (ALTER TABLE)
  - 7 tablas nuevas creadas
  - Constraints, Foreign Keys e índices

- ✅ **02_procedimientos_carga.sql** - 6 SPs de carga básica (1.1)
- ✅ **03_procedimientos_gestion.sql** - 8 SPs de gestión (1.2 al 1.9)
- ✅ **04_datos_prueba.sql** - Datos iniciales

### 🚧 Pendiente

- ⏳ Funciones escalares (7)
- ⏳ Funciones de tabla (10)
- ⏳ Cursores con listados (10)
- ⏳ SQL dinámico (10)
- ⏳ Triggers (10)
- ⏳ Transacciones (10)
- ⏳ Documentación final

## 📊 Modelo de Datos

### Tablas Principales

#### Estudiantes

- `id_estudiante` (PK, AUTO_INCREMENT)
- `dni`, `nombre`, `apellido`
- `fecha_nacimiento`, `email`, `telefono`
- `anio_ingreso` (año de ingreso a la institución)
- `estado_baja` (0=activo, 1=baja)

#### Profesores

- `id_profesor` (PK, AUTO_INCREMENT)
- `dni`, `nombre`, `apellido`
- `especialidad`, `email`, `telefono`

#### Materias

- `id_materia` (PK, AUTO_INCREMENT)
- `nombre`, `descripcion`
- `costo_curso_mensual` (costo mensual del curso)

#### Cursos

- `id_curso` (PK, AUTO_INCREMENT)
- `id_materia` (FK), `id_profesor` (FK)
- `cupo_maximo`, `horario`

#### Inscripciones

- `id_inscripcion` (PK, AUTO_INCREMENT)
- `id_estudiante` (FK), `id_curso` (FK)
- `fecha_inscripcion`
- `nota_evaluacion_1`, `nota_evaluacion_2`, `nota_evaluacion_3`
- `nota_recuperatorio`, `nota_final`
- `id_cuatrimestre` (FK)

#### Cuatrimestre

- `id_cuatrimestre` (PK, AUTO_INCREMENT)
- `anio`, `numero_cuatrimestre` (1, 2 o 3)
- `fecha_inicio`, `fecha_fin`

#### Factura

- `id_factura` (PK, AUTO_INCREMENT)
- `id_estudiante` (FK)
- `fecha_emision`, `monto_total`
- `estado_pago` (Pendiente, Pagado, Vencido)

#### Matriculacion

- `id_matriculacion` (PK, AUTO_INCREMENT)
- `id_estudiante` (FK), `anio`
- `monto_matricula`, `fecha_matriculacion`
- `id_factura` (FK)

#### Cuota

- `id_cuota` (PK, AUTO_INCREMENT)
- `id_estudiante` (FK), `id_curso` (FK)
- `mes`, `anio`, `monto_cuota`
- `fecha_vencimiento`
- `estado_pago` (Pendiente, Pagado, Vencido)
- `id_factura` (FK)

#### CuentaCorriente

- `id_movimiento` (PK, AUTO_INCREMENT)
- `id_estudiante` (FK)
- `fecha_movimiento`, `concepto`
- `debe`, `haber`, `saldo`
- `id_factura` (FK)

#### InteresMora

- `id_interes_mora` (PK, AUTO_INCREMENT)
- `anio` (UNIQUE)
- `tasa_mensual`, `fecha_vigencia`

#### ItemFactura

- `id_item_factura` (PK, AUTO_INCREMENT)
- `id_factura` (FK)
- `concepto`, `monto`

## 💻 Tecnología

- **Base de Datos**: MySQL / PostgreSQL (SQL Estándar)
- **Compatibilidad**: MySQL Workbench, pgAdmin, DBeaver
- **Sintaxis**: SQL puro sin dependencias de T-SQL

## 📝 Ejemplos de Uso

### Cargar un estudiante

```sql
CALL SP_CargarEstudiante('30111111', 'Pedro', 'Gómez', '2000-05-15',
                         'pedro.gomez@mail.com', '1155667788', 2024);
```

### Matricular un alumno

```sql
CALL SP_MatricularAlumno(1, 2024, 5000.00);
```

### Inscribir a un curso

```sql
CALL SP_InscribirAlumno(1, 1);
```

### Cargar una nota

```sql
CALL SP_CargarNota(1, 1, 'Evaluacion1', 8.50);
```

### Registrar un pago

```sql
CALL SP_RegistrarPago(1, 5000.00, 1);
```

## 👥 Autor

Theo Fernández

## 📅 Fecha

Octubre 2025
