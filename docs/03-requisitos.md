# 03 · Requisitos consolidados

**Convenciones.** Prioridad MoSCoW: M/S/C/W. Los IDs consolidados son nuevos; solo se mencionan equivalencias originales que el prompt nombra (RF-05, RF-08, RF-12, RF-A01, RF-A24, RNF-11, RNF-15, RN-01, RN-03). Los CU, pantallas (`PW-`) y tablas son los que se desarrollan en las fases B y C. *Supuesto:* los IDs `PW-` son provisionales hasta recibir el PDF de Figma.

## Catálogo de casos de uso (referencia)
CU-01 Registrarse · CU-02 Iniciar sesión · CU-03 Verificar SMS · CU-04 Vincular Google · CU-05 Recuperar contraseña · CU-06 Recuperar acceso por pérdida de teléfono · CU-07 Cambiar correo/teléfono · CU-08 Gestionar categorías · CU-09 Gestionar movimientos · CU-10 Gestionar presupuesto · CU-11 Recibir alertas · CU-12 Gestionar metas y abonos · CU-13 Conectar cuenta bancaria · CU-14 Revisar movimientos propuestos · CU-15 Ver resumen y reportes · CU-16 Exportar · CU-17 Estudiar lecciones · CU-18 Gestionar suscripción · CU-19 Gestionar usuarios (ADMIN) · CU-20 Gestionar contenido educativo (ADMIN) · CU-21 Gestionar cuentas ADMIN (SUPERADMIN) · CU-22 Ver Génesis (SUPERADMIN) · CU-23 Consultar auditoría.

