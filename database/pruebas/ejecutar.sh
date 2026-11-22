#!/usr/bin/env bash
# Pruebas de integridad de la base de datos (doc 07 §2). Cada prueba corre dentro de una
# transacción que se descarta: no deja datos. Requiere haber ejecutado 01_schema.sql y 02_catalogos.sql.
# Uso: bash database/pruebas/ejecutar.sh        (variable opcional MYSQL_CMD, por defecto "mysql -uroot")
MYSQL_CMD=${MYSQL_CMD:-"mysql -uroot --default-character-set=utf8mb4"}
OK=0; MAL=0

read -r -d '' SETUP <<'SQL'
USE finansmart; START TRANSACTION;
INSERT INTO usuario (rol_id,nombre_completo,correo,telefono,fecha_nacimiento,contrasena_hash,estado)
  VALUES (1,'Prueba Uno','t1@example.test','+573000000001','1995-05-05','hash','ACTIVO');
SET @u = LAST_INSERT_ID();
INSERT INTO usuario (rol_id,nombre_completo,correo,telefono,fecha_nacimiento,contrasena_hash,estado)
  VALUES (1,'Prueba Dos','t2@example.test','+573000000002','1990-01-01','hash','ACTIVO');
SET @u2 = LAST_INSERT_ID();
INSERT INTO categoria (usuario_id,nombre,tipo) VALUES (@u,'Alimentación','GASTO');  SET @cg = LAST_INSERT_ID();
INSERT INTO categoria (usuario_id,nombre,tipo) VALUES (@u,'Salario','INGRESO');     SET @ci = LAST_INSERT_ID();
INSERT INTO categoria (usuario_id,nombre,tipo) VALUES (@u2,'Transporte','GASTO');   SET @cg2 = LAST_INSERT_ID();
SET @sis_g = (SELECT id FROM categoria WHERE usuario_id IS NULL AND tipo='GASTO');
SQL

# t NOMBRE ESPERA(FALLA|OK) FRAGMENTO  <<SQL ... SQL
t() {
  local nombre="$1" espera="$2" frag="$3" sql salida rc
  sql="$(cat)"
  salida=$($MYSQL_CMD -e "$SETUP $sql ROLLBACK;" 2>&1); rc=$?
  if [[ "$espera" == "OK1" ]]; then
    if [[ $rc -eq 0 && "$(echo "$salida" | tail -n 1)" == "1" ]]; then echo "OK    $nombre"; OK=$((OK+1)); else echo "FALLA $nombre (la comprobación final no devolvió 1): rc=$rc $salida"; MAL=$((MAL+1)); fi
  elif [[ "$espera" == "OK" ]]; then
    if [[ $rc -eq 0 ]]; then echo "OK    $nombre"; OK=$((OK+1)); else echo "FALLA $nombre (esperaba éxito): $salida"; MAL=$((MAL+1)); fi
  else
    if [[ $rc -ne 0 && "$salida" == *"$frag"* ]]; then echo "OK    $nombre (rechazado: $frag)"; OK=$((OK+1))
    else echo "FALLA $nombre (esperaba error con «$frag»): rc=$rc $salida"; MAL=$((MAL+1)); fi
  fi
}

