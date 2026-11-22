# 11 · Mapa de pantallas web

Cubre: RW-01 a RW-09, RNF-06 a RNF-08, RF-01 a RF-35, RF-A01 a RF-A26.
La columna **Figma** cita el número de página del PDF «DiseñoKarito» (83 páginas). Con él, los IDs `PW-` dejan de ser provisionales (el supuesto de la fase A queda resuelto).

## 1. Principios de adaptación

| Ancho | Navegación (RW-01) | Disposición |
|---|---|---|
| Celular < 768 px (desde 360 px) | Barra inferior de **5 destinos**: Inicio, Movimientos, Presupuestos, Metas, Más | Una columna; formularios a pantalla completa; tablas pasan a tarjetas |
| Tableta 768–1023 px | Panel lateral plegable (solo íconos) | Dos columnas donde ayuda; formularios en panel lateral derecho |
| Escritorio ≥ 1024 px | Panel lateral fijo con texto | Rejilla de 12 columnas, contenido máximo 1200 px; tablas completas; formularios en diálogo |

- **«Más»** (celular) agrupa: Reportes, Cuentas conectadas, Aprender, Notificaciones, Mi cuenta y Plan. En escritorio y tableta esos destinos están en el panel lateral.
- **Botón «+» flotante** solo en Inicio y Movimientos (RW-02); en escritorio es un botón «Registrar movimiento» en el encabezado, como en el Figma web (página 81).
- **Colores con significado fijo** (RW-06, paleta oficial del Figma, página 82): azul confianza `#15579A` (marca y navegación), azul oscuro `#0D3B69` (texto), verde `#278F4F` (solo logro y ahorro), naranja `#D67600` (solo aviso del 80 %), rojo `#BE2D2D` (solo límite excedido, siempre con acción), crema `#EEF4FA` (fondos). El color nunca es el único indicador: se acompaña de texto o ícono (RNF-08).
- **Sin desbordes horizontales** desde 360 px (RNF-06): tablas y gráficos con `overflow-x: auto` dentro de su contenedor.

## 2. Inventario de pantallas

| ID | Pantalla | Ruta | Rol | Figma | Requisitos |
|---|---|---|:-:|---|---|
| PW-00 | Estructura y navegación | (marco de todas) | U | 14, 50, 81 | RW-01, RW-02 |
| PW-L01 | Landing | `/` | P | 1 | RW-07 |
| PW-L02 | Términos y política de privacidad | `/legal/terminos`, `/legal/privacidad` | P | 10, 11 | RF-02, RNF-12 |
| PW-01 | Registro y consentimientos | `/registro` | P | 3 | RF-01, RF-02, RF-15 |
| PW-02 | Verificar correo | `/verificar-correo` | P | — nueva | RF-03 |
| PW-03 | Iniciar sesión | `/iniciar-sesion` | P | 2, 81 | RF-04, RF-05 |
| PW-04 | Verificar o registrar teléfono (tras Google) | `/verificar-telefono` | P* | 12 + nueva | RF-05, RF-07 |
| PW-05 | Código SMS | `/codigo` | P* | 4 | RF-06, RF-08 |
| PW-06 | Recuperar contraseña | `/recuperar-contrasena` | P | 9 | RF-10 |
| PW-07 | Recuperar acceso por pérdida del teléfono | `/recuperar-acceso` | P | — nueva | RF-11 |
| PW-08 | Inicio (resumen) | `/inicio` | U | 14, 16, 81 | RF-15, RF-25 |
| PW-09 | Categorías | `/categorias` | U | 19 (selector) + nueva | RF-16 |
| PW-10 | Movimientos | `/movimientos` | U | 26–37 | RF-17, RF-18 |
| PW-11 | Presupuestos | `/presupuestos` | U | 19–23 | RF-19, RF-20 |
| PW-12 | Notificaciones y alertas | `/notificaciones` | U | 17, 18, 69 | RF-20, RF-21, RF-35 |
| PW-13 | Metas y abonos | `/metas` | U | 44, 45, 47–49 | RF-22, RF-23, RF-24 |
| PW-14 | Mi cuenta y seguridad | `/cuenta` | U | 50–52, 72–76 | RF-09, RF-12, RF-13, RF-14, RF-34 |
| PW-15 | Reportes y exportación | `/reportes` | U | 70, 71 | RF-26, RF-27, RW-08 |
| PW-16 | Cuentas conectadas | `/cuentas-conectadas` | U | 66–68, 75 | RF-28, RF-29, RF-34, RW-03 |
| PW-17 | Movimientos propuestos | `/movimientos-propuestos` | U | 68 (bandeja) | RF-30, RF-31 |
| PW-18 | Aprender (educación) | `/aprender` | U | 39–43 | RF-32, RW-08 |
| PW-19 | Plan y suscripción | `/plan` | U | 78 | RF-33 |
| PW-A01 | Acceso de administración | `/admin/acceso` | P | 81 (adaptada) | RF-A01 |
| PW-A02 | Usuarios | `/admin/usuarios` | A | 83 | RF-A02, RF-A03 |
| PW-A03 | Contenido educativo | `/admin/contenido` | A | 83 | RF-A04 |
| PW-A04 | Métricas agregadas | `/admin/metricas` | A | 83 | RF-A05 |
| PW-S01 | Cuentas ADMIN | `/superadmin/admins` | S | — nueva | RF-A24 |
| PW-S02 | Génesis del proyecto | `/superadmin/genesis` | S | — nueva | RF-A25, RW-09 |
| PW-S03 | Auditoría | `/superadmin/auditoria` | S | — nueva | RF-A26, RW-09 |