## RF · Funcionales del usuario
| ID | Requisito | MoSCoW | Criterio de aceptación | CU | Tabla | Pantalla |
|---|---|---|---|---|---|---|
| RF-01 | Registro con correo, contraseña, nombre, teléfono y fecha de nacimiento | M | Rechaza menores de 18; contraseña según RN-10; correo único | CU-01 | usuario, consentimiento | PW-01 |
| RF-02 | Aceptar términos y tratamiento de datos antes de crear la cuenta | M | Sin consentimiento no se crea; se guarda versión y fecha | CU-01 | consentimiento | PW-01 |
| RF-03 | Verificar correo con enlace de un solo uso | M | Enlace caduca y no se reutiliza | CU-01 | codigo_verificacion | PW-02 |
| RF-04 | Iniciar sesión con correo y contraseña | M | Credenciales correctas llevan siempre a verificación SMS (RF-06) | CU-02 | usuario, sesion, intento_acceso | PW-03 |
| RF-05 | «Continuar con Google» solo autentica identidad; el SMS es siempre el segundo factor | M | Aun con correo/teléfono marcados como verificados por Google, se exige SMS | CU-02, CU-04 | usuario, sesion | PW-03, PW-04 |
| RF-06 | Verificación SMS en todo acceso (usuario, ADMIN, SUPERADMIN) | M | Sin código válido no hay sesión; parámetros de RN-11 | CU-03 | codigo_verificacion | PW-05 |
| RF-07 | Primer ingreso con Google sin teléfono: pedir y verificar teléfono antes de cualquier pantalla | M | Cuenta en `PENDIENTE_VERIFICACION`; el servidor rechaza cualquier otra ruta | CU-03, CU-04 | usuario | PW-04 |
| RF-08 | 2FA obligatorio y no desactivable (reemplaza «activar/desactivar») | M | No existe opción para apagarlo en UI ni API | CU-03 | usuario | PW-05 |
| RF-09 | Vincular Google a cuenta existente exige SMS | M | Sin código válido no se vincula; se audita | CU-04 | usuario, auditoria | PW-14 |
| RF-10 | Recuperar contraseña por correo | M | Enlace de un solo uso; tras restablecer se cierran sesiones; el ingreso exige SMS | CU-05 | codigo_verificacion, sesion | PW-06 |
| RF-11 | Recuperar acceso por pérdida del teléfono con verificación de identidad | M | Registra auditoría; avisa a correo y teléfono anterior; método según PA-03 | CU-06 | auditoria, codigo_verificacion | PW-07 |
| RF-12 | Cambiar teléfono: contraseña, código al número nuevo, aviso al anterior, auditoría | M | Los cuatro pasos son obligatorios; falla si falta alguno | CU-07 | usuario, auditoria | PW-14 |
| RF-13 | Cambiar correo con las mismas garantías que RF-12 | M | Contraseña, código al correo nuevo, aviso al anterior, auditoría | CU-07 | usuario, auditoria | PW-14 |
| RF-14 | Fecha de nacimiento no editable | M | API devuelve 403 al intentar modificarla | CU-07 | usuario | PW-14 |
| RF-15 | Cuenta nace vacía; sin categorías, movimientos ni metas precargados | M | Tras el registro, todos los listados están vacíos con estado vacío guiado | CU-01 | — | PW-08 |
| RF-16 | Crear, editar y eliminar categorías propias | M | Eliminar con movimientos asociados exige reasignar (ver RN-09) | CU-08 | categoria | PW-09 |
| RF-17 | Registrar, editar y eliminar movimientos (ingreso/gasto) | M | Monto > 0; fecha ≤ hoy; categoría obligatoria; recalcula todo derivado | CU-09 | movimiento | PW-10 |
| RF-18 | Detectar posibles duplicados al registrar | S | Mismo monto, fecha y categoría muestra aviso y pide confirmar | CU-09 | movimiento | PW-10 |
| RF-19 | Definir presupuesto mensual como límites por categoría | M | Límite ≥ 0 (ver RN-07); no hay monto total almacenado | CU-10 | presupuesto, categoria | PW-11 |
| RF-20 | Alertas al 80 % y 100 % configurables por usuario | M | Se dispara una vez por umbral y mes; valores por defecto 80 y 100 | CU-11 | notificacion, presupuesto | PW-11, PW-12 |
| RF-21 | Límite excedido muestra acción sugerida | M | Mensaje en rojo con al menos una acción (ajustar límite, revisar movimientos) | CU-11 | notificacion | PW-12 |
| RF-22 | Crear metas de ahorro con monto objetivo y fecha | M | Objetivo > 0; fecha futura | CU-12 | meta | PW-13 |
| RF-23 | Registrar abonos a una meta | M | Abono > 0; actualiza progreso; meta cumplida se marca | CU-12 | abono_meta | PW-13 |
| RF-24 | Meta de ahorro objetivo por defecto 20 % del ingreso, editable | S | Valor por defecto visible y cambiable | CU-12 | usuario | PW-13 |
| RF-25 | Resumen: balance, tasa de ahorro, uso por categoría | M | Cálculos según doc 04 | CU-15 | (calculado) | PW-08 |
| RF-26 | Reportes calculados por periodo | S | No se persisten; se generan al consultar | CU-15 | (calculado) | PW-15 |
| RF-27 | Exportar a PDF (≤ 5.000 movimientos) y Excel (≤ 100.000) | S | Sobre el tope: mensaje y sugerencia de filtrar; queda registro | CU-16 | exportacion | PW-15 |
| RF-28 | Conectar cuenta bancaria o billetera en solo lectura | S | Sin credenciales; permiso con vencimiento y revocable; historial 90 días | CU-13 | cuenta_bancaria, consentimiento | PW-16 |
| RF-29 | Sincronización automática máx. 2 por día por usuario; sin botón manual | S | Una tercera solicitud se rechaza; no hay control de actualizar | CU-13 | sincronizacion | PW-16 |
| RF-30 | Movimientos propuestos aprobados o rechazados uno por uno | S | No afectan balance, presupuestos, alertas ni reportes hasta aprobar | CU-14 | movimiento_propuesto | PW-17 |
| RF-31 | Un movimiento rechazado no vuelve a proponerse | S | `UNIQUE(cuenta_bancaria_id, id_externo)` y estado `RECHAZADO` persistente | CU-14 | movimiento_propuesto | PW-17 |
| RF-32 | Lecciones de educación financiera con progreso por usuario | C | Marcar completada guarda avance | CU-17 | leccion, progreso_leccion | PW-18 |
| RF-33 | Plan Gratis y Pro ($11.900/mes, prueba 7 días) | S | Cambios de plan visibles; límites del Gratis por PA-02 | CU-18 | suscripcion | PW-19 |
| RF-34 | Revocar permiso bancario y eliminar cuenta | S | Revocación inmediata; eliminación con confirmación | CU-13 | cuenta_bancaria, usuario | PW-14 |
| RF-35 | Notificaciones dentro de la app y por correo | S | Lista con leído/no leído | CU-11 | notificacion | PW-12 |

