# 01 · Resumen ejecutivo y registro de decisiones

Versión 2 · Noviembre de 2026 · Cubre: RF-A24, RF-05, RF-08, RF-12, RF-A01, RN-01, RN-03, RNF-11, RNF-15 (ver doc 03).

## 1. Resumen ejecutivo
FinanSmart pasa a desarrollarse **solo como sitio web responsive** (celular < 768 px, tableta 768–1023 px, escritorio ≥ 1024 px, desde 360 px). El proyecto móvil queda en pausa y sus pantallas sirven de guía visual. El sistema tiene tres roles (USUARIO, ADMIN, SUPERADMIN), 2FA por SMS obligatorio en todo acceso, banca de solo lectura con revisión manual del usuario, y un principio rector: **la cuenta nace vacía; el usuario crea todo; el sistema calcula, resume y alerta.**

## 2. Estado de los insumos (regla «insumos ilegibles»)
| Insumo | Estado | Consecuencia |
|---|---|---|
| Prompt maestro v2 (texto) | Recibido y leído | Fuente de este paquete |
| Informe 1 «PROYECTO FINANSMART» | **No recibido en esta conversación** | Se usan solo las afirmaciones citadas en el prompt (RNF2, `generarTransacciones()`). No se supone nada más. |
| Documento web v1.0 (20 tablas, 18 puntos) | **No recibido** | Los IDs RF/RF-A/RNF/RW/RN originales no se reproducen; se crea numeración consolidada con equivalencias solo donde el prompt las nombra. |
| PDF Figma (83 pantallas) | **No recibido** | Los IDs de pantalla son provisionales (`P-xx`) hasta revisión. |
| DER Canva | Solo las 10 entidades listadas | La tabla de diferencias (doc 07) se basa en esa lista. |

**Acción requerida del cliente:** adjuntar los insumos 1–4 para conciliar IDs y cerrar los 18 puntos por definir.

## 3. Decisiones confirmadas (definitivas)
| ID | Decisión | Efecto |
|---|---|---|
| D-01 | Web responsive; móvil en pausa | Pantallas móviles = guía |
| D-02 | Roles USUARIO / ADMIN / SUPERADMIN; nadie salvo el usuario ve movimientos, saldos o cuentas | RF-A24 pasa a «incluido» |
| D-03 | Plan Gratis y Pro: $11.900 COP/mes, prueba 7 días | Pendientes: descuento anual, límites Gratis, pasarela |
| D-04 | Contraseña mínimo 8 en registro y cambio | Reglas de composición en §5 |
| D-05 | 2FA SMS obligatorio en todo acceso, incluido Google | Reemplaza «activar/desactivar» de RF-08 |
| D-06 | Funciones futuras ocultas en web | Solo backlog (§7) |
| D-07 | Cifras de marketing sin fuente: no se publican | Textos en §6 |
| D-08 | «Génesis del proyecto» en zona SUPERADMIN, solo lectura | RF-A24, RF-A25 |
| D-09 | DER nuevo y unificado | Doc 07 |
| D-10 | Entrega en GitHub sin credenciales | Este repo |

