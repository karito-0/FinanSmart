// Pruebas del módulo Génesis. Ejecutar: npm run probar   (requiere npm ci)
import { test } from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync, existsSync } from 'node:fs';
import { join } from 'node:path';
import { execFileSync } from 'node:child_process';
import { JSDOM } from 'jsdom';
import { marked } from 'marked';
import createDOMPurify from 'dompurify';

const raiz = process.cwd();
const G = join(raiz, 'frontend/superadmin/genesis');
execFileSync(process.execPath, ['scripts/sincronizar-genesis.mjs'], { cwd: raiz, stdio: 'pipe' });

const dom = new JSDOM('<!doctype html><body></body>', { url: 'http://127.0.0.1/' });
globalThis.window = dom.window; globalThis.document = dom.window.document;
const purify = createDOMPurify(dom.window);
const M = await import(join(G, 'modulos/index.js'));

// ---------------------------------------------------------------- fórmulas (mismos casos que verificar_calculos.py)
test('F1/F2/F13 con los valores del Figma (límite 200.000)', () => {
  assert.equal(M.porcentajeUso(196000n, 200000n), 98n);
  assert.equal(M.porcentajeUso(168000n, 200000n), 84n);
  assert.equal(M.disponible(168000n, 200000n), 32000n);
  assert.equal(M.porcentajeUso(118000n, 100000n), 118n);
  assert.equal(M.porcentajeUso(79999n, 100000n), 79n, 'se trunca: 79,999 % no es 80 %');
  assert.equal(M.porcentajeUso(0n, 500000n), 0n);
  assert.equal(M.porcentajeUso(5n, 0n), null);
});
test('F2 estados con valor exacto y umbrales propios', () => {
  assert.equal(M.estadoPresupuesto(79999n, 100000n), 'NORMAL');
  assert.equal(M.estadoPresupuesto(80000n, 100000n), 'AVISO');
  assert.equal(M.estadoPresupuesto(99999n, 100000n), 'AVISO');
  assert.equal(M.estadoPresupuesto(100000n, 100000n), 'EXCEDIDO');
  assert.equal(M.estadoPresupuesto(72n, 100n, 70n, 90n), 'AVISO');
  assert.equal(M.estadoPresupuesto(0n, 0n), 'SIN_LIMITE');
  assert.equal(M.estadoPresupuesto(1000n, 0n), 'EXCEDIDO');
});
test('F3/F4 balance y tasa de ahorro', () => {
  assert.equal(M.balance(3200000n, 2150000n), 1050000n);
  assert.equal(M.tasaAhorro(3200000n, 2560000n), 20n);
  assert.equal(M.tasaAhorro(3200000n, 2559999n), 20n);
  assert.equal(M.tasaAhorro(1000000n, 1250000n), -25n);
  assert.equal(M.tasaAhorro(0n, 500000n), null);
  assert.equal(M.tasaAhorro(3200000n, 1959500n), 38n, 'el Figma dice 39 %; la política de truncado da 38 %');
  assert.equal(M.cumpleMetaAhorro(3200000n, 2560000n), true);
  assert.equal(M.cumpleMetaAhorro(3200000n, 2560001n), false);
});
test('F5/F6/F7 metas', () => {
  const hoy = { anio: 2026, mes: 11, dia: 17 };
  assert.equal(M.mesesRestantes(hoy, { anio: 2026, mes: 11, dia: 30 }), 1);
  assert.equal(M.mesesRestantes(hoy, { anio: 2026, mes: 12, dia: 31 }), 2);
  assert.equal(M.mesesRestantes(hoy, { anio: 2027, mes: 3, dia: 31 }), 5);
  assert.equal(M.mesesRestantes(hoy, { anio: 2026, mes: 11, dia: 16 }), 0);
  assert.equal(M.mesesRestantes(hoy, hoy), 1);
  assert.equal(M.aporteMensual(3000000n, 450000n, hoy, { anio: 2027, mes: 3, dia: 31 }), 510000n);
  assert.equal(M.aporteMensual(1000000n, 0n, hoy, { anio: 2027, mes: 1, dia: 31 }), 333334n, 'redondeo hacia arriba');
  assert.equal(M.aporteMensual(1000000n, 1000000n, hoy, { anio: 2027, mes: 1, dia: 31 }), null);
  assert.equal(M.aporteMensual(1000000n, 100000n, hoy, { anio: 2026, mes: 11, dia: 1 }), null);
  assert.equal(M.progresoMeta(450000n, 3000000n), 15n);
  assert.equal(M.progresoMeta(3500000n, 3000000n), 100n);
  assert.equal(M.progresoMeta(2999999n, 3000000n), 99n);
});
test('F8 límites del mes en UTC', () => {
  const nov = M.limitesMesUTC(2026, 11);
  assert.equal(nov.inicio, '2026-11-01T05:00:00.000Z');
  assert.equal(nov.fin, '2026-12-01T05:00:00.000Z');
  assert.equal(M.limitesMesUTC(2026, 12).fin, '2027-01-01T05:00:00.000Z');
  const mov = Date.parse('2026-12-01T04:30:00Z');   // 23:30 del 30-nov en Colombia
  assert.ok(mov >= Date.parse(nov.inicio) && mov < Date.parse(nov.fin));
});

