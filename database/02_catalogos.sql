-- =====================================================================
-- FinanSmart · Catálogos semilla. NO son datos de ejemplo: son lo mínimo que el
-- sistema necesita para funcionar y no pertenecen a ningún usuario (INC-12).
-- No se precargan categorías, movimientos, presupuestos, metas, lecciones ni usuarios.
-- =====================================================================
USE finansmart;

INSERT INTO rol (codigo, descripcion) VALUES
  ('USUARIO',    'Persona que gestiona sus propias finanzas'),
  ('ADMIN',      'Opera usuarios (solo datos de cuenta) y contenido educativo'),
  ('SUPERADMIN', 'Gestiona cuentas ADMIN, consulta la auditoría y ve Génesis del proyecto');

-- Decisión D-03: precio y prueba son del cliente. Los límites del plan Gratis siguen en PA-02.
INSERT INTO plan (codigo, nombre, precio_mensual_cop, dias_prueba) VALUES
  ('GRATIS', 'Gratis', 0,     0),
  ('PRO',    'Pro',    11900, 7);

-- Destino de reasignación al eliminar una categoría (RN-09). No se ofrece al crear movimientos.
INSERT INTO categoria (usuario_id, nombre, tipo, icono) VALUES
  (NULL, 'Sin categoría', 'INGRESO', NULL),
  (NULL, 'Sin categoría', 'GASTO',   NULL);
