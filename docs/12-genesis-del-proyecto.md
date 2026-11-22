# 12 · Génesis del proyecto (PW-S02)

Cubre: RF-A25, RW-09, RNF-03, RNF-04, RNF-13, RNF-14 · caso de uso CU-22.
Es una página **solo para SUPERADMIN** que permite ver, en código visual e interactivo, cómo nació el proyecto: contexto, enfoque sistémico, requisitos, lógica matemática, casos de uso, clases, DER, normalización, base de datos, API, pantallas y la trazabilidad entre todo ello.

## 1. Qué muestra

| Sección | Fuente | Interacción |
|---|---|---|
| 1 a 3 Contexto, enfoque sistémico, requisitos | `docs/01` a `docs/03` | Índice de la sección, tablas desplazables |
| 4 Lógica matemática | `docs/04` | **Calculadora interactiva** (F1, F2, F4 a F7 y F13) con las mismas reglas del servidor |
| 5 a 8 Casos de uso, clases, DER, normalización | `docs/05` a `docs/08` | Diagramas Mermaid dibujados en pantalla |
| 9 Base de datos | `database/01_schema.sql` | Script completo de solo lectura |
| 10 y 11 API y pantallas | `docs/10`, `docs/11` | Tablas y rutas |
| 12 Trazabilidad | `scripts/lib/trazabilidad.mjs` | Búsqueda por requisito, caso de uso, clase, tabla o pantalla y **consulta inversa** (clic en una etiqueta para ver qué otros requisitos la usan) |

Nunca muestra datos de usuarios. Es documentación, no una consola de administración.

## 2. Reglas de acceso (RF-A25, RW-09)

| Regla | Cómo se cumple |
|---|---|
| Solo SUPERADMIN | El servidor decide. Ocultar el menú **no** es una barrera. Prueba negativa: USUARIO y ADMIN reciben 403; sin sesión, 401 |
| 2FA obligatorio | Como todo acceso: sin SMS válido no hay sesión (RF-06) |
| Ruta separada | Todo cuelga de `/superadmin/*` y `/api/v1/superadmin/*` |
| Solo lectura | Solo métodos `GET`; no hay formularios ni escritura |
| Sin datos de usuarios | El contenido sale de archivos del repositorio, nunca de las tablas de negocio |
| Auditoría de accesos | Cada petición de una sección registra en `auditoria` la acción `GENESIS_VER` con el id de sección, el actor y la IP |
| Sin caché | `Cache-Control: no-store` |

### Advertencia técnica: Spring Boot publica `static/` por defecto
Cualquier archivo dentro de `src/main/resources/static/` se sirve **sin autenticación**. Por eso la página **no puede** ir ahí. Debe quedar fuera (por ejemplo `src/main/resources/privado/genesis/`) y servirse desde un controlador protegido:

```java
// Esquema: el controlador solo expone rutas bajo /superadmin y exige el rol
.requestMatchers("/superadmin/**", "/api/v1/superadmin/**").hasRole("SUPERADMIN")
```

Una prueba automática debe pedir `/superadmin/genesis/`, `/superadmin/genesis/contenido/indice.json` y un archivo de `contenido/` sin sesión y con cada rol, y comprobar 401 o 403 salvo para SUPERADMIN.

## 3. Estructura del módulo

```text
frontend/superadmin/genesis/
├─ index.html            Marco, librerías con versión exacta y hash SRI
├─ genesis.css           Responsive desde 360 px; paleta oficial; un solo rol por color
├─ genesis.js            Controlador: carga, errores con «Reintentar», diagramas
├─ modulos/              Barril (index.js)
│  ├─ formulas.js        F1 a F13 con BigInt (exactas, sin coma flotante)
│  ├─ formato.js         Pesos, fechas DD/MM/AAAA, hora de Bogotá
│  ├─ markdown.js        Markdown → HTML saneado (DOMPurify), diagramas Mermaid
│  ├─ calculadora.js     Calculadora interactiva
│  ├─ trazabilidad.js    Búsqueda y consulta inversa
│  └─ navegacion.js      Rutas por hash simple (#contexto)
└─ contenido/            GENERADO (no se versiona): copia de docs, SQL y los JSON
```