# ---- Usuarios y seguridad
t "RN-04 menor de edad no se registra" FALLA "RN-04" <<'SQL'
INSERT INTO usuario (rol_id,nombre_completo,correo,fecha_nacimiento,contrasena_hash) VALUES (1,'Menor','m@example.test',DATE_SUB(UTC_DATE(), INTERVAL 17 YEAR),'h');
SQL
t "RN-04 exactamente 18 años sí se registra" OK "" <<'SQL'
INSERT INTO usuario (rol_id,nombre_completo,correo,fecha_nacimiento,contrasena_hash) VALUES (1,'Mayor','a@example.test',DATE_SUB(UTC_DATE(), INTERVAL 18 YEAR),'h');
SQL
t "Cuenta sin contraseña ni Google se rechaza" FALLA "ck_usuario_acceso" <<'SQL'
INSERT INTO usuario (rol_id,nombre_completo,correo,fecha_nacimiento) VALUES (1,'Sin acceso','s@example.test','1990-01-01');
SQL
t "Cuenta solo con Google sí es válida" OK "" <<'SQL'
INSERT INTO usuario (rol_id,nombre_completo,correo,fecha_nacimiento,google_sub) VALUES (1,'Con Google','g@example.test','1990-01-01','sub123');
SQL
t "RF-14 fecha de nacimiento no editable" FALLA "RF-14" <<'SQL'
UPDATE usuario SET fecha_nacimiento='1996-06-06' WHERE id=@u;
SQL
t "Correo duplicado (sin distinguir mayúsculas)" FALLA "Duplicate" <<'SQL'
INSERT INTO usuario (rol_id,nombre_completo,correo,fecha_nacimiento,contrasena_hash) VALUES (1,'Otro','T1@EXAMPLE.TEST','1990-01-01','h');
SQL
t "Teléfono duplicado" FALLA "Duplicate" <<'SQL'
INSERT INTO usuario (rol_id,nombre_completo,correo,telefono,fecha_nacimiento,contrasena_hash) VALUES (1,'Otro','o@example.test','+573000000001','1990-01-01','h');
SQL
t "Meta de ahorro fuera de 1-100" FALLA "ck_usuario_meta_ahorro" <<'SQL'
UPDATE usuario SET meta_ahorro_pct=0 WHERE id=@u;
SQL
t "Rol inexistente" FALLA "foreign key" <<'SQL'
INSERT INTO usuario (rol_id,nombre_completo,correo,fecha_nacimiento,contrasena_hash) VALUES (99,'X','x@example.test','1990-01-01','h');
SQL
t "RF-28 permiso bancario sin cuenta" FALLA "RF-28" <<'SQL'
INSERT INTO consentimiento (usuario_id,tipo,version) VALUES (@u,'PERMISO_BANCARIO','1.0');
SQL
t "Cuenta bancaria con últimos 4 inválidos" FALLA "ck_cuenta_ultimos4" <<'SQL'
INSERT INTO cuenta_bancaria (usuario_id,entidad,ultimos_4,tipo,referencia_proveedor,permiso_otorgado_en,permiso_vence_en) VALUES (@u,'Banco','12ab','AHORROS','ref','2026-01-01','2026-04-01');
SQL
t "Permiso bancario con vencimiento anterior al otorgamiento" FALLA "ck_cuenta_permiso" <<'SQL'
INSERT INTO cuenta_bancaria (usuario_id,entidad,ultimos_4,tipo,referencia_proveedor,permiso_otorgado_en,permiso_vence_en) VALUES (@u,'Banco','1234','AHORROS','ref','2026-04-01','2026-01-01');
SQL

# ---- Categorías
t "Categoría duplicada (mismo usuario, tipo y nombre sin acentos/mayúsculas)" FALLA "Duplicate" <<'SQL'
INSERT INTO categoria (usuario_id,nombre,tipo) VALUES (@u,'alimentacion','GASTO');
SQL
t "Mismo nombre en otro tipo sí se permite" OK "" <<'SQL'
INSERT INTO categoria (usuario_id,nombre,tipo) VALUES (@u,'Alimentación','INGRESO');
SQL
t "Categoría del sistema duplicada (usuario nulo)" FALLA "Duplicate" <<'SQL'
INSERT INTO categoria (usuario_id,nombre,tipo) VALUES (NULL,'Sin categoría','GASTO');
SQL

# ---- Movimientos
t "RF-17 monto cero" FALLA "ck_mov_monto" <<'SQL'
INSERT INTO movimiento (usuario_id,categoria_id,monto,descripcion,fecha_hora) VALUES (@u,@cg,0,'x',UTC_TIMESTAMP());
SQL
t "RNF-05 monto con centavos" FALLA "ck_mov_monto" <<'SQL'
INSERT INTO movimiento (usuario_id,categoria_id,monto,descripcion,fecha_hora) VALUES (@u,@cg,10.50,'x',UTC_TIMESTAMP());
SQL
t "RF-17 monto negativo" FALLA "ck_mov_monto" <<'SQL'
INSERT INTO movimiento (usuario_id,categoria_id,monto,descripcion,fecha_hora) VALUES (@u,@cg,-5,'x',UTC_TIMESTAMP());
SQL
t "Movimiento válido de 28.000" OK "" <<'SQL'
INSERT INTO movimiento (usuario_id,categoria_id,monto,descripcion,fecha_hora) VALUES (@u,@cg,28000,'Almuerzo',UTC_TIMESTAMP());
SQL
t "Movimiento con categoría de otro usuario" FALLA "RF-17" <<'SQL'
INSERT INTO movimiento (usuario_id,categoria_id,monto,descripcion,fecha_hora) VALUES (@u,@cg2,1000,'x',UTC_TIMESTAMP());
SQL
t "Movimiento nuevo con «Sin categoría»" FALLA "RF-17" <<'SQL'
INSERT INTO movimiento (usuario_id,categoria_id,monto,descripcion,fecha_hora) VALUES (@u,@sis_g,1000,'x',UTC_TIMESTAMP());
SQL
t "RN-09 reasignar movimiento a «Sin categoría» sí se permite" OK "" <<'SQL'
INSERT INTO movimiento (usuario_id,categoria_id,monto,descripcion,fecha_hora) VALUES (@u,@cg,1000,'x',UTC_TIMESTAMP());
UPDATE movimiento SET categoria_id=@sis_g WHERE usuario_id=@u;
SQL
t "Reasignar movimiento a categoría de otro usuario" FALLA "RF-17" <<'SQL'
INSERT INTO movimiento (usuario_id,categoria_id,monto,descripcion,fecha_hora) VALUES (@u,@cg,1000,'x',UTC_TIMESTAMP());
UPDATE movimiento SET categoria_id=@cg2 WHERE usuario_id=@u;
SQL
t "RN-09 no se elimina categoría con movimientos" FALLA "RN-09" <<'SQL'
INSERT INTO movimiento (usuario_id,categoria_id,monto,descripcion,fecha_hora) VALUES (@u,@cg,1000,'x',UTC_TIMESTAMP());
DELETE FROM categoria WHERE id=@cg;
SQL

