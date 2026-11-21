# 08 · Normalización

Cubre: RNF-04, RNF-05, RNF-13 y todas las tablas del doc 07.
Se parte de las estructuras de los insumos (entidades de Canva y diagrama de clases del informe 1) y se llega a las 21 tablas del DER nuevo. Notación: `A → B` significa «A determina B»; **CC** = clave candidata.

## 1. Punto de partida y anomalías

| Estructura de partida | Problema | Forma normal violada | Corrección |
|---|---|---|---|
| `Presupuesto(id, periodo, montoTotal, asignaciones)` | `asignaciones` guarda varias categorías con sus límites en un solo atributo | 1FN (atributo multivalor) | Tabla `presupuesto`: una fila por categoría y mes |
| `Presupuesto.montoTotal` | Se deduce de la suma de límites | Redundancia derivada (riesgo de contradicción) | Se elimina; se calcula |
| `Categoria(id, nombre, tipo, limiteMensual)` | El límite duplica el presupuesto y no admite histórico por mes | Dependencia del mes, que no está en la clave | El límite pasa a `presupuesto(categoria_id, mes)` |
| `Transaccion(id, tipo, monto, fecha, descripcion, origen, categoria)` | `tipo` lo determina la categoría (`id → categoria → tipo`) | 3FN (dependencia transitiva) | Se elimina `tipo`; sale de `categoria.tipo` |
| `Transaccion.origen` | Se deduce de si existe un `movimiento_propuesto` asociado | Redundancia derivada | Se elimina; vista de apoyo en la fase C |
| `Alerta(id, tipo, mensaje, fecha, severidad)` | `tipo → severidad` | 3FN | Se elimina `severidad` |
| `MetaFinanciera(…, ahorroMensualPlaneado)` | Se deduce de objetivo, abonos y fecha | Redundancia derivada | Se calcula (F5) |
| `Usuario.nivelEducativo` | Dato innecesario; el avance real es calculable | Minimización de datos | Se elimina |
| `EducacionFinanciera` ligada directo a `Usuario` | Relación N:M sin tabla que guarde el avance | Diseño (pierde información) | `progreso_leccion(usuario_id, leccion_id)` |
| `Reporte(id, rango, tipo, grafico)` y `Recomendacion(… impactoEstimado)` | Datos derivables de movimientos y reglas | Redundancia derivada | No persisten; solo `exportacion` |

## 2. Primera forma normal (1FN)

Condiciones: valores atómicos, sin grupos repetidos, cada tabla con clave primaria.
- Todas las tablas tienen PK (simple o compuesta en `progreso_leccion`).
- `presupuesto.asignaciones` desaparece (una fila por categoría y mes).
- Periodos de `exportacion` se guardan como `periodo_inicio` y `periodo_fin`, no como texto «ene–mar».
- `usuario.nombre_completo` se guarda como una sola cadena porque ninguna regla de negocio la divide.
- **Excepción justificada:** `auditoria.detalle` es `JSON` con texto descriptivo del evento. Nunca se filtra ni se une por su contenido, solo se muestra; las columnas que sí se consultan (`actor_id`, `accion`, `objeto_tipo`, `objeto_id`, `ocurrido_en`) son atómicas.
**Resultado:** las 21 tablas están en 1FN.

## 3. Segunda forma normal (2FN)

Condición: en 1FN y ningún atributo depende de solo una parte de una clave compuesta.
- Solo `progreso_leccion` tiene clave compuesta `(usuario_id, leccion_id)`; su único atributo, `completada_en`, depende de ambas partes (cuándo *ese* usuario completó *esa* lección).
- Las demás tablas usan clave simple `id`, por lo que 2FN se cumple de forma automática.
**Resultado:** las 21 tablas están en 2FN.

## 4. Tercera forma normal (3FN)

Condición: en 2FN y sin dependencias transitivas (ningún atributo no clave depende de otro atributo no clave). Al revisar las dependencias funcionales de las tablas de la primera versión del DER se encontraron **cuatro** violaciones, ya corregidas en los docs 06 y 07:

| Tabla | Dependencia que viola 3FN | Corrección |
|---|---|---|
| `codigo_verificacion` | `id → tipo → canal` (el canal lo determina el tipo: acceso por SMS, correo para verificar correo, etc.) | Se elimina `canal`; la regla tipo→canal vive en el servicio |
| `categoria` | `usuario_id → es_sistema` (es sistema si y solo si no tiene dueño) | Se elimina `es_sistema`; se usa `usuario_id IS NULL` |
| `cuenta_bancaria` | `revocado_en → estado REVOCADA` (se deduce de la fecha) | `estado` queda solo con ACTIVA y ERROR; revocada se deduce de `revocado_en` y vencida de `permiso_vence_en` |
| `exportacion` | `vence_en → estado VENCIDA` | `estado` queda con LISTA y RECHAZADA; vencida se deduce de `vence_en` |

Criterio aplicado: un estado que es función **solo de columnas guardadas** se elimina; un estado de proceso que no se puede deducir (por ejemplo, ERROR de una cuenta) se conserva.

