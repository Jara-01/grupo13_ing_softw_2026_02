# US01 · Registro de donantes (Sprint 1)

**Historia:** Como personal del centro de donaciones, quiero registrar a los donantes para llevar un registro consistente de la elegibilidad de cada individuo.

**Trazabilidad:** RF-08, RF-09, RF-05 (base), NRF-02 · UC-01 Registrar donante.

**Responsable de T01–T03:** Bastián Pérez · **Pruebas (T04):** Antonia Paris

## Criterios de aceptación

| ID | Dado | Cuando | Entonces |
|---|---|---|---|
| E1 | un RUT válido no registrado y datos completos | se registra el donante | queda guardado y se puede consultar por RUT |
| E2 | un RUT ya registrado (aunque se escriba con o sin puntos) | se intenta registrar de nuevo | se rechaza y no se duplica |
| E3 | un RUT con dígito verificador inválido | se intenta registrar | se rechaza por formato |
| E4 | un donante diferido con fecha futura | se consulta su elegibilidad | no está apto y se informa desde qué fecha podrá donar |
| E5 | un donante rechazado permanentemente | se consulta su elegibilidad | no está apto |
| E6 | un donante apto con una donación más reciente que el intervalo mínimo | se consulta su elegibilidad | no está apto todavía y se informa la fecha |

## Tareas y verificación

| Tarea | Qué entrega | Horas | Depende de | Verificación |
|---|---|---:|---|---|
| T01 · Modelo de datos y esquema del donante | `lib/models/donante.dart`, tabla `donante` en `lib/services/database_helper.dart` (base única, esquema v2) | 2 | — | `test/t01_esquema_donante_test.dart`: guarda y lee un donante; la base rechaza RUT duplicado, tipo de sangre inválido y diferido sin fecha; la base única tiene las tres tablas y migra desde la versión 1 |
| T02 · Registrar y consultar donantes | `lib/utils/rut.dart`, `lib/services/donantes_service.dart` | 3 | T01 | `test/t02_registro_donantes_test.dart`: E1, E2, E3 y campos obligatorios |
| T03 · Determinar si el donante está apto vigente | `lib/services/elegibilidad.dart`, `registrarElegibilidad` y `consultarElegibilidad` | 3 | T01, T02 | `test/t03_elegibilidad_test.dart`: E4, E5, E6 y casos límite |

## Cómo ejecutar las pruebas

```bash
flutter pub get
flutter test test/t01_esquema_donante_test.dart test/t02_registro_donantes_test.dart test/t03_elegibilidad_test.dart
```

## Registro de ejecución de pruebas

Completar después de cada ejecución (sirve como evidencia para la Sprint Review).

| Fecha | Archivo | Pruebas OK / total | Fallas y causa | Acción |
|---|---|---|---|---|
| 2026-11-11 | t01_esquema_donante_test.dart | 6 / 6 | Ninguna | — |
| 2026-11-12 | t02_registro_donantes_test.dart (junto con T01) | 10 / 10 | Ninguna | — |
| 2026-11-12 | t03_elegibilidad_test.dart (junto con T01 y T02) | 15 / 15 | Ninguna | — |
| 2026-11-12 | Suite completa de US01 | 31 / 31 | Ninguna | — |
| 2026-11-13 | Suite completa de US01, integrada con la base única de `main` | 33 / 33 | Ninguna; 3 avisos informativos de analyze en archivos de main | — |

En todas las ejecuciones `flutter analyze` terminó sin problemas. Las pruebas se ejecutaron en Linux; falta repetirlas en Windows 10/11 (NRF-03).

### Análisis de resultados

- Todos los criterios de aceptación E1–E6 quedaron cubiertos por al menos una prueba automática, incluidos los casos límite (el día exacto de habilitación y la hora del día).
- Aprendizaje de proceso: en T01 se mezclaron por error archivos de otras tareas en un mismo commit. Se rehízo la rama y desde entonces cada commit agrega los archivos por nombre y se revisa con `git status` antes de confirmar.
- Las ramas de T02 y T03 se construyeron sobre la tarea anterior porque T01 aún no estaba fusionado en `main`; se deben fusionar en orden T01 → T02 → T03 con merge commit.
- Integración (13-11): `main` ya tenía su propio `DatabaseHelper` que abría el mismo archivo `banco_sangre.db`. Con dos helpers en versión 1, el que abría primero creaba sus tablas y el otro quedaba sin las suyas. Se unificó en un solo helper (v2) con migración, y T01 suma 2 pruebas (33 en total).
- Pendiente: la regla de elegibilidad recibe la fecha de la última donación como parámetro; cuando exista la tabla de donaciones (T05) se leerá desde la base de datos.

## Decisiones y ajustes del sprint

| Fecha | Decisión | Motivo |
|---|---|---|
| 2026-11-11 | Base de datos SQLite local (`sqflite_common_ffi`) en vez de un servidor | Simplicidad para el prototipo de escritorio (NRF-03). Los "endpoints" de la planificación son métodos de servicios Dart. |
| 2026-11-11 | T03 se renombra de "regla de elegibilidad según el historial" a "determinar si el donante está apto vigente" | Coherencia con la Entrega 1: la evaluación la decide el personal (RF-09) y el sistema la registra; el intervalo desde la última donación se suma como condición. |
| 2026-11-13 | Una sola base de datos: la tabla `donante` se agrega al `DatabaseHelper` de `main` (versión 2, con migración) y se elimina `lib/data/database_helper.dart` | Evitar dos helpers sobre el mismo archivo; cada integrante conserva sus datos locales al actualizar. |
| 2026-11-11 | Intervalo mínimo entre donaciones = 90 días, **provisional** | Lo debe confirmar el Product Owner. Está en `ReglasElegibilidad.diasMinimosEntreDonaciones`. |
| 2026-11-11 | Columna `version` en la tabla `donante` | Deja lista la base para la concurrencia optimista de US05 (T16–T18). |
| 2026-11-11 | Estado adicional `sinEvaluar` | Un donante recién registrado aún no tiene evaluación (UC-01, entre los pasos 5 y 6) y no debe considerarse apto. |

## Notas para el resto del equipo

- **Cambios de esquema (todos):** para agregar o modificar una tabla, subir `DatabaseHelper.versionEsquema` (hoy 2) en `lib/services/database_helper.dart`, crearla en `_createDB` (bases nuevas) y en `_upgradeDB` (bases existentes). No crear otro helper.
- **Donaciones (US02):** la tabla `donaciones` de `main` aún no tiene el RUT del donante, por lo que no se puede impedir la donación de un donante no apto (RF-05) ni saber su última donación. Propuesta: agregar `rut_donante TEXT REFERENCES donante(rut)` en la versión 3. Después, `consultarElegibilidad` puede leer la última donación desde ahí en vez de recibirla como parámetro.
- **T04 (Antonia):** las pruebas de T01–T03 cubren los criterios de aceptación. T04 puede ampliarlas (más casos de RUT, datos límite) y llevar el registro de ejecución de arriba.
- **US05:** con SQLite local, la concurrencia ocurre entre ventanas o procesos que abren el mismo archivo. Usar transacciones (`db.transaction`) y comparar la columna `version` al actualizar.
