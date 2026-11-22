#!/usr/bin/env node
// Escáner de secretos para el repositorio (RNF-14). Revisa los archivos versionados.
// Uso: node scripts/escanear-secretos.mjs      Sale con código 1 si encuentra algo.
import { execFileSync } from 'node:child_process';
import { readFileSync } from 'node:fs';

const PATRONES = [
  ['Token de GitHub (fine-grained)', /github_pat_[A-Za-z0-9_]{20,}/],
  ['Token de GitHub (clásico u OAuth)', /\bgh[pousr]_[A-Za-z0-9]{30,}\b/],
  ['Clave de acceso de AWS', /\bAKIA[0-9A-Z]{16}\b/],
  ['Clave privada', /-----BEGIN (?:RSA |EC |OPENSSH |DSA |PGP )?PRIVATE KEY-----/],
  ['Token de Slack', /\bxox[baprs]-[A-Za-z0-9-]{10,}/],
  ['Clave de API genérica asignada', /\b(?:api[_-]?key|secret|token|passw(?:or)?d|contrasena)\s*[:=]\s*["'][A-Za-z0-9_\-\/+=]{16,}["']/i],
];
const IGNORAR = /(^|\/)(package-lock\.json|node_modules\/)/;

const archivos = execFileSync('git', ['ls-files', '-z', '--cached', '--others', '--exclude-standard'], { encoding: 'utf8' })
  .split('\0').filter((f) => f && !IGNORAR.test(f));
const hallazgos = [];
for (const f of archivos) {
  let txt; try { txt = readFileSync(f, 'utf8'); } catch { continue; }
  if (txt.includes('\u0000')) continue;                                   // binario
  txt.split('\n').forEach((linea, i) => {
    for (const [nombre, re] of PATRONES) if (re.test(linea)) hallazgos.push(`${f}:${i + 1}  ${nombre}`);
  });
}
console.log(`Archivos revisados: ${archivos.length}`);
if (hallazgos.length) { console.error('\nPosibles secretos (el valor no se imprime):'); hallazgos.forEach((h) => console.error(' - ' + h)); process.exit(1); }
console.log('Sin secretos detectados.');
