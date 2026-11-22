# 10 · Estructura del proyecto en barril y contrato de la API

Cubre: RNF-01 a RNF-07, RNF-13, RNF-14 y todos los RF (ver §5). Stack: HTML, CSS y JavaScript en el navegador; Java 17 con Spring Boot; MySQL 8 (`database/`).

## 1. Qué significa «barril» aquí

Un **barril** es un único punto de entrada por carpeta que re-exporta lo público de ese módulo, de modo que el resto del código importa de la carpeta y no de archivos sueltos.

| Capa | Cómo se aplica |
|---|---|
| Front-end (JS) | Cada carpeta tiene un `index.js` que re-exporta lo público. Se importa `from '../api/index.js'`, nunca un archivo interno. |
| Back-end (Java) | Java no tiene archivos barril; el equivalente es el paquete **`api`** de cada módulo: es lo único que otros módulos pueden usar. El resto (`dominio`, `servicio`, `repositorio`, `web`) es interno. Una prueba de arquitectura lo verifica (§4). |

Suposición a confirmar con el cliente (pregunta 1 del análisis): si «barril» significaba monorepo, esta estructura también lo cumple, porque front, back, base de datos y documentos viven en el mismo repositorio.

## 2. Árbol de carpetas

```text
FinanSmart/
├─ README.md  CONTRIBUTING.md  .gitignore
├─ docs/                          Análisis y diseño (Markdown + Mermaid) y anexos de verificación
├─ database/
│  ├─ 01_schema.sql               Esquema (21 tablas, disparadores, vista)
│  ├─ 02_catalogos.sql            rol, plan, «Sin categoría» (no son datos de ejemplo)
│  ├─ 03_permisos.sql             Usuario de la app con privilegios mínimos (sin contraseña)
│  └─ pruebas/                    Pruebas de integridad y de permisos contra MySQL
├─ backend/
│  ├─ pom.xml                     (se crea al iniciar el proyecto Spring Boot)
│  └─ src/
│     ├─ main/java/com/finansmart/
│     │  ├─ FinanSmartApplication.java
│     │  ├─ compartido/           Dinero (BigDecimal), tiempo (America/Bogota), errores, configuración
│     │  ├─ seguridad/            Rol, Permiso, filtros de sesión, política de contraseña, CSRF
│     │  ├─ acceso/               Autenticación, códigos SMS, sesiones, intentos
│     │  ├─ cuenta/               Usuario, consentimientos, cambio de correo/teléfono, eliminación
│     │  ├─ categorias/
│     │  ├─ movimientos/
│     │  ├─ presupuestos/         Incluye ServicioAlertas
│     │  ├─ metas/
│     │  ├─ banca/                Cuentas, sincronización, movimientos propuestos, proveedor bancario
│     │  ├─ notificaciones/
│     │  ├─ reportes/             Resumen, reportes y exportación
│     │  ├─ educacion/
│     │  ├─ suscripcion/
│     │  ├─ administracion/       Usuarios (solo datos de cuenta), contenido, métricas, cuentas ADMIN
│     │  ├─ auditoria/
│     │  └─ calculo/              CalculadoraFinanciera (F1 a F13); única clase que decide estados y alertas
│     │     └─ cada módulo:  api/  dominio/  servicio/  repositorio/  web/
│     ├─ main/resources/          application.yml (sin secretos; valores por variables de entorno)
│     └─ test/java/com/finansmart/  Pruebas por módulo + ArquitecturaTest + AutorizacionPorRolTest
├─ frontend/
│  ├─ index.html                  Landing (PW-L01)
│  ├─ css/                        tokens.css (paleta oficial), base.css, componentes.css
│  ├─ js/
│  │  ├─ index.js                 Barril raíz
│  │  ├─ api/                     Cliente HTTP (fetch), un archivo por recurso + index.js
│  │  ├─ utilidades/              formato (COP, fechas), dinero, validaciones + index.js
│  │  ├─ componentes/             Tarjeta, barra de progreso, estado vacío, alerta + index.js
│  │  └─ paginas/                 Una carpeta por pantalla (PW-xx) con su index.js
│  ├─ admin/                      Pantallas de ADMIN (PW-A01..A04)
│  └─ superadmin/                 Pantallas de SUPERADMIN, servidas solo con sesión SUPERADMIN
│     └─ genesis/                 Génesis del proyecto (PW-S02), doc 12
└─ scripts/                       Sincroniza y valida la trazabilidad (doc 12)
```

## 3. Convenciones

