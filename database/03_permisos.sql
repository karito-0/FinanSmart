-- =====================================================================
-- FinanSmart · Usuario de la aplicación con privilegios mínimos (RNF-04, RNF-14).
-- La contraseña NUNCA se escribe en este archivo. Se pasa en la misma sesión:
--
--   (echo "SET @app_pwd='$DB_APP_PASSWORD';"; cat database/03_permisos.sql) | mysql -u root -p
--
-- DB_APP_PASSWORD es una variable de entorno (nunca se guarda en el repositorio).
--
-- IMPORTANTE: MySQL no permite quitar (REVOKE) un privilegio de tabla concedido a nivel de
-- base de datos, por eso los privilegios se conceden tabla por tabla.
-- Si agregas una tabla en 01_schema.sql, agrégala aquí y en pruebas/permisos.sh.
-- =====================================================================
USE finansmart;

SET @sql = CONCAT("CREATE USER IF NOT EXISTS 'finansmart_app'@'%' IDENTIFIED BY '", REPLACE(@app_pwd, "'", "''"), "'");
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

-- Tablas de la aplicación: lectura y escritura
GRANT SELECT, INSERT, UPDATE, DELETE ON finansmart.usuario              TO 'finansmart_app'@'%';
GRANT SELECT, INSERT, UPDATE, DELETE ON finansmart.consentimiento       TO 'finansmart_app'@'%';
GRANT SELECT, INSERT, UPDATE, DELETE ON finansmart.codigo_verificacion  TO 'finansmart_app'@'%';
GRANT SELECT, INSERT, UPDATE, DELETE ON finansmart.sesion               TO 'finansmart_app'@'%';
GRANT SELECT, INSERT, UPDATE, DELETE ON finansmart.intento_acceso       TO 'finansmart_app'@'%';
GRANT SELECT, INSERT, UPDATE, DELETE ON finansmart.categoria            TO 'finansmart_app'@'%';
GRANT SELECT, INSERT, UPDATE, DELETE ON finansmart.movimiento           TO 'finansmart_app'@'%';
GRANT SELECT, INSERT, UPDATE, DELETE ON finansmart.presupuesto          TO 'finansmart_app'@'%';
GRANT SELECT, INSERT, UPDATE, DELETE ON finansmart.meta                 TO 'finansmart_app'@'%';
GRANT SELECT, INSERT, UPDATE, DELETE ON finansmart.abono_meta           TO 'finansmart_app'@'%';
GRANT SELECT, INSERT, UPDATE, DELETE ON finansmart.cuenta_bancaria      TO 'finansmart_app'@'%';
GRANT SELECT, INSERT, UPDATE, DELETE ON finansmart.sincronizacion       TO 'finansmart_app'@'%';
GRANT SELECT, INSERT, UPDATE, DELETE ON finansmart.movimiento_propuesto TO 'finansmart_app'@'%';
GRANT SELECT, INSERT, UPDATE, DELETE ON finansmart.notificacion         TO 'finansmart_app'@'%';
GRANT SELECT, INSERT, UPDATE, DELETE ON finansmart.exportacion          TO 'finansmart_app'@'%';
GRANT SELECT, INSERT, UPDATE, DELETE ON finansmart.leccion              TO 'finansmart_app'@'%';
GRANT SELECT, INSERT, UPDATE, DELETE ON finansmart.progreso_leccion     TO 'finansmart_app'@'%';
GRANT SELECT, INSERT, UPDATE, DELETE ON finansmart.suscripcion          TO 'finansmart_app'@'%';

-- Auditoría: solo insertar y consultar (RNF-04)
GRANT SELECT, INSERT ON finansmart.auditoria TO 'finansmart_app'@'%';

-- Catálogos y vista: solo lectura (los catálogos no se modifican desde la aplicación)
GRANT SELECT ON finansmart.rol          TO 'finansmart_app'@'%';
GRANT SELECT ON finansmart.plan         TO 'finansmart_app'@'%';
GRANT SELECT ON finansmart.v_movimiento TO 'finansmart_app'@'%';
