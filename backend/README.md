# Backend (Java 17 + Spring Boot)

Estructura y contrato de la API: `docs/10-estructura-y-api.md`. Esquema de base de datos: `database/`.

Estado: **solo esqueleto**. Falta crear `pom.xml` (Spring Boot, Spring Security, validación, MySQL) y el código de cada módulo.

Reglas que deben cumplirse desde el primer commit:
- Un módulo solo importa el paquete `api` de otro (prueba `ArquitecturaTest`).
- Solo el módulo `calculo` decide estados y alertas (fórmulas del doc 04, con `BigDecimal`).
- Los módulos de administración no dependen de `movimientos`, `presupuestos`, `metas`, `banca` ni `reportes` (RN-12).
- Todo endpoint declara su rol; una prueba falla si alguno no lo hace (RNF-03).
- La página Génesis va **fuera** de `static/`, servida por un controlador protegido (doc 12 §2).
- Sin secretos en el repositorio: `application.yml` solo lee variables de entorno (RNF-14).
