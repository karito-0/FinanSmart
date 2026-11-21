# 06 · Diagrama de clases unificado

Cubre: RF-01 a RF-35, RF-A01 a RF-A26, RN-01 a RN-17, RNF-01, RNF-03, RNF-04.
Alineado con el DER (doc 07). Convención (INC-01): clases en PascalCase y español; atributos en camelCase; tablas y columnas en snake_case. Paquete base `com.finansmart`.

## 1. Qué persiste y qué se calcula

| Persistente (entidad con tabla) | Calculado (objeto de valor, **sin tabla**) |
|---|---|
| Usuario, Rol, Consentimiento, CodigoVerificacion, Sesion, IntentoAcceso, Categoria, Movimiento, MovimientoPropuesto, CuentaBancaria, Sincronizacion, Presupuesto, Meta, AbonoMeta, Notificacion, Exportacion, Leccion, ProgresoLeccion, Auditoria, Plan, Suscripcion | EstadoPresupuesto, ResumenMensual, ProgresoMeta, Reporte, Recomendacion, CupoSincronizacion |

`Reporte` y `Recomendacion` (clases del informe 1) pasan a objetos calculados: un reporte se genera al consultar y solo `Exportacion` deja registro. Las recomendaciones salen de reglas sobre los cálculos y de las lecciones publicadas; no tienen «impacto estimado» inventado.

## 2. Dominio

```mermaid
classDiagram
  class Rol {
    <<enumeration>>
    USUARIO
    ADMIN
    SUPERADMIN
  }
  class Usuario {
    +Long id
    +String nombreCompleto
    +String correo
    +String telefono
    +LocalDate fechaNacimiento
    +Rol rol
    +EstadoUsuario estado
    +int metaAhorroPct
    +esMayorDeEdad() boolean
    +puedeIniciarSesion() boolean
  }
  class Consentimiento {
    +Long id
    +TipoConsentimiento tipo
    +String version
    +Instant aceptadoEn
  }
  class CodigoVerificacion {
    +Long id
    +TipoCodigo tipo
    +String destino
    +int intentos
    +Instant venceEn
    +estaVigente() boolean
  }
  class Sesion {
    +Long id
    +String dispositivo
    +Instant expiraEn
    +Instant cerradaEn
    +estaActiva() boolean
  }
  class IntentoAcceso {
    +Long id
    +Etapa etapa
    +ResultadoIntento resultado
    +Instant ocurridoEn
  }
  class Categoria {
    +Long id
    +String nombre
    +TipoCategoria tipo
    +esDelSistema() boolean
  }
  class Movimiento {
    +Long id
    +BigDecimal monto
    +String descripcion
    +Instant fechaHora
    +tipo() TipoCategoria
  }
  class Presupuesto {
    +Long id
    +LocalDate mes
    +BigDecimal limiteMensual
    +boolean repiteCadaMes
    +int umbralAvisoPct
    +int umbralLimitePct
    +boolean alertasActivas
  }
  class Meta {
    +Long id
    +String nombre
    +BigDecimal montoObjetivo
    +LocalDate fechaObjetivo
  }
  class AbonoMeta {
    +Long id
    +BigDecimal monto
    +LocalDate fecha
  }
  class CuentaBancaria {
    +Long id
    +String entidad
    +String ultimos4
    +TipoCuenta tipo
    +EstadoCuenta estado
    +Instant permisoVenceEn
    +Instant revocadoEn
    +estaVigente() boolean
  }
  class Sincronizacion {
    +Long id
    +Instant ejecutadaEn
    +ResultadoSync resultado
  }
  class MovimientoPropuesto {
    +Long id
    +String idExterno
    +BigDecimal monto
    +TipoCategoria tipo
    +Instant fechaHora
    +EstadoPropuesto estado
    +aprobar(Categoria c) Movimiento
    +rechazar() void
  }
  class Notificacion {
    +Long id
    +TipoNotificacion tipo
    +String periodo
    +Integer umbralPct
    +String mensaje
    +String accionSugerida
    +boolean leida
  }
  class Exportacion {
    +Long id
    +Formato formato
    +LocalDate periodoInicio
    +LocalDate periodoFin
    +EstadoExportacion estado
  }
  class Leccion {
    +Long id
    +String titulo
    +String tema
    +int nivel
    +EstadoLeccion estado
  }
  class ProgresoLeccion {
    +Instant completadaEn
  }
  class Plan {
    +Long id
    +String codigo
    +BigDecimal precioMensualCop
    +int diasPrueba
  }
  class Suscripcion {
    +Long id
    +EstadoSuscripcion estado
    +Instant iniciaEn
    +Instant pruebaHasta
    +Instant venceEn
  }
  class Auditoria {
    +Long id
    +Instant ocurridoEn
    +String accion
    +String objetoTipo
    +Long objetoId
    +String detalle
  }
  Rol "1" --> "0..*" Usuario
  Usuario "1" --> "0..*" Consentimiento
  Usuario "1" --> "0..*" CodigoVerificacion
  Usuario "1" --> "0..*" Sesion
  Usuario "1" --> "0..*" IntentoAcceso
  Usuario "1" --> "0..*" Categoria : crea
  Usuario "1" --> "0..*" Movimiento
  Categoria "1" --> "0..*" Movimiento : clasifica
  Categoria "1" --> "0..*" Presupuesto : tiene
  Usuario "1" --> "0..*" Meta
  Meta "1" *-- "0..*" AbonoMeta
  Usuario "1" --> "0..*" CuentaBancaria
  Usuario "1" --> "0..*" Sincronizacion
  CuentaBancaria "1" --> "0..*" MovimientoPropuesto
  Sincronizacion "1" --> "0..*" MovimientoPropuesto
  MovimientoPropuesto "0..1" --> "0..1" Movimiento : origina
  Categoria "0..1" --> "0..*" MovimientoPropuesto : sugerida
  Usuario "1" --> "0..*" Notificacion
  Presupuesto "0..1" --> "0..*" Notificacion : origina
  Usuario "1" --> "0..*" Exportacion
  Usuario "1" --> "0..*" ProgresoLeccion
  Leccion "1" --> "0..*" ProgresoLeccion
  Plan "1" --> "0..*" Suscripcion
  Usuario "1" --> "0..*" Suscripcion
```

