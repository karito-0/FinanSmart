-- =====================================================================
-- FinanSmart · Esquema de base de datos (MySQL 8.0.16 o superior)
-- Fuente de verdad: docs/07-der.md y docs/08-normalizacion.md
-- Sin datos de ejemplo ni credenciales. Los catálogos están en 02_catalogos.sql.
-- Convenciones: tablas y columnas en snake_case; fechas en UTC (RNF-05);
-- montos en DECIMAL(15,2) con pesos enteros (doc 04, política de números).
-- =====================================================================

DROP DATABASE IF EXISTS finansmart;
CREATE DATABASE finansmart
  DEFAULT CHARACTER SET utf8mb4
  DEFAULT COLLATE utf8mb4_0900_ai_ci;
USE finansmart;

-- ---------------------------------------------------------------------
-- 1. Catálogos
-- ---------------------------------------------------------------------
CREATE TABLE rol (
  id          TINYINT UNSIGNED NOT NULL AUTO_INCREMENT,
  codigo      VARCHAR(20)  NOT NULL,
  descripcion VARCHAR(120) NOT NULL,
  PRIMARY KEY (id),
  UNIQUE KEY uk_rol_codigo (codigo)
) ENGINE=InnoDB;

CREATE TABLE plan (
  id                 TINYINT UNSIGNED NOT NULL AUTO_INCREMENT,
  codigo             VARCHAR(20)   NOT NULL,
  nombre             VARCHAR(60)   NOT NULL,
  precio_mensual_cop DECIMAL(15,2) NOT NULL,
  dias_prueba        TINYINT UNSIGNED NOT NULL DEFAULT 0,
  PRIMARY KEY (id),
  UNIQUE KEY uk_plan_codigo (codigo),
  CONSTRAINT ck_plan_precio CHECK (precio_mensual_cop >= 0 AND precio_mensual_cop = TRUNCATE(precio_mensual_cop, 0))
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- 2. Identidad y seguridad
-- ---------------------------------------------------------------------
CREATE TABLE usuario (
  id                     BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  rol_id                 TINYINT UNSIGNED NOT NULL,
  nombre_completo        VARCHAR(120) NOT NULL,
  correo                 VARCHAR(254) NOT NULL,
  correo_verificado_en   DATETIME NULL,
  telefono               VARCHAR(20)  NULL,
  telefono_verificado_en DATETIME NULL,
  fecha_nacimiento       DATE NOT NULL,
  contrasena_hash        VARCHAR(255) NULL,          -- hash adaptativo; nulo si solo usa Google
  google_sub             VARCHAR(64)  NULL,
  estado                 ENUM('PENDIENTE_VERIFICACION','ACTIVO','SUSPENDIDO')
                         NOT NULL DEFAULT 'PENDIENTE_VERIFICACION',
  meta_ahorro_pct        TINYINT UNSIGNED NOT NULL DEFAULT 20,   -- RF-24
  bloqueado_hasta        DATETIME NULL,                           -- RN-11 / F11
  creado_en              DATETIME NOT NULL DEFAULT (UTC_TIMESTAMP()),
  PRIMARY KEY (id),
  UNIQUE KEY uk_usuario_correo (correo),
  UNIQUE KEY uk_usuario_telefono (telefono),
  UNIQUE KEY uk_usuario_google (google_sub),
  KEY ix_usuario_rol (rol_id),
  CONSTRAINT fk_usuario_rol FOREIGN KEY (rol_id) REFERENCES rol (id),
  CONSTRAINT ck_usuario_meta_ahorro CHECK (meta_ahorro_pct BETWEEN 1 AND 100),
  CONSTRAINT ck_usuario_acceso CHECK (contrasena_hash IS NOT NULL OR google_sub IS NOT NULL)
) ENGINE=InnoDB;

CREATE TABLE cuenta_bancaria (
  id                   BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  usuario_id           BIGINT UNSIGNED NOT NULL,
  entidad              VARCHAR(60) NOT NULL,
  ultimos_4            CHAR(4)     NOT NULL,
  tipo                 ENUM('AHORROS','CORRIENTE','BILLETERA','TARJETA') NOT NULL,
  referencia_proveedor VARCHAR(120) NOT NULL,         -- identificador opaco del agregador; nunca credenciales
  estado               ENUM('ACTIVA','ERROR') NOT NULL DEFAULT 'ACTIVA',
  permiso_otorgado_en  DATETIME NOT NULL,
  permiso_vence_en     DATETIME NOT NULL,
  revocado_en          DATETIME NULL,
  PRIMARY KEY (id),
  UNIQUE KEY uk_cuenta_unica (usuario_id, entidad, ultimos_4),
  CONSTRAINT fk_cuenta_usuario FOREIGN KEY (usuario_id) REFERENCES usuario (id) ON DELETE CASCADE,
  CONSTRAINT ck_cuenta_ultimos4 CHECK (ultimos_4 REGEXP '^[0-9]{4}$'),
  CONSTRAINT ck_cuenta_permiso CHECK (permiso_vence_en > permiso_otorgado_en)
) ENGINE=InnoDB;

CREATE TABLE consentimiento (
  id                 BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  usuario_id         BIGINT UNSIGNED NOT NULL,
  cuenta_bancaria_id BIGINT UNSIGNED NULL,
  tipo               ENUM('TERMINOS','TRATAMIENTO_DATOS','PERMISO_BANCARIO') NOT NULL,
  version            VARCHAR(20) NOT NULL,
  aceptado_en        DATETIME NOT NULL DEFAULT (UTC_TIMESTAMP()),
  ip                 VARCHAR(45) NULL,
  PRIMARY KEY (id),
  KEY ix_consent_usuario (usuario_id, tipo),
  CONSTRAINT fk_consent_usuario FOREIGN KEY (usuario_id) REFERENCES usuario (id) ON DELETE CASCADE,
  CONSTRAINT fk_consent_cuenta  FOREIGN KEY (cuenta_bancaria_id) REFERENCES cuenta_bancaria (id) ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE codigo_verificacion (
  id            BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  usuario_id    BIGINT UNSIGNED NOT NULL,
  tipo          ENUM('ACCESO_SMS','VERIFICAR_TELEFONO','VERIFICAR_CORREO','CAMBIO_TELEFONO',
                     'CAMBIO_CORREO','RECUPERAR_CONTRASENA','RECUPERAR_TELEFONO','VINCULAR_GOOGLE') NOT NULL,
  destino       VARCHAR(254) NULL,                    -- solo en cambios de correo o teléfono
  codigo_hash   CHAR(64) NOT NULL,                    -- nunca el código en claro
  intentos      TINYINT UNSIGNED NOT NULL DEFAULT 0,
  creado_en     DATETIME NOT NULL DEFAULT (UTC_TIMESTAMP()),
  vence_en      DATETIME NOT NULL,
  usado_en      DATETIME NULL,
  invalidado_en DATETIME NULL,
  PRIMARY KEY (id),
  KEY ix_codigo_usuario (usuario_id, tipo, creado_en),
  CONSTRAINT fk_codigo_usuario FOREIGN KEY (usuario_id) REFERENCES usuario (id) ON DELETE CASCADE,
  CONSTRAINT ck_codigo_vigencia CHECK (vence_en > creado_en)
) ENGINE=InnoDB;

CREATE TABLE sesion (
  id            BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  usuario_id    BIGINT UNSIGNED NOT NULL,
  token_hash    CHAR(64) NOT NULL,
  dispositivo   VARCHAR(120) NULL,
  ip            VARCHAR(45)  NULL,
  creada_en     DATETIME NOT NULL DEFAULT (UTC_TIMESTAMP()),
  ultimo_uso_en DATETIME NOT NULL DEFAULT (UTC_TIMESTAMP()),
  expira_en     DATETIME NOT NULL,
  cerrada_en    DATETIME NULL,
  PRIMARY KEY (id),
  UNIQUE KEY uk_sesion_token (token_hash),
  KEY ix_sesion_usuario (usuario_id, expira_en),
  CONSTRAINT fk_sesion_usuario FOREIGN KEY (usuario_id) REFERENCES usuario (id) ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE intento_acceso (
  id               BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  usuario_id       BIGINT UNSIGNED NULL,              -- nulo si el correo no existe
  correo_intentado VARCHAR(254) NOT NULL,             -- lo que la persona escribió
  etapa            ENUM('CONTRASENA','GOOGLE','SMS') NOT NULL,
  resultado        ENUM('EXITOSO','CREDENCIALES_INVALIDAS','CODIGO_INCORRECTO','CODIGO_VENCIDO',
                        'BLOQUEADO','SMS_NO_ENVIADO') NOT NULL,
  ip               VARCHAR(45) NULL,
  ocurrido_en      DATETIME NOT NULL DEFAULT (UTC_TIMESTAMP()),
  PRIMARY KEY (id),
  KEY ix_intento_usuario (usuario_id, ocurrido_en),
  KEY ix_intento_correo (correo_intentado, ocurrido_en),
  CONSTRAINT fk_intento_usuario FOREIGN KEY (usuario_id) REFERENCES usuario (id) ON DELETE SET NULL
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- 3. Núcleo financiero
-- ---------------------------------------------------------------------
CREATE TABLE categoria (
  id         BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  usuario_id BIGINT UNSIGNED NULL,                    -- nulo = categoría del sistema
  nombre     VARCHAR(60) NOT NULL,
  tipo       ENUM('INGRESO','GASTO') NOT NULL,
  icono      VARCHAR(16) NULL,                        -- emoji elegido por la persona (Figma)
  PRIMARY KEY (id),
  UNIQUE KEY uk_categoria_nombre ((IFNULL(usuario_id, 0)), tipo, nombre),
  KEY ix_categoria_usuario (usuario_id),
  CONSTRAINT fk_categoria_usuario FOREIGN KEY (usuario_id) REFERENCES usuario (id) ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE movimiento (
  id             BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  usuario_id     BIGINT UNSIGNED NOT NULL,
  categoria_id   BIGINT UNSIGNED NOT NULL,
  monto          DECIMAL(15,2) NOT NULL,
  descripcion    VARCHAR(160) NOT NULL,
  fecha_hora     DATETIME NOT NULL,                   -- UTC; el mes se calcula en America/Bogota (F8)
  creado_en      DATETIME NOT NULL DEFAULT (UTC_TIMESTAMP()),
  actualizado_en DATETIME NOT NULL DEFAULT (UTC_TIMESTAMP()),   -- se actualiza en trg_movimiento_bu
  PRIMARY KEY (id),
  KEY ix_mov_usuario_fecha (usuario_id, fecha_hora),
  KEY ix_mov_categoria_fecha (categoria_id, fecha_hora),
  CONSTRAINT fk_mov_usuario   FOREIGN KEY (usuario_id)   REFERENCES usuario (id)   ON DELETE CASCADE,
  -- CASCADE solo actúa al eliminar la cuenta; borrar una categoría con movimientos lo bloquea trg_categoria_bd (RN-09)
  CONSTRAINT fk_mov_categoria FOREIGN KEY (categoria_id) REFERENCES categoria (id) ON DELETE CASCADE,
  CONSTRAINT ck_mov_monto CHECK (monto > 0 AND monto = TRUNCATE(monto, 0))
) ENGINE=InnoDB;

CREATE TABLE presupuesto (
  id                BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  categoria_id      BIGINT UNSIGNED NOT NULL,
  mes               DATE NOT NULL,                    -- siempre el día 1
  limite_mensual    DECIMAL(15,2) NOT NULL,
  repite_cada_mes   BOOLEAN NOT NULL DEFAULT FALSE,
  umbral_aviso_pct  TINYINT UNSIGNED NOT NULL DEFAULT 80,
  umbral_limite_pct TINYINT UNSIGNED NOT NULL DEFAULT 100,
  alertas_activas   BOOLEAN NOT NULL DEFAULT TRUE,
  PRIMARY KEY (id),
  UNIQUE KEY uk_presupuesto_cat_mes (categoria_id, mes),
  CONSTRAINT fk_presupuesto_categoria FOREIGN KEY (categoria_id) REFERENCES categoria (id) ON DELETE CASCADE,
  CONSTRAINT ck_presupuesto_mes CHECK (DAY(mes) = 1),
  CONSTRAINT ck_presupuesto_limite CHECK (limite_mensual >= 0 AND limite_mensual = TRUNCATE(limite_mensual, 0)),
  CONSTRAINT ck_presupuesto_umbrales CHECK (umbral_aviso_pct >= 1 AND umbral_aviso_pct < umbral_limite_pct AND umbral_limite_pct <= 100)
) ENGINE=InnoDB;

CREATE TABLE meta (
  id             BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  usuario_id     BIGINT UNSIGNED NOT NULL,
  nombre         VARCHAR(80) NOT NULL,
  icono          VARCHAR(16) NULL,
  monto_objetivo DECIMAL(15,2) NOT NULL,
  fecha_objetivo DATE NOT NULL,
  creada_en      DATETIME NOT NULL DEFAULT (UTC_TIMESTAMP()),
  PRIMARY KEY (id),
  KEY ix_meta_usuario (usuario_id),
  CONSTRAINT fk_meta_usuario FOREIGN KEY (usuario_id) REFERENCES usuario (id) ON DELETE CASCADE,
  CONSTRAINT ck_meta_objetivo CHECK (monto_objetivo > 0 AND monto_objetivo = TRUNCATE(monto_objetivo, 0))
) ENGINE=InnoDB;

CREATE TABLE abono_meta (
  id        BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  meta_id   BIGINT UNSIGNED NOT NULL,
  monto     DECIMAL(15,2) NOT NULL,
  fecha     DATE NOT NULL,
  creado_en DATETIME NOT NULL DEFAULT (UTC_TIMESTAMP()),
  PRIMARY KEY (id),
  KEY ix_abono_meta (meta_id, fecha),
  CONSTRAINT fk_abono_meta FOREIGN KEY (meta_id) REFERENCES meta (id) ON DELETE CASCADE,
  CONSTRAINT ck_abono_monto CHECK (monto > 0 AND monto = TRUNCATE(monto, 0))
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- 4. Banca de solo lectura con revisión del usuario (INC-02)
-- ---------------------------------------------------------------------
CREATE TABLE sincronizacion (
  id           BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  usuario_id   BIGINT UNSIGNED NOT NULL,
  ejecutada_en DATETIME NOT NULL DEFAULT (UTC_TIMESTAMP()),
  resultado    ENUM('EXITOSA','PARCIAL','FALLIDA') NOT NULL,
  PRIMARY KEY (id),
  KEY ix_sync_usuario (usuario_id, ejecutada_en),
  CONSTRAINT fk_sync_usuario FOREIGN KEY (usuario_id) REFERENCES usuario (id) ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE movimiento_propuesto (
  id                    BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  cuenta_bancaria_id    BIGINT UNSIGNED NOT NULL,
  sincronizacion_id     BIGINT UNSIGNED NOT NULL,
  categoria_sugerida_id BIGINT UNSIGNED NULL,
  movimiento_id         BIGINT UNSIGNED NULL,
  id_externo            VARCHAR(120) NOT NULL,
  descripcion           VARCHAR(160) NOT NULL,
  monto                 DECIMAL(15,2) NOT NULL,
  tipo                  ENUM('INGRESO','GASTO') NOT NULL,
  fecha_hora            DATETIME NOT NULL,
  estado                ENUM('PENDIENTE','APROBADO','RECHAZADO') NOT NULL DEFAULT 'PENDIENTE',
  revisado_en           DATETIME NULL,
  PRIMARY KEY (id),
  UNIQUE KEY uk_propuesto_externo (cuenta_bancaria_id, id_externo),      -- RF-31
  UNIQUE KEY uk_propuesto_movimiento (movimiento_id),
  KEY ix_propuesto_estado (cuenta_bancaria_id, estado),
  KEY ix_propuesto_sync (sincronizacion_id),
  CONSTRAINT fk_propuesto_cuenta FOREIGN KEY (cuenta_bancaria_id) REFERENCES cuenta_bancaria (id) ON DELETE CASCADE,
  CONSTRAINT fk_propuesto_sync   FOREIGN KEY (sincronizacion_id)  REFERENCES sincronizacion (id) ON DELETE CASCADE,
  CONSTRAINT fk_propuesto_cat    FOREIGN KEY (categoria_sugerida_id) REFERENCES categoria (id) ON DELETE SET NULL,
  CONSTRAINT fk_propuesto_mov    FOREIGN KEY (movimiento_id)      REFERENCES movimiento (id) ON DELETE SET NULL,
  CONSTRAINT ck_propuesto_monto CHECK (monto > 0 AND monto = TRUNCATE(monto, 0))
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- 5. Notificaciones, exportaciones, educación, suscripción
-- ---------------------------------------------------------------------
CREATE TABLE notificacion (
  id              BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  usuario_id      BIGINT UNSIGNED NOT NULL,
  presupuesto_id  BIGINT UNSIGNED NULL,
  tipo            ENUM('ALERTA_AVISO','ALERTA_LIMITE','SINCRONIZACION','META_CUMPLIDA','SEGURIDAD','SISTEMA') NOT NULL,
  periodo         CHAR(7) NULL,                       -- 'AAAA-MM'
  umbral_pct      TINYINT UNSIGNED NULL,              -- umbral vigente al enviar
  mensaje         VARCHAR(255) NOT NULL,
  accion_sugerida VARCHAR(160) NULL,                  -- RF-21
  leida           BOOLEAN NOT NULL DEFAULT FALSE,
  creada_en       DATETIME NOT NULL DEFAULT (UTC_TIMESTAMP()),
  PRIMARY KEY (id),
  UNIQUE KEY uk_alerta_unica (presupuesto_id, periodo, tipo),            -- RN-17
  KEY ix_notif_usuario (usuario_id, leida, creada_en),
  CONSTRAINT fk_notif_usuario     FOREIGN KEY (usuario_id)     REFERENCES usuario (id)     ON DELETE CASCADE,
  CONSTRAINT fk_notif_presupuesto FOREIGN KEY (presupuesto_id) REFERENCES presupuesto (id) ON DELETE CASCADE,
  CONSTRAINT ck_notif_periodo CHECK (periodo IS NULL OR periodo REGEXP '^[0-9]{4}-(0[1-9]|1[0-2])$')
) ENGINE=InnoDB;

CREATE TABLE exportacion (
  id             BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  usuario_id     BIGINT UNSIGNED NOT NULL,
  formato        ENUM('PDF','EXCEL') NOT NULL,
  tipo_reporte   VARCHAR(40) NOT NULL,
  periodo_inicio DATE NOT NULL,
  periodo_fin    DATE NOT NULL,
  estado         ENUM('LISTA','RECHAZADA') NOT NULL,
  archivo_ref    VARCHAR(255) NULL,
  creada_en      DATETIME NOT NULL DEFAULT (UTC_TIMESTAMP()),
  vence_en       DATETIME NULL,
  PRIMARY KEY (id),
  KEY ix_export_usuario (usuario_id, creada_en),
  CONSTRAINT fk_export_usuario FOREIGN KEY (usuario_id) REFERENCES usuario (id) ON DELETE CASCADE,
  CONSTRAINT ck_export_periodo CHECK (periodo_fin >= periodo_inicio)
) ENGINE=InnoDB;

CREATE TABLE leccion (
  id             BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  creada_por     BIGINT UNSIGNED NULL,
  titulo         VARCHAR(120) NOT NULL,
  tema           VARCHAR(60)  NOT NULL,
  nivel          TINYINT UNSIGNED NOT NULL DEFAULT 1,
  minutos        SMALLINT UNSIGNED NOT NULL,
  contenido      MEDIUMTEXT NOT NULL,
  estado         ENUM('BORRADOR','EN_REVISION','PUBLICADA','ARCHIVADA') NOT NULL DEFAULT 'BORRADOR',
  creada_en      DATETIME NOT NULL DEFAULT (UTC_TIMESTAMP()),
  actualizada_en DATETIME NOT NULL DEFAULT (UTC_TIMESTAMP()),   -- se actualiza en trg_leccion_bu
  PRIMARY KEY (id),
  KEY ix_leccion_estado (estado, tema, nivel),
  CONSTRAINT fk_leccion_autor FOREIGN KEY (creada_por) REFERENCES usuario (id) ON DELETE SET NULL
) ENGINE=InnoDB;

CREATE TABLE progreso_leccion (
  usuario_id    BIGINT UNSIGNED NOT NULL,
  leccion_id    BIGINT UNSIGNED NOT NULL,
  completada_en DATETIME NOT NULL DEFAULT (UTC_TIMESTAMP()),
  PRIMARY KEY (usuario_id, leccion_id),
  CONSTRAINT fk_progreso_usuario FOREIGN KEY (usuario_id) REFERENCES usuario (id) ON DELETE CASCADE,
  CONSTRAINT fk_progreso_leccion FOREIGN KEY (leccion_id) REFERENCES leccion (id) ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE suscripcion (
  id           BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  usuario_id   BIGINT UNSIGNED NOT NULL,
  plan_id      TINYINT UNSIGNED NOT NULL,
  estado       ENUM('PRUEBA','ACTIVA','CANCELADA') NOT NULL,
  inicia_en    DATETIME NOT NULL DEFAULT (UTC_TIMESTAMP()),
  prueba_hasta DATETIME NULL,                         -- condición pactada al contratar (doc 08 §6)
  vence_en     DATETIME NULL,
  PRIMARY KEY (id),
  KEY ix_susc_usuario (usuario_id, inicia_en),
  CONSTRAINT fk_susc_usuario FOREIGN KEY (usuario_id) REFERENCES usuario (id) ON DELETE CASCADE,
  CONSTRAINT fk_susc_plan    FOREIGN KEY (plan_id)    REFERENCES plan (id)
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- 6. Auditoría inmutable (RNF-04). Sin claves foráneas a propósito (doc 07).
-- ---------------------------------------------------------------------
CREATE TABLE auditoria (
  id          BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  ocurrido_en DATETIME NOT NULL DEFAULT (UTC_TIMESTAMP()),
  actor_id    BIGINT UNSIGNED NULL,
  actor_rol   ENUM('USUARIO','ADMIN','SUPERADMIN','SISTEMA') NOT NULL,
  accion      VARCHAR(60) NOT NULL,
  objeto_tipo VARCHAR(40) NULL,
  objeto_id   BIGINT UNSIGNED NULL,
  detalle     JSON NULL,
  ip          VARCHAR(45) NULL,
  PRIMARY KEY (id),
  KEY ix_audit_fecha (ocurrido_en),
  KEY ix_audit_actor (actor_id, ocurrido_en),
  KEY ix_audit_accion (accion, ocurrido_en)
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- 7. Reglas que MySQL no permite como CHECK (columnas con acciones referenciales
--    o consultas a otras tablas). Mensajes con el ID de la regla de negocio.
-- ---------------------------------------------------------------------
DELIMITER $$

CREATE TRIGGER trg_usuario_bi BEFORE INSERT ON usuario FOR EACH ROW
BEGIN
  IF NEW.fecha_nacimiento > DATE_SUB(UTC_DATE(), INTERVAL 18 YEAR) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RN-04: solo se permiten personas mayores de 18 años';
  END IF;
END$$

CREATE TRIGGER trg_usuario_bu BEFORE UPDATE ON usuario FOR EACH ROW
BEGIN
  IF NOT (NEW.fecha_nacimiento <=> OLD.fecha_nacimiento) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RF-14: la fecha de nacimiento no se puede modificar';
  END IF;
END$$

CREATE TRIGGER trg_consentimiento_bi BEFORE INSERT ON consentimiento FOR EACH ROW
BEGIN
  IF (NEW.tipo = 'PERMISO_BANCARIO') <> (NEW.cuenta_bancaria_id IS NOT NULL) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RF-28: solo el permiso bancario se asocia a una cuenta bancaria';
  END IF;
END$$

-- Los borrados en cascada (eliminar la cuenta) NO activan disparadores; un borrado directo sí.
CREATE TRIGGER trg_categoria_bd BEFORE DELETE ON categoria FOR EACH ROW
BEGIN
  IF EXISTS (SELECT 1 FROM movimiento WHERE categoria_id = OLD.id) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RN-09: reasigna los movimientos antes de eliminar la categoría';
  END IF;
END$$

CREATE TRIGGER trg_movimiento_bi BEFORE INSERT ON movimiento FOR EACH ROW
BEGIN
  -- Un movimiento nuevo usa una categoría propia; «Sin categoría» solo sirve para reasignar (INC-12)
  IF NOT EXISTS (SELECT 1 FROM categoria WHERE id = NEW.categoria_id AND usuario_id = NEW.usuario_id) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RF-17: la categoría debe pertenecer al mismo usuario';
  END IF;
END$$

CREATE TRIGGER trg_movimiento_bu BEFORE UPDATE ON movimiento FOR EACH ROW
BEGIN
  SET NEW.actualizado_en = UTC_TIMESTAMP();
  IF NOT EXISTS (SELECT 1 FROM categoria WHERE id = NEW.categoria_id AND (usuario_id IS NULL OR usuario_id = NEW.usuario_id)) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RF-17: la categoría debe ser del mismo usuario o del sistema';
  END IF;
END$$

CREATE TRIGGER trg_presupuesto_bi BEFORE INSERT ON presupuesto FOR EACH ROW
BEGIN
  IF NOT EXISTS (SELECT 1 FROM categoria WHERE id = NEW.categoria_id AND tipo = 'GASTO' AND usuario_id IS NOT NULL) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RF-19: el presupuesto solo aplica a categorías de GASTO del usuario';
  END IF;
END$$

CREATE TRIGGER trg_presupuesto_bu BEFORE UPDATE ON presupuesto FOR EACH ROW
BEGIN
  IF NOT EXISTS (SELECT 1 FROM categoria WHERE id = NEW.categoria_id AND tipo = 'GASTO' AND usuario_id IS NOT NULL) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RF-19: el presupuesto solo aplica a categorías de GASTO del usuario';
  END IF;
END$$

CREATE TRIGGER trg_propuesto_bi BEFORE INSERT ON movimiento_propuesto FOR EACH ROW
BEGIN
  IF NEW.movimiento_id IS NOT NULL AND NEW.estado <> 'APROBADO' THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RF-30: un propuesto enlazado a un movimiento debe estar APROBADO';
  END IF;
END$$

CREATE TRIGGER trg_propuesto_bu BEFORE UPDATE ON movimiento_propuesto FOR EACH ROW
BEGIN
  IF NEW.movimiento_id IS NOT NULL AND NEW.estado <> 'APROBADO' THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RF-30: un propuesto enlazado a un movimiento debe estar APROBADO';
  END IF;
END$$

CREATE TRIGGER trg_leccion_bu BEFORE UPDATE ON leccion FOR EACH ROW
BEGIN
  SET NEW.actualizada_en = UTC_TIMESTAMP();
END$$

CREATE TRIGGER trg_auditoria_bu BEFORE UPDATE ON auditoria FOR EACH ROW
BEGIN
  SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RNF-04: la auditoría es inmutable (solo inserción)';
END$$

CREATE TRIGGER trg_auditoria_bd BEFORE DELETE ON auditoria FOR EACH ROW
BEGIN
  SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RNF-04: la auditoría es inmutable (solo inserción)';
END$$

DELIMITER ;

-- ---------------------------------------------------------------------
-- 8. Vista de apoyo: el origen y el tipo del movimiento se DEDUCEN (doc 08 §1)
-- ---------------------------------------------------------------------
CREATE VIEW v_movimiento AS
SELECT m.id, m.usuario_id, m.categoria_id, c.tipo, m.monto, m.descripcion, m.fecha_hora,
       IF(p.id IS NULL, 'MANUAL', 'BANCO') AS origen,
       p.cuenta_bancaria_id
FROM movimiento m
JOIN categoria c ON c.id = m.categoria_id
LEFT JOIN movimiento_propuesto p ON p.movimiento_id = m.id;