| Tema | Regla |
|---|---|
| Idioma | Código, clases y rutas en español sin tildes (`movimientos`, `Presupuesto`); mensajes al usuario en español de Colombia con tildes |
| Nombres | Clases `PascalCase`; atributos y métodos `camelCase`; tablas y columnas `snake_case` (INC-01); constantes `MAYUSCULAS` |
| Dinero | `BigDecimal` en Java; en el navegador solo se **muestra** (nunca se calcula con `Number` para decidir). En JSON viaja como cadena: `"monto": "28000.00"` |
| Tiempo | UTC en BD y API (ISO-8601); el cálculo de mes y día en `America/Bogota` (doc 04, F8) |
| Ramas | `main` protegida; trabajo en `feature/RF-xx-descripcion`, `fix/…`, `docs/…`; todo entra por Pull Request |
| Commits | `tipo: resumen (Refs: RF-xx)`; tipos `feat`, `fix`, `docs`, `test`, `refactor`, `chore` |
| Secretos | Ninguno en el repositorio: variables de entorno y un gestor de secretos; el escaneo de secretos corre en CI (RNF-14) |
| Sesión | Cookie `HttpOnly; Secure; SameSite=Strict` + cabecera `X-CSRF-Token`; **nunca** `localStorage` para tokens |
| Errores | `application/problem+json` (RFC 7807) con `type`, `title`, `status`, `detail` y `codigo` estable |
| Paginación | `?pagina=0&tamano=20` (máx. 100); respuesta con `total` |

## 4. Reglas de arquitectura (se prueban, no solo se escriben)

1. Un módulo solo importa el paquete `api` de otro (`ArquitecturaTest`).
2. Solo `calculo` toma decisiones sobre estados, umbrales y alertas.
3. Ningún controlador de `administracion` ni `superadministracion` depende de `movimientos`, `presupuestos`, `metas`, `banca` ni `reportes` (garantiza RN-12).
4. Todo endpoint declara su rol; una prueba recorre todos los endpoints y falla si alguno no tiene regla (RNF-03).
5. No existe un endpoint para: desactivar el 2FA, sincronizar manualmente, aprobar movimientos en lote, ni ver datos financieros ajenos.

## 5. Contrato de la API REST (`/api/v1`)

Roles: **P** público, **U** USUARIO, **A** ADMIN o SUPERADMIN, **S** solo SUPERADMIN. Todo lo que no es **P** exige sesión completa (con SMS válido). Una cuenta `PENDIENTE_VERIFICACION` solo alcanza `POST /auth/telefono`, `POST /auth/verificar-sms` y `POST /auth/reenviar-sms` (RF-07).

### Acceso (CU-01 a CU-06)
| Método y ruta | Rol | Descripción | RF |
|---|:-:|---|---|
| `POST /auth/registro` | P | Crea la cuenta; exige edad ≥ 18 y consentimientos | RF-01, 02 |
| `POST /auth/verificar-correo` | P | Confirma el enlace de un solo uso | RF-03 |
| `POST /auth/login` | P | Credenciales → reto SMS (nunca sesión directa) | RF-04, 06 |
| `POST /auth/google` | P | Identidad de Google → reto SMS | RF-05 |
| `POST /auth/telefono` | P* | Registra y verifica teléfono (cuenta pendiente) | RF-07 |
| `POST /auth/verificar-sms` | P* | Valida el código y crea la sesión | RF-06, 08 |
| `POST /auth/reenviar-sms` | P* | Reenvío con temporizador y tope | RF-06 |
| `POST /auth/logout` | U/A | Cierra la sesión actual | — |
| `POST /auth/recuperar-contrasena` | P | Respuesta idéntica exista o no la cuenta | RF-10 |
| `POST /auth/restablecer-contrasena` | P | Con enlace de un solo uso; cierra sesiones | RF-10 |
| `POST /auth/recuperar-acceso` | P | Inicia recuperación por pérdida del teléfono | RF-11 |
| `POST /auth/recuperar-acceso/confirmar` | P | Confirma tras la espera de seguridad | RF-11 |

\* Público pero atado a un reto SMS vigente, no a una sesión.

### Cuenta (CU-07)
| Método y ruta | Rol | Descripción | RF |
|---|:-:|---|---|
| `GET /cuenta` | U/A | Datos de la persona | — |
| `PATCH /cuenta` | U | Nombre y `metaAhorroPct`. Rechaza `fechaNacimiento` con 403 | RF-14, 24 |
| `POST /cuenta/telefono` y `/confirmar` | U/A | Contraseña + código al número nuevo + aviso al anterior | RF-12 |
| `POST /cuenta/correo` y `/confirmar` | U/A | Igual que el teléfono | RF-13 |
| `POST /cuenta/google/vincular` | U/A | Exige contraseña y SMS | RF-09 |
| `DELETE /cuenta` | U | Eliminación con confirmación | RF-34 |
| `GET /cuenta/sesiones` · `DELETE /cuenta/sesiones/{id}` | U | Dispositivos activos (propuesta RF-36, doc 11 §6) | — |

