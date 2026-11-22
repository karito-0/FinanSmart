#!/usr/bin/env node
// Copia la documentación a frontend/superadmin/genesis/contenido/ y genera indice.json y trazabilidad.json.
// Falla (código 1) si la trazabilidad tiene rupturas: Génesis nunca publica una cadena rota (RNF-13).
// Uso: node scripts/sincronizar-genesis.mjs   (desde la raíz del repositorio)
import { mkdirSync, copyFileSync, writeFileSync, existsSync, readdirSync, rmSync } from 'node:fs';
import { join, basename } from 'node:path';
import { validar } from './lib/trazabilidad.mjs';

const raiz = process.cwd();
const destino = join(raiz, 'frontend/superadmin/genesis/contenido');

const SECCIONES = [
  { id: 'contexto', titulo: '1. Contexto y decisiones', archivo: 'docs/01-resumen-y-decisiones.md' },
  { id: 'sistemico', titulo: '2. Enfoque sistémico', archivo: 'docs/02-enfoque-sistemico.md' },
  { id: 'requisitos', titulo: '3. Requisitos', archivo: 'docs/03-requisitos.md' },
  { id: 'logica', titulo: '4. Lógica matemática', archivo: 'docs/04-logica-matematica.md', componente: 'calculadora' },
  { id: 'casos-de-uso', titulo: '5. Casos de uso', archivo: 'docs/05-casos-de-uso.md' },
  { id: 'clases', titulo: '6. Diagrama de clases', archivo: 'docs/06-diagrama-de-clases.md' },
  { id: 'der', titulo: '7. DER', archivo: 'docs/07-der.md' },
  { id: 'normalizacion', titulo: '8. Normalización', archivo: 'docs/08-normalizacion.md' },
  { id: 'base-de-datos', titulo: '9. Base de datos (SQL)', archivo: 'database/01_schema.sql', tipo: 'codigo' },
  { id: 'api', titulo: '10. Estructura y API', archivo: 'docs/10-estructura-y-api.md' },
  { id: 'pantallas', titulo: '11. Mapa de pantallas', archivo: 'docs/11-mapa-de-pantallas.md' },
  { id: 'trazabilidad', titulo: '12. Trazabilidad interactiva', componente: 'trazabilidad' },
  { id: 'acerca', titulo: 'Acerca de este módulo', archivo: 'docs/12-genesis-del-proyecto.md' },
];

const { errores, reqs } = validar(raiz);
if (errores.length) {
  console.error(`Trazabilidad con ${errores.length} ruptura(s); no se genera Génesis:`);
  errores.forEach((e) => console.error(' - ' + e));
  process.exit(1);
}

if (existsSync(destino)) for (const f of readdirSync(destino)) if (f !== '.gitkeep') rmSync(join(destino, f), { recursive: true, force: true });
mkdirSync(destino, { recursive: true });

const faltan = [];
const secciones = SECCIONES.map((s) => {
  if (!s.archivo) return s;
  const origen = join(raiz, s.archivo);
  if (!existsSync(origen)) { faltan.push(s.archivo); return s; }
  copyFileSync(origen, join(destino, basename(s.archivo)));
  return { ...s, archivo: basename(s.archivo) };
});
if (faltan.length) { console.error('Faltan archivos: ' + faltan.join(', ')); process.exit(1); }

const generado = new Date().toISOString().slice(0, 10);
writeFileSync(join(destino, 'indice.json'), JSON.stringify({ generado, secciones }, null, 2));
writeFileSync(join(destino, 'trazabilidad.json'), JSON.stringify({ generado, requisitos: reqs }, null, 2));
console.log(`Génesis sincronizado: ${secciones.length} secciones y ${reqs.length} requisitos con cadena completa.`);