## RF-A · Administración
| ID | Requisito | MoSCoW | Criterio | CU | Tabla | Pantalla |
|---|---|---|---|---|---|---|
| RF-A01 | Inicio de sesión de ADMIN/SUPERADMIN con 2FA SMS obligatorio | M | Idéntico a RF-06; sin excepciones | CU-02, CU-03 | usuario, rol, sesion | PW-A01 |
| RF-A02 | ADMIN gestiona usuarios (listar, suspender, reactivar) sin ver movimientos, saldos ni cuentas | M | La API de admin no expone esos datos; prueba automatizada | CU-19 | usuario | PW-A02 |
| RF-A03 | Suspender cuenta cierra sesiones activas | M | Siguiente petición con la sesión previa devuelve 401 | CU-19 | sesion | PW-A02 |
| RF-A04 | ADMIN gestiona contenido educativo | C | CRUD de lecciones | CU-20 | leccion | PW-A03 |
| RF-A05 | ADMIN ve métricas agregadas anónimas (conteos) | C | Sin datos individuales ni montos | CU-19 | (calculado) | PW-A04 |
| RF-A24 | SUPERADMIN gestiona cuentas ADMIN (**incluido**) | M | Crear, suspender, reactivar; todo auditado | CU-21 | usuario, rol, auditoria | PW-S01 |
| RF-A25 | SUPERADMIN accede a «Génesis del proyecto» | M | Ruta separada; protegida en servidor; solo lectura; sin datos de usuarios | CU-22 | auditoria | PW-S02 |
| RF-A26 | Consulta de auditoría | M | Filtros por fecha, actor y acción; solo lectura | CU-23 | auditoria | PW-S03 |

## RNF · No funcionales
| ID | Requisito | MoSCoW | Criterio |
|---|---|---|---|
| RNF-01 | Contraseñas con hash adaptativo; nunca en claro ni en logs | M | Revisión de código y logs |
| RNF-02 | Toda comunicación por HTTPS | M | Sin acceso HTTP |
| RNF-03 | Autorización en servidor por rol en cada endpoint | M | Prueba negativa por rol |
| RNF-04 | Auditoría inmutable (solo inserción) | M | Sin UPDATE/DELETE para el usuario de la aplicación |
| RNF-05 | Montos DECIMAL(15,2); fechas UTC; mostrar en hora de Colombia | M | Verificado en pruebas |
| RNF-06 | Responsive: celular < 768, tableta 768–1023, escritorio ≥ 1024, desde 360 px | M | Sin desbordes horizontales |
| RNF-07 | Español de Colombia: 1.234,56 y DD/MM/AAAA | M | Pruebas de formato |
| RNF-08 | Accesibilidad: contraste suficiente y color nunca como único indicador | S | Revisión con lista WCAG 2.1 AA |
| RNF-09 | Rendimiento: pantallas principales cargan en ≤ 3 s en conexión móvil habitual | S | *Supuesto de umbral* (S-05) |
| RNF-10 | Sincronización bancaria con tope de 2/día aplicado en servidor | M | Prueba de límite |
| RNF-11 | Disponibilidad del 2FA: ante fallo del proveedor SMS no hay vía alterna; se informa al usuario | M | Simulación de caída |
| RNF-12 | Cumplimiento de Ley 1581 de 2012 (datos personales) | M | Validación legal (PA-04) |
| RNF-13 | Rastreabilidad: cada requisito vincula CU, clase, tabla y pantalla | M | Lista de verificación final |
| RNF-14 | Sin credenciales ni tokens en repositorio, ejemplos ni scripts | M | Escaneo de secretos en CI |
| RNF-15 | Fricción del 2FA: temporizador, mensajes claros y reenvío visibles; «dispositivo de confianza» evaluado (PA-01) | S | Prueba de usabilidad |

