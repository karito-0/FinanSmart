# FinanSmart

Aplicación web responsive de organización financiera personal para jóvenes profesionales y familias en Colombia (español de Colombia, COP, fechas DD/MM/AAAA).

> **Orientación, no asesoría.** El contenido y las recomendaciones de FinanSmart no constituyen asesoría financiera.

## Estado
Documentación de análisis y diseño por fases:

| Fase | Entregables | Estado |
|---|---|---|
| A | 1 Resumen y decisiones · 2 Enfoque sistémico · 3 Requisitos | Publicada |
| B | 4 Lógica matemática · 5 Casos de uso · 6 Clases · 7 DER · 8 Normalización | En revisión (PR `docs/fase-b`) |
| C | 9 SQL · 10 Estructura/API · 11 Pantallas · 12 Génesis del proyecto | Pendiente |

## Stack
Front: HTML, CSS, JavaScript (fetch) · Back: Java 17, Spring Boot, Spring Security, API REST JSON · BD: MySQL 8 (InnoDB, utf8mb4, DECIMAL(15,2), UTC).

## Estructura
```
docs/        Análisis y diseño (Markdown + Mermaid)
docs/anexos/ Verificación de cálculos (Python)
database/    Scripts SQL (sin datos de ejemplo)
frontend/    Sitio web (estructura barril)
backend/     API (paquetes com.finansmart)
```

## Seguridad
Ningún archivo del repositorio contiene credenciales, tokens ni claves. Los secretos se inyectan por variables de entorno.
Ver [CONTRIBUTING.md](CONTRIBUTING.md) para ramas y commits.