# ---- Presupuestos
t "Presupuesto válido" OK "" <<'SQL'
INSERT INTO presupuesto (categoria_id,mes,limite_mensual) VALUES (@cg,'2026-11-01',200000);
SQL
t "RF-19 presupuesto sobre categoría de INGRESO" FALLA "RF-19" <<'SQL'
INSERT INTO presupuesto (categoria_id,mes,limite_mensual) VALUES (@ci,'2026-11-01',200000);
SQL
t "RF-19 presupuesto sobre «Sin categoría»" FALLA "RF-19" <<'SQL'
INSERT INTO presupuesto (categoria_id,mes,limite_mensual) VALUES (@sis_g,'2026-11-01',200000);
SQL
t "Presupuesto con mes que no es día 1" FALLA "ck_presupuesto_mes" <<'SQL'
INSERT INTO presupuesto (categoria_id,mes,limite_mensual) VALUES (@cg,'2026-11-15',200000);
SQL
t "Umbrales invertidos (90 aviso, 80 límite)" FALLA "ck_presupuesto_umbrales" <<'SQL'
INSERT INTO presupuesto (categoria_id,mes,limite_mensual,umbral_aviso_pct,umbral_limite_pct) VALUES (@cg,'2026-11-01',200000,90,80);
SQL
t "Umbral de límite mayor a 100" FALLA "ck_presupuesto_umbrales" <<'SQL'
INSERT INTO presupuesto (categoria_id,mes,limite_mensual,umbral_limite_pct) VALUES (@cg,'2026-11-01',200000,120);
SQL
t "Límite cero es válido (RN-07)" OK "" <<'SQL'
INSERT INTO presupuesto (categoria_id,mes,limite_mensual) VALUES (@cg,'2026-11-01',0);
SQL
t "Presupuesto duplicado para categoría y mes" FALLA "Duplicate" <<'SQL'
INSERT INTO presupuesto (categoria_id,mes,limite_mensual) VALUES (@cg,'2026-11-01',1);
INSERT INTO presupuesto (categoria_id,mes,limite_mensual) VALUES (@cg,'2026-11-01',2);
SQL
t "Eliminar categoría sin movimientos borra sus presupuestos (RN-09)" OK1 "" <<'SQL'
INSERT INTO presupuesto (categoria_id,mes,limite_mensual) VALUES (@cg,'2026-11-01',1000);
DELETE FROM categoria WHERE id=@cg;
SELECT (SELECT COUNT(*) FROM presupuesto WHERE categoria_id=@cg)=0 AS ok;
SQL

# ---- Metas
t "Meta con objetivo cero" FALLA "ck_meta_objetivo" <<'SQL'
INSERT INTO meta (usuario_id,nombre,monto_objetivo,fecha_objetivo) VALUES (@u,'Laptop',0,'2027-03-31');
SQL
t "Abono negativo" FALLA "ck_abono_monto" <<'SQL'
INSERT INTO meta (usuario_id,nombre,monto_objetivo,fecha_objetivo) VALUES (@u,'Laptop',2000000,'2027-03-31'); SET @m=LAST_INSERT_ID();
INSERT INTO abono_meta (meta_id,monto,fecha) VALUES (@m,-1,'2026-11-17');
SQL
t "Meta y abono válidos" OK "" <<'SQL'
INSERT INTO meta (usuario_id,nombre,monto_objetivo,fecha_objetivo) VALUES (@u,'Laptop',2000000,'2027-03-31'); SET @m=LAST_INSERT_ID();
INSERT INTO abono_meta (meta_id,monto,fecha) VALUES (@m,700000,'2026-11-17');
SQL