*Auditoría* no tiene relaciones de clave: guarda `actorId` y `objetoId` como referencias lógicas para que el registro sobreviva a la eliminación de cuentas y sea inmutable (RNF-04).
*Reglas de integridad que no expresa el diagrama:* un movimiento y su categoría pertenecen al mismo usuario o la categoría es del sistema; un presupuesto solo apunta a categorías de GASTO del usuario; `Usuario.rol` es un solo rol.

## 3. Objetos calculados

```mermaid
classDiagram
  class CalculadoraFinanciera {
    <<servicio sin estado>>
    +porcentajeUso(BigDecimal gastado, BigDecimal limite) Integer
    +estado(BigDecimal gastado, BigDecimal limite, int aviso, int tope) EstadoPresupuesto
    +balance(BigDecimal ingresos, BigDecimal gastos) BigDecimal
    +tasaAhorro(BigDecimal ingresos, BigDecimal gastos) Integer
    +cumpleMeta(BigDecimal ingresos, BigDecimal gastos, int metaPct) boolean
    +mesesRestantes(LocalDate hoy, LocalDate objetivo) int
    +aporteMensual(Meta meta, BigDecimal ahorrado, LocalDate hoy) Optional
    +progreso(BigDecimal ahorrado, BigDecimal objetivo) int
  }
  class EstadoPresupuesto {
    <<enumeration>>
    NORMAL
    AVISO
    EXCEDIDO
    SIN_LIMITE
  }
  class ResumenMensual {
    +YearMonth mes
    +BigDecimal ingresos
    +BigDecimal gastos
    +BigDecimal balance
    +Integer tasaAhorro
  }
  class ProgresoMeta {
    +BigDecimal ahorrado
    +int porcentaje
    +boolean cumplida
    +BigDecimal aporteSugerido
  }
  class Reporte {
    +YearMonth desde
    +YearMonth hasta
    +ResumenMensual resumen
  }
  class Recomendacion {
    +String titulo
    +String descripcion
    +Long leccionId
  }
  CalculadoraFinanciera ..> EstadoPresupuesto
  CalculadoraFinanciera ..> ResumenMensual
  CalculadoraFinanciera ..> ProgresoMeta
  Reporte o-- ResumenMensual
```