`contenido/` lo genera `scripts/sincronizar-genesis.mjs` a partir de `docs/` y `database/`; así Génesis nunca se desactualiza respecto del análisis. Si la trazabilidad tiene una ruptura, **no se genera**.

## 4. Cómo ejecutarlo

```bash
npm ci                      # dependencias solo de pruebas
npm run validar             # trazabilidad requisito → CU → clase → tabla → pantalla
npm run genesis:servir      # SOLO DESARROLLO: http://127.0.0.1:8080/superadmin/genesis/ (sin autenticación)
npm run probar              # pruebas del módulo
```

El servidor local escucha solo en `127.0.0.1` y no autentica: es para ver la página mientras no exista el backend. En producción lo reemplaza el controlador protegido.

## 5. Seguridad del front-end

| Riesgo | Medida |
|---|---|
| Librería de CDN alterada | Versión exacta (`marked 12.0.2`, `DOMPurify 3.1.6`, `mermaid 10.9.1`) + hash SRI + `crossorigin="anonymous"` |
| HTML malicioso en el contenido | `DOMPurify` antes de insertar; los bloques Mermaid se pasan por `textContent`, nunca como HTML; `securityLevel: 'strict'` |
| Enlaces a rutas del repositorio | Se desactivan (no existen en la web); los externos llevan `noopener noreferrer` |
| Tokens en el navegador | Ninguno: la sesión es una cookie `HttpOnly` |
| Indexación | `noindex, nofollow` y `Referrer-Policy: no-referrer` |
| Respuestas lentas que pisan a otras | Cada carga lleva un número de secuencia; una respuesta vieja se descarta |

**Cabecera `Content-Security-Policy` recomendada** (la pone el servidor):
`default-src 'self'; script-src 'self' https://cdn.jsdelivr.net; style-src 'self' 'unsafe-inline'; img-src 'self' data:; connect-src 'self'; object-src 'none'; base-uri 'none'; frame-ancestors 'none'`.
Mermaid genera SVG con estilos en línea, por eso `style-src` los permite. **Debe probarse en un navegador real antes de activarla**, porque una política demasiado estricta rompería los diagramas sin avisar.

## 5.1 Por qué `calculadora.js` repite las fórmulas
Es una réplica **explicativa**: el servidor es quien decide estados y alertas (`CalculadoraFinanciera`). Para evitar que se desvíen, `formulas.js` se prueba con los mismos casos que `docs/anexos/verificar_calculos.py` (uso, estados, tasa, aporte, progreso, meses). Si cambia una fórmula, cambian el doc 04, el anexo en Python y `formulas.js` en el mismo Pull Request.

## 6. Accesibilidad y responsive (RNF-06, RNF-08)
- Enlace «Saltar al contenido», foco visible, `aria-live` para estados y resultados, `aria-current` en la sección activa y `aria-busy` mientras carga.
- El color nunca es el único indicador: los resultados incluyen texto («Aviso», «Límite alcanzado o superado», «Cumple tu meta de ahorro»).
- Colores con un solo rol: naranja solo para el aviso del 80 %, rojo solo para límite excedido o error, verde solo para logro y ahorro.
- Tablas y bloques de código desplazan **dentro** de su contenedor: la página no se desborda horizontalmente desde 360 px.
- Celular: índice en un menú «Secciones»; tableta: una columna ancha; escritorio: índice fijo a la izquierda y «En esta sección» a la derecha.
- Respeta `prefers-reduced-motion`.

## 7. Qué se verificó y qué no

| Verificado con pruebas automáticas | Sin verificar (requiere navegador real) |
|---|---|
| Fórmulas contra los casos del doc 04 | Dibujo visual de los diagramas Mermaid (su **sintaxis** sí se valida) |
| Saneado de HTML y conversión de bloques Mermaid | Aspecto en pantallas reales y lectores de pantalla |
| Montaje de la calculadora y de la trazabilidad (simulando el DOM) | Cabecera CSP con Mermaid |
| Índice, secciones y enlaces entre secciones | Control de acceso por rol (depende del backend, aún no construido) |
| Trazabilidad completa de los 52 requisitos | |