## RW · Requisitos web
| ID | Requisito | MoSCoW | Criterio | Pantalla |
|---|---|---|---|---|
| RW-01 | Escritorio y tableta: panel lateral; celular: barra inferior de máximo 5 destinos | M | Navegación consistente por ancho | PW-00 |
| RW-02 | Botón «+» flotante solo en Inicio y Movimientos | M | No aparece en otras vistas | PW-08, PW-10 |
| RW-03 | Sin control de «actualizar» en Cuentas conectadas; solo «Última sincronización» y «Próxima disponible» | M | Verificado en diseño | PW-16 |
| RW-04 | Funciones futuras ocultas: sin menú, botones ni «próximamente» | M | Revisión de UI | todas |
| RW-05 | Cada pantalla define estados vacío, carga y error | M | Mapa de pantallas (doc 11) | todas |
| RW-06 | Colores fijos: verde solo logro/ahorro, naranja solo alerta 80 %, rojo solo límite excedido con acción | M | Guía de estilos | todas |
| RW-07 | Textos de marketing sin cifras sin fuente citada | M | Revisión legal | PW-L01 |
| RW-08 | Aviso «Orientación, no asesoría financiera» visible en reportes y educación | M | Presente | PW-15, PW-18 |
| RW-09 | Rutas `/superadmin/*` separadas del resto | M | Prueba de acceso por rol | PW-S01..S03 |

## RN · Reglas de negocio
| ID | Regla | MoSCoW | Origen |
|---|---|---|---|
| RN-01 | Porcentajes se muestran truncados a entero; el umbral se evalúa con el valor exacto | M | Reemplaza RN-01 original (INC-07) |
| RN-02 | Estado del presupuesto: normal < 80 %, aviso ≥ 80 % y < 100 %, excedido ≥ 100 % | M | Alertas por defecto |
| RN-03 | Aportes requeridos para una meta se redondean hacia arriba al peso | M | Reemplaza RN-03 original (INC-07) |
| RN-04 | Solo mayores de 18 años | M | Decisión de alcance |
| RN-05 | Los movimientos propuestos no cuentan hasta aprobarse | M | Banca |
| RN-06 | Máx. 2 sincronizaciones al día por usuario | M | Banca |
| RN-07 | Límite = 0: no se calcula %; se muestra «sin límite definido» y gastar genera estado excedido | M | Caso límite |
| RN-08 | Ingreso = 0: tasa de ahorro «no calculable» | M | Caso límite |
| RN-09 | Eliminar categoría con movimientos exige reasignarlos a otra o a «Sin categoría» del sistema | M | Caso límite |
| RN-10 | Contraseña: 8–64 caracteres, al menos una letra y un número, no común, no igual a datos personales | M | D-04 |
| RN-11 | Código SMS: 6 dígitos, 5 min, un uso, reenvío cada 60 s, 5 intentos, 5 reenvíos/h, bloqueo 15 min | M | D-05 |
| RN-12 | Ni ADMIN ni SUPERADMIN ven movimientos, saldos ni cuentas bancarias de usuarios | M | D-02 |
| RN-13 | Meses restantes ≤ 0 en una meta: no se calcula aporte; se muestra «fecha vencida, ajusta la fecha» | M | Caso límite |
| RN-14 | Meta con abonos ≥ objetivo se marca «cumplida» y no genera aporte | M | Caso límite |
| RN-15 | Correo y teléfono cambian solo con contraseña, código al dato nuevo, aviso al anterior y auditoría | M | Reglas generales |
| RN-16 | Exportación PDF > 5.000 o Excel > 100.000 movimientos se rechaza con mensaje | S | Caso límite |
| RN-17 | La alerta se dispara una vez por umbral, categoría y mes | M | Coherencia con RF-20 |

## Verificación de la fase A
- Sin duplicados: cada concepto tiene un solo ID. Contradicciones abiertas: ninguna dentro de lo recibido; los puntos PA-01 a PA-07 dependen del cliente.
- *Supuesto S-05:* umbral de 3 s propuesto, a confirmar.