### Núcleo financiero (CU-08 a CU-12, CU-15, CU-16)
| Método y ruta | Rol | Descripción | RF |
|---|:-:|---|---|
| `GET·POST /categorias` · `PATCH /categorias/{id}` | U | Listar, crear, editar | RF-15, 16 |
| `DELETE /categorias/{id}?reasignarA={id}` | U | Elimina; exige destino si hay movimientos | RF-16 |
| `GET /movimientos?mes&tipo&categoriaId&q` | U | Lista filtrada y paginada | RF-17 |
| `POST /movimientos` | U | Crea; devuelve aviso `posibleDuplicado` | RF-17, 18 |
| `GET·PATCH·DELETE /movimientos/{id}` | U | Detalle, edición, eliminación (con impacto en %) | RF-17 |
| `GET /presupuestos?mes` | U | Límites, gastado, % y estado (F1, F2, F13) | RF-19 |
| `PUT /presupuestos/{categoriaId}/{mes}` | U | Crea o actualiza límite, umbrales, recurrencia | RF-19, 20 |
| `DELETE /presupuestos/{categoriaId}/{mes}` | U | Elimina el presupuesto | RF-19 |
| `GET·POST /metas` · `GET·PATCH·DELETE /metas/{id}` | U | CRUD de metas con progreso y aporte sugerido (F5 a F7) | RF-22 |
| `POST /metas/{id}/abonos` · `DELETE …/{abonoId}` | U | Abonos | RF-23 |
| `GET /resumen?mes` | U | Balance, ingresos, gastos, tasa (F3, F4) | RF-25 |
| `GET /reportes?desde&hasta` | U | Reporte calculado | RF-26 |
| `POST /exportaciones` · `GET /exportaciones/{id}/archivo` | U | PDF o Excel; 422 si supera el tope (F10) | RF-27 |

### Banca (CU-13, CU-14) · plan Pro
| Método y ruta | Rol | Descripción | RF |
|---|:-:|---|---|
| `GET /cuentas-bancarias` | U | Cuentas, última sincronización y próxima disponible (sin saldos, INC-19) | RF-28, 29 |
| `POST /cuentas-bancarias` | U | Inicia la autorización de solo lectura | RF-28 |
| `DELETE /cuentas-bancarias/{id}` | U | Revoca el permiso | RF-34 |
| `GET /movimientos-propuestos?estado` | U | Bandeja de revisión | RF-30 |
| `POST /movimientos-propuestos/{id}/aprobar` | U | Aprueba **uno** con su categoría | RF-30 |
| `POST /movimientos-propuestos/{id}/rechazar` | U | Rechaza; no vuelve a proponerse | RF-31 |

No existe `POST /sincronizaciones`: la sincronización la ejecuta solo la tarea programada (F9, RW-03).

### Notificaciones, educación y suscripción (CU-11, CU-17, CU-18)
| Método y ruta | Rol | Descripción | RF |
|---|:-:|---|---|
| `GET /notificaciones` · `PATCH /notificaciones/{id}/leida` · `POST /notificaciones/leer-todas` | U | Bandeja y estado de lectura | RF-21, 35 |
| `GET /lecciones` · `GET /lecciones/{id}` | U | Solo lecciones PUBLICADAS | RF-32 |
| `POST /lecciones/{id}/completar` | U | Guarda el avance | RF-32 |
| `GET /planes` · `GET /suscripcion` | U | Planes y estado actual | RF-33 |
| `POST /suscripcion/prueba` · `POST /suscripcion/plan` | U | Inicia la prueba o cambia de plan | RF-33 |

### Administración (CU-19 a CU-23)
| Método y ruta | Rol | Descripción | RF |
|---|:-:|---|---|
| `GET /admin/usuarios?q&estado` · `GET /admin/usuarios/{id}` | A | **Solo datos de cuenta** (nombre, correo, estado, plan, registro) | RF-A02 |
| `POST /admin/usuarios/{id}/suspender` · `/reactivar` | A | Con motivo; cierra sesiones | RF-A02, A03 |
| `GET·POST·PATCH /admin/lecciones` · `POST /admin/lecciones/{id}/estado` | A | CRUD y flujo borrador → revisión → publicada → archivada | RF-A04 |
| `GET /admin/metricas` | A | Conteos agregados anónimos | RF-A05 |
| `GET·POST /superadmin/admins` · `POST …/{id}/suspender` · `/reactivar` | S | Gestión de cuentas ADMIN | RF-A24 |
| `GET /superadmin/genesis/**` | S | Contenido de Génesis; solo lectura; cada acceso se audita | RF-A25 |
| `GET /superadmin/auditoria?desde&hasta&actor&accion` | S | Consulta; solo lectura | RF-A26 |

**Ausentes a propósito:** cualquier ruta bajo `/admin` o `/superadmin` que devuelva movimientos, saldos, presupuestos, metas o cuentas bancarias de un usuario (RN-12); cualquier ruta que modifique o borre auditoría (RNF-04).

### Códigos de estado
`200/201/204` éxito · `400` datos inválidos · `401` sin sesión o suspendida · `403` rol insuficiente o campo no editable · `404` no existe **o no es tuyo** (no se revela existencia) · `409` duplicado · `422` regla de negocio (tope de exportación, cupo de sincronización, reasignación pendiente) · `429` demasiados intentos (F11).

## 6. Trazabilidad RF → endpoint

Cada RF de la tabla anterior aparece en el mapa de trazabilidad del módulo Génesis (doc 12). `scripts/validar-trazabilidad.mjs` falla si un RF no tiene caso de uso, clase, tabla y pantalla (RNF-13).
