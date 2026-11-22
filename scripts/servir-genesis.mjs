#!/usr/bin/env node
// SOLO DESARROLLO LOCAL. Sirve frontend/ en http://127.0.0.1:8080 SIN autenticación.
// En producción, /superadmin/** lo sirve el backend (Spring Security) únicamente con sesión SUPERADMIN (RF-A25, RW-09).
import { createServer } from 'node:http';
import { readFile, stat } from 'node:fs/promises';
import { join, normalize, extname, sep } from 'node:path';
import { execFileSync } from 'node:child_process';

execFileSync(process.execPath, ['scripts/sincronizar-genesis.mjs'], { stdio: 'inherit' });
const raiz = join(process.cwd(), 'frontend');
const TIPOS = { '.html': 'text/html; charset=utf-8', '.css': 'text/css; charset=utf-8', '.js': 'text/javascript; charset=utf-8', '.json': 'application/json; charset=utf-8', '.md': 'text/plain; charset=utf-8', '.sql': 'text/plain; charset=utf-8' };
const puerto = Number(process.env.PUERTO ?? 8080);

createServer(async (req, res) => {
  try {
    let ruta = decodeURIComponent(new URL(req.url, 'http://x').pathname);
    if (ruta.endsWith('/')) ruta += 'index.html';
    const archivo = normalize(join(raiz, ruta));
    if (archivo !== raiz && !archivo.startsWith(raiz + sep)) { res.writeHead(403).end('Prohibido'); return; }   // sin salir de frontend/
    if (!(await stat(archivo)).isFile()) throw new Error('no es archivo');
    res.writeHead(200, { 'Content-Type': TIPOS[extname(archivo)] ?? 'application/octet-stream', 'Cache-Control': 'no-store', 'X-Content-Type-Options': 'nosniff', 'Referrer-Policy': 'no-referrer' });
    res.end(await readFile(archivo));
  } catch { res.writeHead(404, { 'Content-Type': 'text/plain; charset=utf-8' }).end('No encontrado'); }
}).listen(puerto, '127.0.0.1', () => console.log(`SOLO DESARROLLO (sin autenticación): http://127.0.0.1:${puerto}/superadmin/genesis/`));