La `CalculadoraFinanciera` implementa F1 a F8 del doc 04 con `BigDecimal` y producto cruzado. Es la única clase autorizada a decidir estados y alertas.

## 4. Servicios

```mermaid
classDiagram
  class ServicioAutenticacion {
    +iniciarSesion(correo, contrasena) RetoSms
    +iniciarConGoogle(identidad) RetoSms
    +verificarSms(retoId, codigo) Sesion
    +cerrarSesiones(usuarioId) void
  }
  class ServicioCodigos {
    +emitir(usuario, tipo, destino) CodigoVerificacion
    +validar(id, codigo) boolean
    +estaBloqueado(usuario) boolean
  }
  class ServicioCuenta {
    +registrar(solicitud) Usuario
    +cambiarTelefono(usuarioId, contrasena, nuevo) void
    +cambiarCorreo(usuarioId, contrasena, nuevo) void
    +vincularGoogle(usuarioId, identidad) void
    +suspender(adminId, usuarioId, motivo) void
    +reactivar(adminId, usuarioId, motivo) void
  }
  class ServicioMovimientos {
    +registrar(usuarioId, datos) Movimiento
    +editar(usuarioId, id, datos) Movimiento
    +eliminar(usuarioId, id) void
    +posiblesDuplicados(usuarioId, datos) List~Movimiento~
  }
  class ServicioPresupuestos {
    +definir(usuarioId, datos) Presupuesto
    +estadoDelMes(usuarioId, mes) List~EstadoPresupuesto~
    +copiarRecurrentes(mes) void
  }
  class ServicioAlertas {
    +evaluar(usuarioId, categoriaId, mes) void
  }
  class ServicioMetas {
    +crear(usuarioId, datos) Meta
    +abonar(usuarioId, metaId, monto) AbonoMeta
    +progreso(usuarioId, metaId) ProgresoMeta
  }
  class ServicioBanca {
    +conectar(usuarioId, autorizacion) CuentaBancaria
    +revocar(usuarioId, cuentaId) void
    +sincronizar(usuarioId) Sincronizacion
    +cupo(usuarioId) CupoSincronizacion
    +aprobar(usuarioId, propuestoId, categoriaId) Movimiento
    +rechazar(usuarioId, propuestoId) void
  }
  class ProveedorBancario {
    <<interface>>
    +obtenerMovimientos(cuenta, desde) List
  }
  class ProveedorSms {
    <<interface>>
    +enviar(telefono, mensaje) void
  }
  class ProveedorCorreo {
    <<interface>>
    +enviar(correo, asunto, cuerpo) void
  }
  class ServicioReportes {
    +resumen(usuarioId, mes) ResumenMensual
    +recomendaciones(usuarioId) List~Recomendacion~
  }
  class ServicioExportacion {
    +exportar(usuarioId, formato, periodo) Exportacion
  }
  class ServicioEducacion {
    +publicadas() List~Leccion~
    +completar(usuarioId, leccionId) void
    +gestionar(adminId, datos) Leccion
  }
  class ServicioSuscripcion {
    +iniciarPrueba(usuarioId) Suscripcion
    +cambiarPlan(usuarioId, planId) Suscripcion
  }
  class ServicioAuditoria {
    +registrar(actor, accion, objeto, detalle) void
    +consultar(filtro) List~Auditoria~
  }
  ServicioAutenticacion ..> ServicioCodigos
  ServicioCodigos ..> ProveedorSms
  ServicioCuenta ..> ServicioCodigos
  ServicioCuenta ..> ProveedorCorreo
  ServicioMovimientos ..> ServicioAlertas
  ServicioPresupuestos ..> ServicioAlertas
  ServicioBanca ..> ProveedorBancario
  ServicioBanca ..> ServicioMovimientos
  ServicioAlertas ..> ProveedorCorreo
  ServicioReportes ..> CalculadoraFinanciera
  ServicioAlertas ..> CalculadoraFinanciera
  ServicioMetas ..> CalculadoraFinanciera
  ServicioAutenticacion ..> ServicioAuditoria
  ServicioCuenta ..> ServicioAuditoria
```