Roles: **P** público, **P\*** público atado a un reto SMS vigente, **U** usuario, **A** ADMIN o SUPERADMIN, **S** solo SUPERADMIN. El PDF solo trae un encabezado del panel de administración (página 83), por lo que las pantallas de administración tienen referencia mínima y deben diseñarse.

## 3. Adaptación por pantalla

| Pantalla | Escritorio | Tableta | Celular |
|---|---|---|---|
| PW-03 / PW-01 | Dos paneles: mensaje de marca a la izquierda y formulario a la derecha (Figma 81) | Formulario centrado | Solo formulario; «Continuar con Google» bajo el botón principal |
| PW-05 | Diálogo centrado con 6 casillas, temporizador de reenvío y aviso «Nadie de FinanSmart te pedirá este código» | Igual | Pantalla completa; teclado numérico; autocompletado del SMS |
| PW-08 | Tarjetas de balance, ingresos, gastos y tasa en una fila; presupuestos, metas y movimientos recientes en rejilla | Tarjetas 2×2 | Pila vertical; balance arriba |
| PW-10 | Tabla con filtros arriba y detalle en panel derecho | Tabla simplificada | Lista de tarjetas con búsqueda; formulario a pantalla completa |
| PW-11 | Lista de presupuestos y detalle lado a lado | Lista y detalle en dos columnas | Lista; el detalle abre pantalla aparte |
| PW-13 | Rejilla de metas; abonar en diálogo | Rejilla de 2 | Lista; abonar en hoja inferior |
| PW-15 | Gráficos y tabla juntos; exportar en diálogo | Gráficos arriba | Gráficos apilados con desplazamiento interno |
| PW-16 / PW-17 | Cuentas a la izquierda y bandeja a la derecha | Una sobre otra | Una por pantalla |
| PW-A02 | Tabla con búsqueda y acciones | Tabla con columnas esenciales | Tarjetas con menú de acciones |
| PW-S02 | Índice lateral de secciones y contenido ancho | Índice colapsable | Índice en menú desplegable |

## 4. Estados vacío, carga y error (RW-05)

Todas las pantallas muestran un **esqueleto de carga** (sin bloquear la navegación) y un **error con acción «Reintentar»** que no pierde lo escrito. El estado vacío de cada pantalla:

| Pantalla | Estado vacío (texto y acción) |
|---|---|
| PW-08 | «Tu cuenta empieza vacía. Registra tu primer movimiento y verás tu resumen aquí.» → Registrar movimiento (Figma 27) |
| PW-09 | «Aún no tienes categorías. Crea la primera para empezar a registrar.» → Crear categoría |
| PW-10 | «Aún no tienes movimientos. Registra tu primer gasto o ingreso.» → Registrar movimiento (Figma 27) |
| PW-11 | «Aún no defines límites. Elige una categoría de gasto y fija cuánto quieres gastar al mes.» → Crear presupuesto |
| PW-12 | «No tienes notificaciones.» |
| PW-13 | «Aún no tienes metas. Crea una con un monto y una fecha.» → Crear meta |
| PW-15 | «Sin datos en este periodo. Cambia el periodo o registra movimientos.» |
| PW-16 | «No has conectado cuentas. Es opcional y de solo lectura.» → Conectar cuenta (plan Pro) |
| PW-17 | «No hay movimientos por revisar.» |
| PW-18 | «Aún no hay lecciones publicadas.» |
| PW-A02 | «No hay usuarios que coincidan con la búsqueda.» |
| PW-A03 | «Aún no hay lecciones. Crea la primera en borrador.» |
| PW-S01 | «No hay cuentas ADMIN.» |
| PW-S03 | «Sin eventos en este rango.» |

**Errores específicos:** guardar un movimiento fallido muestra «No pudimos guardar el movimiento» con reintento (Figma 26); SMS no enviado muestra «No pudimos enviar el código, intenta de nuevo en unos minutos» sin vía alterna (RNF-11); permiso bancario vencido muestra «Requiere reconexión» (Figma 68).

## 5. Pantallas del Figma que NO pasan a la web (INC-20)