## 4. Resolución de incongruencias (trazabilidad)
| ID | Conflicto | Decisión | Justificación | Documento afectado | Estado |
|---|---|---|---|---|---|
| INC-01 | Clases ≠ tablas (Transaccion/movimiento, MetaFinanciera/meta+abono_meta, Presupuesto.montoTotal vs límite por categoría, Categoria.limiteMensual duplicado, Alerta/Recomendacion/Reporte vs notificacion/exportacion) | Nomenclatura única en español, snake_case en BD y PascalCase en clases: `Movimiento`, `Meta`, `AbonoMeta`, `Presupuesto`, `Categoria`, `Notificacion`, `Exportacion`. **Persistente:** movimiento, meta, abono_meta, presupuesto, categoria (con `limite_mensual`), notificacion, exportacion. **Calculado (no persiste):** % de uso, estado del presupuesto, balance, tasa de ahorro, aporte mensual, progreso de meta, Reporte y Recomendación. `Presupuesto.montoTotal` se elimina: el total es la suma de límites de categoría. | Evita duplicidad y desincronización; lo derivado no se guarda | Informe 1 (diagrama de clases), DER Canva | Resuelta |
| INC-02 | Banca «tiempo real» y clasificación automática vs máx. 2 al día y aprobación uno por uno | Prevalece revisión del usuario. RNF2 del informe 1 se reescribe; `generarTransacciones()` pasa a `proponerMovimientos()` y crea `MovimientoPropuesto`, nunca `Movimiento`. | Privacidad, control del usuario, costo y fiabilidad | Informe 1 (RNF2, `SincronizacionBancaria`) | Resuelta |
| INC-03 | DER Canva incompleto | Se agregan: rol, movimiento_propuesto, sincronizacion, auditoria, consentimiento, codigo_verificacion, sesion, intento_acceso, abono_meta, leccion y progreso_leccion (el usuario se liga a lecciones vía `progreso_leccion`, tabla necesaria por ser N:M; la liga directa de Canva no permite registrar avance). Reporte es calculado; solo `exportacion` persiste. | Cumple 3FN y trazabilidad | DER Canva | Resuelta (detalle en doc 07) |
| INC-04 | Cifras de ejemplo no cuadran (Alimentación 91 % → 84 % al eliminar $28.000) y textos cortados | Se retira el ejemplo y se recalcula en doc 04 con fórmula: el % depende del límite; con límite L, bajar 7 puntos exige 28.000 = 0,07·L → L = 400.000 (ejemplo coherente: 364.000 → 336.000 = 91 % → 84 %). Textos cortados: corregir en Figma. | Ejemplo verificable | Figma (pantallas de presupuesto) | Resuelta (verificar L real con el cliente) |
| INC-05 | Barra inferior móvil vs panel lateral web; «+» flotante; ícono de actualizar sugiere sincronización manual | Escritorio/tableta: panel lateral. Celular: barra inferior de 5 destinos máx. «+» flotante solo en Inicio y Movimientos. El ícono de actualizar se **elimina**; se muestra «Última sincronización» y «Próxima disponible». | No existe sincronización manual (regla de banca) | Figma «Cuentas conectadas» | Resuelta |
| INC-06 | Segmento objetivo | «Jóvenes profesionales, universitarios y familias en Colombia (mayores de edad)». | Un solo texto en toda la documentación; el filtro de edad (≥ 18) manda | Informes 1 y 2, marketing | Resuelta |
| INC-07 | Redondeos RN-01 (abajo), RN-03 (arriba), DECIMAL(15,2) y COP | Política única (doc 04): montos guardados en **pesos enteros** con escala .00; porcentajes mostrados con **truncamiento** a entero (nunca se muestra 80 % antes de la alerta); umbrales comparan el valor **exacto**; montos necesarios para cumplir una meta se redondean **hacia arriba** al peso. | Coherencia con alerta al 80 % y meta alcanzable | RN-01, RN-03 | Resuelta |
| INC-08 | RF-08 «activar/desactivar 2FA» contradice D-05 | RF-08 pasa a «2FA obligatorio» (no configurable) | Decisión del cliente | Doc web RF-05, RF-08, RF-12, RF-A01 | Resuelta |
| INC-09 | «Google ya verificó teléfono/correo» | Se ignora esa verificación; SMS siempre | D-05 | RF-05 | Resuelta |
| INC-10 | Funciones futuras visibles en diseños | Se ocultan (D-06) | Alcance MVP | Figma | Resuelta |
| INC-11 | Cifras de marketing sin fuente | Se eliminan (§6) | Ley 1480 de 2011 | Landing | Resuelta; **pendiente validación legal** |

