# FinanSmart

Aplicación web responsive de organización financiera personal para jóvenes profesionales y familias en Colombia (español de Colombia, COP, fechas DD/MM/AAAA).

> **Orientación, no asesoría.** El contenido y las recomendaciones de FinanSmart no constituyen asesoría financiera.

## Estado
Documentación de análisis y diseño por fases:

| Fase | Entregables | Estado |
|---|---|---|
| A | 1 Resumen y decisiones · 2 Enfoque sistémico · 3 Requisitos | Publicada |
| B | 4 Lógica matemática · 5 Casos de uso · 6 Clases · 7 DER · 8 Normalización | En revisión (PR `docs/fase-b`) |
| C | 9 SQL · 10 Estructura y API · 11 Pantallas · 12 Génesis del proyecto | En revisión (PR `docs/fase-c`, depende de la fase B) |

El código de la aplicación (backend y pantallas) aún no existe: hay esqueleto, esquema de base de datos probado y el módulo Génesis.
Los puntos abiertos que necesitan decisión del cliente están en `docs/01-resumen-y-decisiones.md` (PA-xx).

## Stack
Front: HTML, CSS, JavaScript (fetch) · Back: Java 17, Spring Boot, Spring Security, API REST JSON · BD: MySQL 8 (InnoDB, utf8mb4, DECIMAL(15,2), UTC).

## Estructura
```
docs/          Análisis y diseño (Markdown + Mermaid); docs/anexos/ verifica los cálculos
database/      01_schema.sql · 02_catalogos.sql · 03_permisos.sql · pruebas/ (sin datos de ejemplo)
backend/       API (paquetes com.finansmart por módulo; solo esqueleto)
frontend/      Sitio web (estructura barril) y superadmin/genesis/ (Génesis del proyecto)
scripts/       Trazabilidad, sincronización de Génesis y pruebas
```

## Cómo verificar el trabajo
Requisitos: Node 18 o superior, Python 3 y MySQL 8.0.16 o superior.

```bash
npm ci
npm run validar                 # trazabilidad: requisito → caso de uso → clase → tabla → pantalla
npm run probar                  # pruebas del módulo Génesis (13)
npm run verificar:calculos      # 37 ejemplos numéricos del doc 04

# Base de datos (crea la base `finansmart`; borra la anterior si existe)
mysql -u root -p --default-character-set=utf8mb4 < database/01_schema.sql
mysql -u root -p --default-character-set=utf8mb4 < database/02_catalogos.sql
bash database/pruebas/ejecutar.sh     # 50 pruebas de integridad
bash database/pruebas/permisos.sh     # 11 pruebas de privilegios mínimos

npm run genesis:servir          # SOLO DESARROLLO: http://127.0.0.1:8080/superadmin/genesis/
```

**Integración continua:** `docs/anexos/ci-verificar.yml` corre todo lo anterior más `npm run escanear`. Aún no está activo: cópialo a `.github/workflows/verificar.yml` con una cuenta que tenga permiso `workflow` y revisa la primera corrida (no se ha ejecutado en GitHub).

`MYSQL_CMD` permite cambiar cómo se invoca el cliente (por ejemplo `MYSQL_CMD="mysql -uroot -p..."`). El usuario de la aplicación (`03_permisos.sql`) se crea con una contraseña que **no** está en el repositorio (ver el encabezado del script).

## Seguridad
Ningún archivo del repositorio contiene credenciales, tokens ni claves. Los secretos se inyectan por variables de entorno.
Ver [CONTRIBUTING.md](CONTRIBUTING.md) para ramas y commits.