# ---- Banca
CUENTA="INSERT INTO cuenta_bancaria (usuario_id,entidad,ultimos_4,tipo,referencia_proveedor,permiso_otorgado_en,permiso_vence_en) VALUES (@u,'Bancolombia','1234','AHORROS','ref','2026-11-01','2027-02-01'); SET @cb=LAST_INSERT_ID();
INSERT INTO sincronizacion (usuario_id,resultado) VALUES (@u,'EXITOSA'); SET @sy=LAST_INSERT_ID();"
t "RF-31 no se propone dos veces el mismo movimiento bancario" FALLA "Duplicate" <<SQL
$CUENTA
INSERT INTO movimiento_propuesto (cuenta_bancaria_id,sincronizacion_id,id_externo,descripcion,monto,tipo,fecha_hora) VALUES (@cb,@sy,'abc','Compra',5000,'GASTO',UTC_TIMESTAMP());
INSERT INTO movimiento_propuesto (cuenta_bancaria_id,sincronizacion_id,id_externo,descripcion,monto,tipo,fecha_hora) VALUES (@cb,@sy,'abc','Compra',5000,'GASTO',UTC_TIMESTAMP());
SQL
t "RF-30 propuesto enlazado a movimiento debe estar APROBADO" FALLA "RF-30" <<SQL
$CUENTA
INSERT INTO movimiento (usuario_id,categoria_id,monto,descripcion,fecha_hora) VALUES (@u,@cg,5000,'Compra',UTC_TIMESTAMP()); SET @mv=LAST_INSERT_ID();
INSERT INTO movimiento_propuesto (cuenta_bancaria_id,sincronizacion_id,movimiento_id,id_externo,descripcion,monto,tipo,fecha_hora,estado) VALUES (@cb,@sy,@mv,'abc','Compra',5000,'GASTO',UTC_TIMESTAMP(),'PENDIENTE');
SQL
t "Aprobar crea movimiento; el origen se deduce como BANCO" OK1 "" <<SQL
$CUENTA
INSERT INTO movimiento (usuario_id,categoria_id,monto,descripcion,fecha_hora) VALUES (@u,@cg,5000,'Compra',UTC_TIMESTAMP()); SET @mv=LAST_INSERT_ID();
INSERT INTO movimiento (usuario_id,categoria_id,monto,descripcion,fecha_hora) VALUES (@u,@cg,7000,'Manual',UTC_TIMESTAMP());
INSERT INTO movimiento_propuesto (cuenta_bancaria_id,sincronizacion_id,movimiento_id,id_externo,descripcion,monto,tipo,fecha_hora,estado) VALUES (@cb,@sy,@mv,'abc','Compra',5000,'GASTO',UTC_TIMESTAMP(),'APROBADO');
SELECT (SELECT origen FROM v_movimiento WHERE id=@mv)='BANCO' AND (SELECT COUNT(*) FROM v_movimiento WHERE usuario_id=@u AND origen='MANUAL')=1 AS ok;
SQL
t "Borrar el movimiento aprobado deja el propuesto APROBADO (no se reimporta)" OK1 "" <<SQL
$CUENTA
INSERT INTO movimiento (usuario_id,categoria_id,monto,descripcion,fecha_hora) VALUES (@u,@cg,5000,'Compra',UTC_TIMESTAMP()); SET @mv=LAST_INSERT_ID();
INSERT INTO movimiento_propuesto (cuenta_bancaria_id,sincronizacion_id,movimiento_id,id_externo,descripcion,monto,tipo,fecha_hora,estado) VALUES (@cb,@sy,@mv,'abc','Compra',5000,'GASTO',UTC_TIMESTAMP(),'APROBADO');
DELETE FROM movimiento WHERE id=@mv;
SELECT (SELECT estado FROM movimiento_propuesto WHERE id_externo='abc')='APROBADO' AND (SELECT movimiento_id FROM movimiento_propuesto WHERE id_externo='abc') IS NULL AS ok;
SQL