## 5. Decisiones de diseño propias (justificadas)
**Contraseña (D-04).** Mínimo 8, máximo 64; al menos una letra y un número; sin espacios en los extremos; no igual al correo, nombre o teléfono; no estar en lista de contraseñas comunes; se permite cualquier carácter Unicode. Se almacena con hash adaptativo (bcrypt/Argon2). *Supuesto:* no se exige símbolo ni rotación periódica (prácticas actuales y compatibles con el mínimo de 8).

**Códigos SMS (D-05).** Valores propuestos (a confirmar por el cliente):
| Parámetro | Valor |
|---|---|
| Longitud | 6 dígitos numéricos, generados con CSPRNG |
| Vigencia | 5 minutos |
| Uso | Único; se invalida al usarse o al emitir uno nuevo |
| Reenvío | Temporizador de 60 s |
| Intentos por código | 5; al 5.º fallo el código se invalida |
| Reenvíos por hora | 5 por usuario |
| Bloqueo temporal | 15 min tras 5 fallos acumulados o 5 reenvíos; aviso por correo |
| Almacenamiento | Solo hash del código |

**Casos del 2FA:**
| Caso | Decisión |
|---|---|
| Primer ingreso con Google sin teléfono | Estado `PENDIENTE_VERIFICACION`; pantalla única para ingresar y verificar teléfono; ninguna otra ruta accesible |
| Vincular Google a cuenta con contraseña | Exige SMS al vincular y en cada ingreso |
| Pérdida del teléfono | Recuperación con verificación de identidad (correo verificado + contraseña + validación definida por el cliente, **punto abierto PA-03**), espera de seguridad, auditoría y aviso a correo y teléfono anterior |
| Cambio de teléfono (RF-12) | Contraseña → código al número nuevo → aviso al anterior (SMS) y al correo → auditoría |
| Fallo del proveedor SMS | Mensaje «No pudimos enviar el código; intenta de nuevo en unos minutos»; sin vía alterna ni omisión; se registra en `intento_acceso` |
| Dispositivo de confianza (RNF-11/RNF-15) | **Solo evaluado, no incluido.** Reduciría costo y fricción pero debilita D-05; punto abierto PA-01 |

## 6. Textos honestos sin cifras (D-07)
- «Empieza con tu cuenta vacía y decide tú cómo organizar tu dinero.»
- «Define tus presupuestos, recibe avisos a tiempo y revisa cuánto llevas ahorrado.»
- «Conecta tus cuentas en modo solo lectura y aprueba cada movimiento tú mismo.»
- Regla: toda cifra pública requiere fuente citada y fecha. **Validar con asesoría legal** la publicidad (Ley 1480 de 2011).

## 7. Backlog «fase futura» (oculto en web)
Salud financiera, patrimonio neto, fondo de emergencia, libertad financiera, simulador, deudas, gastos fijos, IA y biometría. Sin menú, sin botones, sin «próximamente».

## 8. Supuestos y puntos abiertos
| ID | Tipo | Descripción |
|---|---|---|
| S-01 | Supuesto | Montos en pesos enteros |
| S-02 | Supuesto | Valores SMS de §5 |
| S-03 | Supuesto | Un usuario tiene un solo teléfono activo |
| S-04 | Supuesto | Prueba de 7 días sin tarjeta hasta definir pasarela |
| PA-01 | Abierto | Dispositivo de confianza por tiempo limitado |
| PA-02 | Abierto | Descuento anual, límites del plan Gratis, pasarela de pago |
| PA-03 | Abierto | Método de verificación de identidad en pérdida del teléfono |
| PA-04 | Abierto | Validación legal Ley 1480 y tratamiento de datos (Ley 1581 de 2012) |
| PA-05 | Abierto | Proveedor de SMS, costo y SLA |
| PA-06 | Abierto | Los 18 puntos por definir del documento web (insumo no recibido) |
| PA-07 | Abierto | Valor real del límite de Alimentación del ejemplo INC-04 |