`ServicioBanca.sincronizar` llama a `ProveedorBancario` y crea solo `MovimientoPropuesto` (INC-02); la única vía a `Movimiento` es `aprobar`. `ProveedorBancario`, `ProveedorSms` y `ProveedorCorreo` son interfaces para poder usar simuladores en desarrollo y pruebas, sin credenciales en el código.

## 5. Seguridad y autorización

```mermaid
classDiagram
  class PoliticaContrasena {
    +validar(contrasena, usuario) ResultadoValidacion
    +hashear(contrasena) String
    +coincide(contrasena, hash) boolean
  }
  class AutorizacionPorRol {
    +permitido(Rol rol, Permiso permiso) boolean
  }
  class Permiso {
    <<enumeration>>
    DATOS_FINANCIEROS_PROPIOS
    GESTIONAR_USUARIOS
    GESTIONAR_CONTENIDO
    GESTIONAR_ADMINS
    VER_AUDITORIA
    VER_GENESIS
  }
  class FiltroSesion {
    +autenticar(token) Sesion
    +exigirRol(Rol rol) void
  }
  class FiltroEstadoCuenta {
    +exigirActiva(Usuario u) void
  }
  AutorizacionPorRol ..> Permiso
  FiltroSesion ..> AutorizacionPorRol
  FiltroEstadoCuenta ..> FiltroSesion
```

| Rol | Permisos |
|---|---|
| USUARIO | `DATOS_FINANCIEROS_PROPIOS` |
| ADMIN | `GESTIONAR_USUARIOS`, `GESTIONAR_CONTENIDO` |
| SUPERADMIN | los de ADMIN + `GESTIONAR_ADMINS`, `VER_AUDITORIA`, `VER_GENESIS` |

**No existe** un permiso que dé a ADMIN o SUPERADMIN acceso a datos financieros de otros usuarios (RN-12). `FiltroEstadoCuenta` hace que un usuario en `PENDIENTE_VERIFICACION` solo alcance la ruta de verificación de teléfono (RF-07), y que uno suspendido reciba 401 (RF-A03).

## 6. Equivalencias con los insumos

| Informe 1 / Canva | Clase unificada | Cambio |
|---|---|---|
| Usuario (nivelEducativo, fechaRegistro) | `Usuario` | Se elimina `nivelEducativo` (dato innecesario; el avance sale de `ProgresoLeccion`); `fechaRegistro` es `creadoEn` |
| Transaccion | `Movimiento` | Tipo derivado de su categoría; origen derivado de `MovimientoPropuesto` |
| Categoria (limiteMensual) | `Categoria` | El límite pasa a `Presupuesto` por mes |
| Presupuesto (montoTotal, asignaciones) | `Presupuesto` | Una fila por categoría y mes; el total es calculado |
| Alerta | `Notificacion` | Severidad derivada del tipo |
| MetaFinanciera (ahorroMensualPlaneado) | `Meta` + `AbonoMeta` | El ahorro mensual es calculado (F5) |
| Reporte | `Reporte` calculado + `Exportacion` | Solo la exportación persiste |
| Recomendacion (impactoEstimado) | `Recomendacion` calculada | Sin cifra de impacto (D-07) |
| CuentaBancaria (numeroEnmascarado) | `CuentaBancaria` | Solo últimos 4 dígitos |
| EducacionFinanciera | `Leccion` + `ProgresoLeccion` | Relación N:M con avance |
| SincronizacionBancaria.generarTransacciones() | `ServicioBanca.sincronizar()` | Crea propuestos, nunca movimientos (INC-02) |
| Rol SOPORTE/ANALISTA/SUPERADMIN | `Rol` USUARIO/ADMIN/SUPERADMIN | Tres niveles confirmados (D-02) |