# ---- Notificaciones
PRES="INSERT INTO presupuesto (categoria_id,mes,limite_mensual) VALUES (@cg,'2026-11-01',200000); SET @pr=LAST_INSERT_ID();"
t "RN-17 una sola alerta por umbral, categoría y mes" FALLA "Duplicate" <<SQL
$PRES
INSERT INTO notificacion (usuario_id,presupuesto_id,tipo,periodo,umbral_pct,mensaje) VALUES (@u,@pr,'ALERTA_AVISO','2026-11',80,'Llegaste al 80 %');
INSERT INTO notificacion (usuario_id,presupuesto_id,tipo,periodo,umbral_pct,mensaje) VALUES (@u,@pr,'ALERTA_AVISO','2026-11',80,'Otra vez');
SQL
t "Alerta de otro umbral el mismo mes sí se permite" OK "" <<SQL
$PRES
INSERT INTO notificacion (usuario_id,presupuesto_id,tipo,periodo,umbral_pct,mensaje) VALUES (@u,@pr,'ALERTA_AVISO','2026-11',80,'80 %');
INSERT INTO notificacion (usuario_id,presupuesto_id,tipo,periodo,umbral_pct,mensaje) VALUES (@u,@pr,'ALERTA_LIMITE','2026-11',100,'100 %');
SQL
t "Periodo de notificación inválido (2026-13)" FALLA "ck_notif_periodo" <<SQL
INSERT INTO notificacion (usuario_id,tipo,periodo,mensaje) VALUES (@u,'SISTEMA','2026-13','x');
SQL
t "Notificaciones del sistema sin presupuesto se repiten sin conflicto" OK "" <<SQL
INSERT INTO notificacion (usuario_id,tipo,mensaje) VALUES (@u,'SEGURIDAD','a');
INSERT INTO notificacion (usuario_id,tipo,mensaje) VALUES (@u,'SEGURIDAD','a');
SQL
t "Exportación con periodo invertido" FALLA "ck_export_periodo" <<SQL
INSERT INTO exportacion (usuario_id,formato,tipo_reporte,periodo_inicio,periodo_fin,estado) VALUES (@u,'PDF','resumen','2026-11-30','2026-11-01','LISTA');
SQL

# ---- Auditoría inmutable y eliminación de cuenta
t "RNF-04 insertar en auditoría sí" OK "" <<SQL
INSERT INTO auditoria (actor_id,actor_rol,accion) VALUES (@u,'USUARIO','LOGIN');
SQL
t "RNF-04 no se puede modificar la auditoría" FALLA "RNF-04" <<SQL
INSERT INTO auditoria (actor_id,actor_rol,accion) VALUES (@u,'USUARIO','LOGIN');
UPDATE auditoria SET accion='OTRA' WHERE actor_id=@u;
SQL
t "RNF-04 no se puede borrar la auditoría" FALLA "RNF-04" <<SQL
INSERT INTO auditoria (actor_id,actor_rol,accion) VALUES (@u,'USUARIO','LOGIN');
DELETE FROM auditoria WHERE actor_id=@u;
SQL
t "Eliminar usuario borra sus datos pero conserva la auditoría" OK1 "" <<SQL
INSERT INTO movimiento (usuario_id,categoria_id,monto,descripcion,fecha_hora) VALUES (@u,@cg,5000,'x',UTC_TIMESTAMP());
INSERT INTO meta (usuario_id,nombre,monto_objetivo,fecha_objetivo) VALUES (@u,'M',1000,'2027-01-01');
INSERT INTO sesion (usuario_id,token_hash,expira_en) VALUES (@u,REPEAT('a',64),DATE_ADD(UTC_TIMESTAMP(),INTERVAL 1 DAY));
INSERT INTO auditoria (actor_id,actor_rol,accion) VALUES (@u,'USUARIO','CUENTA_ELIMINADA');
DELETE FROM usuario WHERE id=@u;
SELECT (SELECT COUNT(*) FROM movimiento WHERE usuario_id=@u)=0 AND (SELECT COUNT(*) FROM categoria WHERE usuario_id=@u)=0 AND (SELECT COUNT(*) FROM meta WHERE usuario_id=@u)=0 AND (SELECT COUNT(*) FROM sesion WHERE usuario_id=@u)=0 AND (SELECT COUNT(*) FROM auditoria WHERE actor_id=@u)=1 AS ok;
SQL

# ---- Catálogos
t "Catálogos mínimos presentes y sin datos de ejemplo" OK1 "" <<SQL
SELECT (SELECT COUNT(*) FROM rol)=3 AND (SELECT COUNT(*) FROM plan)=2 AND (SELECT COUNT(*) FROM categoria WHERE usuario_id IS NULL)=2 AND (SELECT COUNT(*) FROM usuario WHERE correo NOT LIKE '%@example.test')=0 AND (SELECT COUNT(*) FROM leccion)=0 AS ok;
SQL

echo; echo "Resultado: $OK correctas, $MAL fallidas"
[[ $MAL -eq 0 ]]