// ---------------------------------------------------------------- formato
test('Formato es-CO', () => {
  assert.equal(M.pesos(1234567n), '$1.234.567');
  assert.equal(M.pesos(-32000n), '−$32.000');
  assert.equal(M.pesos(0n), '$0');
  assert.equal(M.leerPesos('1.240.500'), 1240500n);
  assert.equal(M.leerPesos('12,5'), null);
  assert.equal(M.leerPesos('-5'), null);
  assert.equal(M.leerPesos(''), null);
  assert.equal(M.fechaCorta({ anio: 2026, mes: 3, dia: 5 }), '05/03/2026');
  assert.deepEqual(M.hoyBogota(new Date('2026-12-01T04:30:00Z')), { anio: 2026, mes: 11, dia: 30 });
  assert.equal(M.leerFecha('2026-02-30'), null);
});

// ---------------------------------------------------------------- Markdown y saneado
test('El saneado elimina scripts y manejadores de eventos', () => {
  const html = M.renderizar('# T\n\n<script>alert(1)</script><img src=x onerror="alert(2)">\n\n[x](javascript:alert(3))', { marked, purify });
  assert.ok(!/<script/i.test(html)); assert.ok(!/onerror/i.test(html)); assert.ok(!/javascript:/i.test(html));
});
test('Cada documento se renderiza: títulos con id único, tablas desplazables y todos los bloques Mermaid detectados', () => {
  const idx = JSON.parse(readFileSync(join(G, 'contenido/indice.json'), 'utf8'));
  let totalMermaid = 0;
  for (const s of idx.secciones.filter((x) => x.archivo && x.tipo !== 'codigo')) {
    const md = readFileSync(join(G, 'contenido', s.archivo), 'utf8');
    const esperados = (md.match(/^```mermaid$/gm) || []).length;
    const art = document.createElement('article');
    art.innerHTML = M.renderizar(md, { marked, purify });
    const bloques = M.posprocesar(art);
    assert.equal(bloques.length, esperados, `${s.archivo}: bloques Mermaid`);
    totalMermaid += bloques.length;
    const ids = [...art.querySelectorAll('[id]')].map((e) => e.id);
    assert.equal(new Set(ids).size, ids.length, `${s.archivo}: ids duplicados`);
    art.querySelectorAll('table').forEach((t) => assert.ok(t.parentElement.classList.contains('tabla-scroll'), `${s.archivo}: tabla sin contenedor`));
    art.querySelectorAll('a[href]').forEach((a) => assert.ok(/^(https?:|#)/.test(a.getAttribute('href')), `${s.archivo}: enlace interno activo`));
    assert.equal(art.querySelectorAll('script').length, 0);
  }
  assert.ok(totalMermaid >= 9, `se esperaban al menos 9 diagramas, hay ${totalMermaid}`);
});
test('Un diagrama que falla muestra su texto en vez de romper la página', async () => {
  const pre = document.createElement('pre'); pre.className = 'mermaid'; pre.textContent = 'grafo roto';
  const fallos = await M.dibujarDiagramas([pre], { run: async () => { throw new Error('x'); } });
  assert.equal(fallos, 1); assert.ok(pre.textContent.includes('grafo roto')); assert.equal(pre.className, 'diagrama-error');
});

// ---------------------------------------------------------------- Índice y enlaces
test('Índice: ids únicos, archivos existentes y destinos de la trazabilidad', () => {
  const idx = JSON.parse(readFileSync(join(G, 'contenido/indice.json'), 'utf8'));
  const ids = idx.secciones.map((s) => s.id);
  assert.equal(new Set(ids).size, ids.length);
  for (const s of idx.secciones) if (s.archivo) assert.ok(existsSync(join(G, 'contenido', s.archivo)), s.archivo);
  for (const destino of Object.values(M.ENLACES)) assert.ok(ids.includes(destino.slice(1)), `destino ${destino} no existe`);
  assert.equal(M.seccionDesdeHash('#der', idx.secciones).id, 'der');
  assert.equal(M.seccionDesdeHash('#no-existe', idx.secciones), null);
  assert.equal(M.seccionDesdeHash('', idx.secciones), null);
});

// ---------------------------------------------------------------- Trazabilidad
const traza = JSON.parse(readFileSync(join(G, 'contenido/trazabilidad.json'), 'utf8'));
test('Trazabilidad: búsqueda y consulta inversa', () => {
  assert.equal(traza.requisitos.length, 52);
  assert.ok(M.filtrar(traza.requisitos, 'RF-17').some((r) => r.id === 'RF-17'));
  assert.ok(M.filtrar(traza.requisitos, 'sesion').length >= 2);
  assert.equal(M.filtrar(traza.requisitos, 'zzzz-no-existe').length, 0);
  assert.equal(M.filtrar(traza.requisitos, '').length, 52);
  const usan = M.usadoPor(traza.requisitos, 'tablas', 'sesion').map((r) => r.id);
  assert.ok(usan.includes('RF-04') && usan.includes('RF-A03'));
  const rf17 = traza.requisitos.find((r) => r.id === 'RF-17');
  assert.deepEqual([rf17.cu, rf17.clases, rf17.tablas, rf17.pantallas], [['CU-09'], ['Movimiento'], ['movimiento'], ['PW-10']]);
  const rf15 = traza.requisitos.find((r) => r.id === 'RF-15');
  assert.equal(rf15.sinPersistencia, true);
});
test('Trazabilidad: la interfaz filtra, muestra la cadena y navega', () => {
  const caja = document.createElement('div'); document.body.appendChild(caja);
  let destino = null;
  M.montarTrazabilidad(caja, traza.requisitos, { alElegirSeccion: (h) => { destino = h; } });
  assert.match(caja.querySelector('.traza-conteo').textContent, /52 de 52/);
  const q = caja.querySelector('#traza-q'); q.value = 'RF-17'; q.dispatchEvent(new dom.window.Event('input'));
  assert.match(caja.querySelector('.traza-conteo').textContent, /^1 de 52/);
  caja.querySelector('.traza-lista button').click();
  const detalle = caja.querySelector('.traza-detalle');
  for (const esperado of ['CU-09', 'Movimiento', 'movimiento', 'PW-10']) assert.ok(detalle.textContent.includes(esperado), esperado);
  detalle.querySelector('.chip').click();                                         // chip CU-09 -> búsqueda inversa
  assert.equal(q.value, 'CU-09'); assert.ok(Number(caja.querySelector('.traza-conteo').textContent.split(' ')[0]) >= 2);
  q.value = 'xyz-nada'; q.dispatchEvent(new dom.window.Event('input'));
  assert.match(caja.querySelector('.traza-lista').textContent, /Sin resultados/);
  caja.querySelector('.traza-lista'); caja.querySelector('#traza-q').value = 'RF-17'; q.dispatchEvent(new dom.window.Event('input'));
  caja.querySelector('.traza-lista button').click(); caja.querySelector('.traza-detalle .enlace').click();
  assert.equal(destino, '#casos-de-uso');
});

// ---------------------------------------------------------------- Calculadora
test('Calculadora: valores por defecto, estados y validación', () => {
  const cont = document.createElement('div'); document.body.appendChild(cont);
  const sec = M.montarCalculadora(cont);
  const sal = (n) => sec.querySelector(`[data-o="${n}"]`);
  const poner = (n, v) => { const i = sec.querySelector(`[data-c="${n}"]`); i.value = v; i.dispatchEvent(new dom.window.Event('input', { bubbles: true })); };
  assert.match(sal('presupuesto').textContent, /Uso: 84 %/); assert.match(sal('presupuesto').textContent, /Te quedan \$32\.000/);
  assert.match(sal('tasa').textContent, /Tasa: 38 %/);
  assert.match(sal('meta').textContent, /Progreso: 15 %/);
  poner('gastado', '200000');
  assert.equal(sal('presupuesto').className, 'excedido'); assert.match(sal('presupuesto').textContent, /Llegaste a tu límite/);
  poner('gastado', '118000'); poner('limite', '100000');
  assert.match(sal('presupuesto').textContent, /Superaste tu límite por \$18\.000/);
  poner('gastado', '80000');
  assert.equal(sal('presupuesto').className, 'aviso');
  poner('limite', '0'); poner('gastado', '0'); assert.match(sal('presupuesto').textContent, /Sin límite definido/);
  poner('gastado', 'abc'); assert.equal(sal('presupuesto').className, 'error');
  poner('aviso', '100'); poner('gastado', '10'); assert.equal(sal('presupuesto').className, 'error', 'umbrales inválidos');
  poner('ingresos', '0'); assert.match(sal('tasa').textContent, /no calculable/);
  poner('ingresos', '1000'); poner('gastos', '800'); assert.equal(sal('tasa').className, 'logro');
  poner('ahorrado', '3000000'); assert.match(sal('meta').textContent, /Meta cumplida/);
  poner('ahorrado', '0'); poner('fobj', '2000-01-01'); assert.match(sal('meta').textContent, /Fecha vencida/);
  poner('fobj', '2026-02-30'); assert.equal(sal('meta').className, 'error');
});
