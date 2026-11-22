#!/usr/bin/env bash
# Verifica los privilegios mínimos del usuario de la aplicación (RNF-04, RNF-14).
# Crea el usuario con una contraseña aleatoria que no se guarda y lo elimina al terminar.
# Uso: bash database/pruebas/permisos.sh   (desde la raíz del repositorio)
ROOT=${MYSQL_CMD:-"mysql -uroot --default-character-set=utf8mb4"}
PWD_APP="$(openssl rand -hex 12)"
(echo "SET @app_pwd='$PWD_APP';"; cat database/03_permisos.sql) | $ROOT || { echo "No se pudo crear el usuario"; exit 1; }
APP="mysql -h127.0.0.1 -ufinansmart_app --default-character-set=utf8mb4 finansmart"   # la clave va por MYSQL_PWD solo en cada llamada de la app
OK=0; MAL=0
# prueba NOMBRE (permite|niega) SQL
p() {
  local salida; salida=$(MYSQL_PWD="$PWD_APP" $APP -e "$3" 2>&1); local rc=$?
  if [[ "$2" == "permite" && $rc -eq 0 ]] || [[ "$2" == "niega" && $rc -ne 0 && "$salida" == *"denied"* ]]; then
    echo "OK    $1"; OK=$((OK+1))
  else echo "FALLA $1 (esperaba que $2): $salida"; MAL=$((MAL+1)); fi
}
p "Leer usuarios"                         permite "SELECT COUNT(*) FROM usuario;"
p "Leer movimientos"                      permite "SELECT 1 FROM movimiento LIMIT 1;"
p "Leer la vista v_movimiento"            permite "SELECT COUNT(*) FROM v_movimiento;"
p "Insertar en auditoría"                 permite "INSERT INTO auditoria (actor_rol,accion) VALUES ('SISTEMA','PRUEBA_PERMISOS');"
p "UPDATE sobre auditoría"                niega   "UPDATE auditoria SET accion='x';"
p "DELETE sobre auditoría"                niega   "DELETE FROM auditoria;"
p "INSERT en el catálogo rol"             niega   "INSERT INTO rol (codigo,descripcion) VALUES ('X','x');"
p "UPDATE en el catálogo plan"            niega   "UPDATE plan SET precio_mensual_cop=1;"
p "DROP TABLE"                            niega   "DROP TABLE auditoria;"
p "CREATE TABLE"                          niega   "CREATE TABLE t (id INT);"
p "DROP TRIGGER (quitar la inmutabilidad)" niega  "DROP TRIGGER trg_auditoria_bu;"
$ROOT -e "DROP USER 'finansmart_app'@'%';"
echo; echo "Resultado: $OK correctas, $MAL fallidas"; [[ $MAL -eq 0 ]]