## 5. Forma normal de Boyce-Codd (BCNF)

Condición: todo determinante es clave candidata. Se verifica tabla por tabla con sus dependencias funcionales (DF).

| Tabla | CC | Dependencias funcionales | BCNF |
|---|---|---|---|
| `rol` | `id`; `codigo` | `id → codigo, descripcion`; `codigo → id, descripcion` | Sí |
| `usuario` | `id`; `correo`; `telefono`; `google_sub` | Cada CC determina todas las demás columnas | Sí |
| `consentimiento` | `id` | `id → usuario_id, cuenta_bancaria_id, tipo, version, aceptado_en, ip` | Sí |
| `codigo_verificacion` | `id` | `id → …` (sin `canal`) | Sí |
| `sesion` | `id`; `token_hash` | `id ↔ token_hash → resto` | Sí |
| `intento_acceso` | `id` | `id → …` | Sí |
| `categoria` | `id`; `(usuario_id, tipo, nombre)` | `id → …`; `(usuario_id, tipo, nombre) → id` | Sí |
| `movimiento` | `id` | `id → usuario_id, categoria_id, monto, descripcion, fecha_hora, creado_en, actualizado_en` | Sí* |
| `presupuesto` | `id`; `(categoria_id, mes)` | `(categoria_id, mes) → limite_mensual, umbrales, repite, alertas` | Sí |
| `meta` | `id` | `id → …` | Sí |
| `abono_meta` | `id` | `id → …` | Sí |
| `cuenta_bancaria` | `id` | `id → …` | Sí |
| `sincronizacion` | `id` | `id → …` | Sí |
| `movimiento_propuesto` | `id`; `(cuenta_bancaria_id, id_externo)`; `movimiento_id` | Cada CC determina el resto | Sí* |
| `notificacion` | `id`; `(presupuesto_id, periodo, tipo)` | `id → …` | Sí* |
| `exportacion` | `id` | `id → …` | Sí |
| `leccion` | `id` | `id → …` | Sí |
| `progreso_leccion` | `(usuario_id, leccion_id)` | `(usuario_id, leccion_id) → completada_en` | Sí |
| `plan` | `id`; `codigo` | `id ↔ codigo → nombre, precio_mensual_cop, dias_prueba` | Sí |
| `suscripcion` | `id` | `id → …` | Sí* |
| `auditoria` | `id` | `id → …` | Sí |

\* Con la redundancia controlada que se explica en el apartado 6.

## 6. Redundancias controladas (desnormalizaciones justificadas)

No se desnormaliza por rendimiento. Quedan estas cuatro, con la razón y la protección:

| Dónde | Redundancia | Por qué se acepta | Cómo se protege |
|---|---|---|---|
| `movimiento.usuario_id` | Cuando la categoría es del usuario, `categoria_id → usuario_id` | La categoría «Sin categoría» es del sistema y no tiene dueño, así que el dueño del movimiento no siempre se deduce de ella; además todas las consultas filtran por usuario | Servicio y prueba de integración: la categoría debe ser del mismo usuario o del sistema |
| `notificacion.usuario_id` | Si hay `presupuesto_id`, el destinatario se deduce de la categoría del presupuesto | Las notificaciones de seguridad o del sistema no tienen presupuesto; el destinatario es un hecho propio de la notificación | Se crea siempre desde el servicio de alertas con el dueño del presupuesto |
| `movimiento_propuesto.estado` | `APROBADO ⇔ movimiento_id no nulo` | RECHAZADO y PENDIENTE no se pueden deducir; guardar el estado completo simplifica la bandeja | `CHECK ((estado = 'APROBADO') = (movimiento_id IS NOT NULL))` |
| `suscripcion.prueba_hasta` | Depende de `inicia_en + plan.dias_prueba` | Es la condición **pactada** con la persona; si el cliente cambia los días de prueba del plan, no debe cambiar a quien ya la contrató | Se calcula una sola vez al crear la suscripción |

Dos columnas que parecen redundantes y **no** lo son:
- `intento_acceso.correo_intentado`: es lo que la persona escribió (puede no corresponder a ningún usuario ni al correo actual).
- `notificacion.umbral_pct`: es el valor vigente cuando se envió la alerta; el usuario puede cambiar después sus umbrales.

## 7. Resultado

| Criterio | Resultado |
|---|---|
| Tablas | 21 |
| En 1FN / 2FN / 3FN | 21 / 21 / 21 |
| En BCNF | 21 (4 con redundancia controlada documentada) |
| Datos derivados guardados | Ninguno (balance, %, estados, aporte, progreso, reporte y recomendaciones se calculan) |
| Violaciones halladas y corregidas | 4 en el DER (apartado 4) + 10 en las estructuras de partida (apartado 1) |

**Lista de comprobación para cambios futuros:** antes de añadir una columna, confirmar que (1) es atómica, (2) depende de toda la clave, (3) no se deduce de otra columna guardada y (4) si es un estado, no es función solo de otras columnas.
