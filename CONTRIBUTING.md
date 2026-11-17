# Convención de ramas y commits

## Ramas (Scrum + Kanban)
- `main`: estable, solo por Pull Request.
- `develop`: integración del sprint.
- `feature/<RF-ID>-<descripcion-corta>` (ej. `feature/RF-12-cambio-telefono`).
- `fix/<ID>-<descripcion>`, `docs/<tema>`, `release/<version>`.

## Commits (Conventional Commits, en español)
`<tipo>(<alcance>): <resumen en imperativo>` con cuerpo opcional y referencia `Refs: RF-xx`.
Tipos: `feat`, `fix`, `docs`, `refactor`, `test`, `chore`, `db`.
Ejemplo: `feat(auth): exigir SMS tras Continuar con Google (Refs: RF-05, RF-08)`

## Reglas
- Prohibido subir credenciales, tokens o claves (usar variables de entorno).
- Todo PR referencia al menos un ID de requisito y pasa revisión de otro integrante.
