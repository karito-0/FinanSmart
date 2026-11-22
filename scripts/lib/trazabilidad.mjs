// Lee los documentos del análisis y construye/valida la cadena
// requisito -> caso de uso -> clase -> tabla -> pantalla (RNF-13).
// Sin dependencias: solo Node 18 o superior.
import { readFileSync } from 'node:fs';
import { join } from 'node:path';

const leer = (raiz, ruta) => readFileSync(join(raiz, ruta), 'utf8');
const celdas = (linea) => linea.trim().replace(/^\||\|$/g, '').split('|').map((c) => c.trim());
const lista = (txt) => txt.split(',').map((x) => x.trim()).filter(Boolean);
const pascal = (t) => t.split('_').map((p) => p[0].toUpperCase() + p.slice(1)).join('');

/** Expande «PW-S01..S03» y «PW-08, PW-10». «todas» queda como comodín. */
export function expandirPantallas(txt) {
  const salida = [];
  for (const parte of lista(txt)) {
    const r = parte.match(/^(PW-)([A-Z]?)(\d+)\.\.([A-Z]?)(\d+)$/);
    if (r) {
      for (let n = Number(r[3]); n <= Number(r[5]); n++) salida.push(`${r[1]}${r[2]}${String(n).padStart(2, '0')}`);
    } else salida.push(parte);
  }
  return salida;
}

/** Filas RF-/RF-A/RW- de docs/03-requisitos.md */
export function leerRequisitos(raiz) {
  const filas = [];
  for (const l of leer(raiz, 'docs/03-requisitos.md').split('\n')) {
    if (!/^\| (RF|RW)-/.test(l)) continue;
    const c = celdas(l);
    if (c[0].startsWith('RW-')) {
      filas.push({ id: c[0], texto: c[1], prioridad: c[2], criterio: c[3], cu: [], tablas: [], clases: [], pantallas: expandirPantallas(c[4]) });
    } else {
      const tablas = lista(c[5]).filter((t) => t !== '—' && t !== '(calculado)');
      const calculado = c[5].includes('(calculado)');
      filas.push({
        id: c[0], texto: c[1], prioridad: c[2], criterio: c[3],
        cu: lista(c[4]), tablas,
        clases: [...tablas.map(pascal), ...(calculado ? ['CalculadoraFinanciera'] : [])],
        sinPersistencia: c[5] === '—' || calculado,
        pantallas: expandirPantallas(c[6]),
      });
    }
  }
  return filas;
}

export function leerCatalogos(raiz) {
  const sql = leer(raiz, 'database/01_schema.sql');
  const tablas = new Set([...sql.matchAll(/CREATE TABLE (\w+)/g)].map((m) => m[1]));
  const clases = new Set([...leer(raiz, 'docs/06-diagrama-de-clases.md').matchAll(/^\s*class (\w+) \{/gm)].map((m) => m[1]));
  const cu = new Set([...leer(raiz, 'docs/05-casos-de-uso.md').matchAll(/^### (CU-\d+)/gm)].map((m) => m[1]));
  const pantallas = new Set([...leer(raiz, 'docs/11-mapa-de-pantallas.md').matchAll(/^\| (PW-[A-Z]?\d+) \|/gm)].map((m) => m[1]));
  return { tablas, clases, cu, pantallas };
}

/** RF citados por cada CU en la tabla de trazabilidad del doc 05 */
export function leerRfPorCu(raiz) {
  const txt = leer(raiz, 'docs/05-casos-de-uso.md').split('## 5. Trazabilidad')[1] ?? '';
  const mapa = new Map();
  for (const l of txt.split('\n')) {
    const m = l.match(/^\| (\d{2}) \| (.+) \|$/);
    if (!m) continue;
    const ids = new Set();
    for (const tok of lista(m[2])) {
      const t = tok.replace(/^RF-/, '');
      ids.add(`RF-${t}`);
    }
    mapa.set(`CU-${m[1]}`, ids);
  }
  return mapa;
}

export function validar(raiz) {
  const errores = [];
  const reqs = leerRequisitos(raiz);
  const cat = leerCatalogos(raiz);
  const rfPorCu = leerRfPorCu(raiz);
  for (const r of reqs) {
    const esRF = r.id.startsWith('RF-');
    if (esRF && r.cu.length === 0) errores.push(`${r.id}: sin caso de uso`);
    if (esRF && !r.sinPersistencia && r.tablas.length === 0) errores.push(`${r.id}: sin tabla`);
    if (r.pantallas.length === 0) errores.push(`${r.id}: sin pantalla`);
    for (const c of r.cu) if (!cat.cu.has(c)) errores.push(`${r.id}: ${c} no existe en docs/05`);
    for (const t of r.tablas) if (!cat.tablas.has(t)) errores.push(`${r.id}: la tabla «${t}» no existe en database/01_schema.sql`);
    for (const k of r.clases) if (!cat.clases.has(k)) errores.push(`${r.id}: la clase «${k}» no existe en docs/06`);
    for (const p of r.pantallas) if (p !== 'todas' && !cat.pantallas.has(p)) errores.push(`${r.id}: la pantalla ${p} no existe en docs/11`);
    // coherencia con la tabla de trazabilidad del doc 05
    if (esRF) for (const c of r.cu) {
      const citados = rfPorCu.get(c);
      if (citados && !citados.has(r.id)) errores.push(`${r.id}: docs/03 lo asocia a ${c}, pero la tabla del doc 05 no lo lista`);
    }
  }
  for (const [c, ids] of rfPorCu) {
    for (const id of ids) {
      const r = reqs.find((x) => x.id === id);
      if (!r) errores.push(`docs/05: ${c} cita ${id}, que no existe en docs/03`);
      else if (!r.cu.includes(c)) errores.push(`docs/05: ${c} cita ${id}, pero docs/03 no lo asocia a ese caso de uso`);
    }
  }
  // todo CU del catálogo debe tener al menos un requisito
  for (const c of cat.cu) if (!reqs.some((r) => r.cu.includes(c))) errores.push(`${c}: ningún requisito lo usa`);
  // toda pantalla del inventario debe tener al menos un requisito
  for (const p of cat.pantallas) if (!reqs.some((r) => r.pantallas.includes(p) || r.pantallas.includes('todas'))) errores.push(`${p}: ningún requisito la usa`);
  return { errores, reqs, cat };
}
