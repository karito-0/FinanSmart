#!/usr/bin/env node
// Uso: node scripts/validar-trazabilidad.mjs   (desde la raíz del repositorio)
// Sale con código 1 si hay una ruptura en la cadena requisito -> CU -> clase -> tabla -> pantalla (RNF-13).
import { validar } from './lib/trazabilidad.mjs';
const { errores, reqs, cat } = validar(process.cwd());
console.log(`Requisitos revisados: ${reqs.length} · CU: ${cat.cu.size} · clases: ${cat.clases.size} · tablas: ${cat.tablas.size} · pantallas: ${cat.pantallas.size}`);
if (errores.length) { console.log(`\n${errores.length} problema(s):`); errores.forEach((e) => console.log(' - ' + e)); process.exit(1); }
console.log('Trazabilidad completa y sin rupturas.');