| Figma | Pantalla | Motivo |
|---|---|---|
| 5–8 | Preguntas de inicio y «Tu diagnóstico» | Recoge ingreso y plazos que el sistema no guarda (la cuenta nace vacía, D-06) y alimenta salud financiera, fuera de alcance |
| 13 | Face ID | Biometría fuera de alcance; el segundo factor es el SMS (D-05) |
| 15 | Vista previa con datos de ejemplo | Muestra cifras inventadas; contradice «la cuenta nace vacía» y RW-07 (INC-21) |
| 38 | Gastos fijos | Función futura (D-06) |
| 46, 80 | Compartir logro, Mis logros | No está en los requisitos; decisión del cliente (PA-11) |
| 53 | Idioma | La web es solo español de Colombia (RNF-07) |
| 54–56 | Salud financiera, plan para mejorar, ¿cómo se calcula? | Función futura |
| 57–59 | Patrimonio neto | Función futura |
| 60–61 | Fondo de emergencia | Función futura |
| 62–65 | Libertad financiera, plan paso a paso, simulador | Función futura |
| 79 | Mis deudas | Función futura |
| 24, 25 | Comparativo mes a mes, calendario | No están en los requisitos; candidatos a fase futura (PA-12) |

Para las funciones futuras: sin menú, sin botón y sin «próximamente» (RW-04, D-06). Solo viven como backlog en el análisis.

## 6. Pantallas y requisitos nuevos por diseñar

| Pantalla | Por qué | Propuesta |
|---|---|---|
| PW-02 Verificar correo | RF-03 no tiene diseño | Pantalla de estado: «Revisa tu correo» y «Enlace vencido» con reenvío |
| PW-04 (parte de teléfono) | Figma 12 solo cubre «Elegir cuenta» de Google | Formulario de teléfono con verificación por SMS (RF-07) |
| PW-07 Pérdida del teléfono | RF-11 | Flujo de 3 pasos con espera de seguridad (PA-03) |
| PW-09 Categorías | Solo existe el selector | Lista con crear, editar, eliminar y reasignar (RF-16) |
| PW-A01 a PW-A04, PW-S01 a PW-S03 | Solo hay un encabezado de administración (Figma 83) | Diseñar con la paleta y el marco del Figma web |
| **RF-36 (propuesta)** Dispositivos activos | El Figma 74 lo muestra y encaja con el 2FA obligatorio; la tabla `sesion` ya lo soporta | Ver y cerrar sesiones propias en PW-14 |
| **RF-37 (propuesta)** Ayuda y soporte | Figma 77; no hay requisito | Decisión del cliente (PA-13) |

Las propuestas RF-36 y RF-37 **no** están aprobadas: se agregan al backlog hasta que el cliente las acepte.

## 7. Textos y cifras a corregir en el diseño

| ID | Dónde (Figma) | Problema | Decisión |
|---|---|---|---|
| INC-17 | 81 | «+12.000 usuarios activos», «4.8/5 calificación» y «20 % menos errores financieros» no tienen fuente (el producto no ha lanzado) | Quitar (D-07). Texto sin cifras: «Registra, controla y alcanza tus metas». Sección de confianza con hechos verificables (cifrado, solo lectura, 2FA) |
| INC-18 | 2, 14, 16 | La tasa de ahorro dice 39 %, pero 1.240.500 / 3.200.000 = 38,77 % y la política es truncar | Mostrar **38 %** (doc 04) |
| INC-19 | 68 | Muestra **saldos** por cuenta y «Total en cuentas», «Sincronizado hace 2 min» y «Ya los clasificamos». Contradice: 2 sincronizaciones al día, no hay saldos en el modelo de datos y la clasificación es solo sugerida | Quitar saldos y total; mostrar «Última sincronización» y «Próxima disponible» (RW-03); texto «Te sugerimos una categoría para cada uno»; quitar el ícono de actualizar |
| INC-20 | ver §5 | Pantallas del Figma fuera del alcance web | Ocultas |
| INC-21 | 15 | Vista previa con datos de ejemplo | No se incluye |
| INC-22 | 78 | El plan Pro lista salud financiera, patrimonio, simulador, deudas y gastos fijos (ocultos), y «Exportar sin límite». El Gratis lista registro, presupuestos, metas y reportes del mes | Con las funciones ocultas, el Pro web ofrece conexión bancaria y exportación sin límite. Propuesta para PA-02: Gratis = lo que lista el Figma; Pro = banca + exportación. Descuento anual «ahorra 20 %» queda pendiente de PA-02 |
| INC-23 | 20–22 y 28 | Con límite 200.000, un movimiento de 28.000 son 14 puntos: 98 % → 84 %, no 91 % → 84 % | Ejemplo corregido en el doc 04; PA-07 se responde con el límite del Figma (200.000) |

## 8. Resumen (cifras verificadas contra las tablas de este documento)

- **29 pantallas web:** 1 marco de navegación (PW-00), 2 públicas (landing y legales), 7 de acceso (PW-01 a PW-07), 12 de uso diario del usuario (PW-08 a PW-19), 4 de ADMIN y 3 de SUPERADMIN.
- **Las 83 páginas del Figma:** 56 sirven de guía visual, 25 quedan fuera del alcance web (§5), 1 es una propuesta pendiente (página 77, ayuda y soporte) y 1 es el sistema de diseño (página 82).
- **Por diseñar total o parcialmente:** PW-02, PW-04 (parte de teléfono), PW-07, PW-09 (lista de categorías), PW-S01, PW-S02 y PW-S03; las 4 de ADMIN (PW-A01 a PW-A04) tienen solo un encabezado de referencia.
