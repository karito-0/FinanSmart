// Cadena requisito -> caso de uso -> clase -> tabla -> pantalla (RNF-13). Funciones puras + montaje de la interfaz.

const normalizar = (t) => t.normalize('NFD').replace(/[\u0300-\u036f]/g, '').toLowerCase();

/** Busca en id, texto y en todos los eslabones de la cadena. */
export function filtrar(requisitos, consulta) {
  const q = normalizar(consulta.trim());
  if (!q) return requisitos;
  return requisitos.filter((r) => normalizar([r.id, r.texto, ...r.cu, ...r.clases, ...r.tablas, ...r.pantallas].join(' ')).includes(q));
}

/** Requisitos que usan un eslabón concreto (consulta inversa): p. ej. «¿qué requisitos tocan la tabla sesion?» */
export function usadoPor(requisitos, tipo, valor) {
  return requisitos.filter((r) => r[tipo]?.includes(valor));
}

// Los valores son los ids de sección de contenido/indice.json
export const ENLACES = { cu: '#casos-de-uso', clases: '#clases', tablas: '#der', pantallas: '#pantallas' };
const ETIQUETAS = { cu: 'Casos de uso', clases: 'Clases', tablas: 'Tablas', pantallas: 'Pantallas' };

export function montarTrazabilidad(contenedor, requisitos, { alElegirSeccion } = {}) {
  const doc = contenedor.ownerDocument;
  contenedor.innerHTML = '';
  const caja = doc.createElement('div'); caja.className = 'traza';
  caja.innerHTML = `
    <label for="traza-q">Buscar un requisito, caso de uso, clase, tabla o pantalla</label>
    <input id="traza-q" type="search" placeholder="Ej.: RF-17, sesion, PW-10, CU-13" autocomplete="off">
    <p class="traza-conteo" aria-live="polite"></p>
    <div class="traza-cuerpo"><ul class="traza-lista" aria-label="Resultados"></ul><div class="traza-detalle" aria-live="polite"></div></div>`;
  contenedor.appendChild(caja);
  const q = caja.querySelector('#traza-q'), lista = caja.querySelector('.traza-lista');
  const conteo = caja.querySelector('.traza-conteo'), detalle = caja.querySelector('.traza-detalle');

  function pintarDetalle(r) {
    detalle.innerHTML = '';
    const h = doc.createElement('h3'); h.textContent = `${r.id} · prioridad ${r.prioridad ?? ''}`.trim(); detalle.appendChild(h);
    const p = doc.createElement('p'); p.textContent = r.texto; detalle.appendChild(p);
    if (r.criterio) { const c = doc.createElement('p'); c.className = 'suave'; c.textContent = `Criterio: ${r.criterio}`; detalle.appendChild(c); }
    for (const tipo of ['cu', 'clases', 'tablas', 'pantallas']) {
      const fila = doc.createElement('div'); fila.className = 'traza-fila';
      const et = doc.createElement('strong'); et.textContent = ETIQUETAS[tipo]; fila.appendChild(et);
      const valores = r[tipo] ?? [];
      if (!valores.length) { const s = doc.createElement('span'); s.className = 'suave'; s.textContent = tipo === 'tablas' && r.sinPersistencia ? 'No persiste (calculado)' : '—'; fila.appendChild(s); }
      for (const v of valores) {
        const b = doc.createElement('button'); b.type = 'button'; b.className = 'chip'; b.textContent = v;
        b.title = 'Ver otros requisitos que usan este elemento';
        b.addEventListener('click', () => { q.value = v; pintarLista(); q.focus(); });
        fila.appendChild(b);
      }
      const ir = doc.createElement('button'); ir.type = 'button'; ir.className = 'enlace'; ir.textContent = 'Ver sección';
      ir.addEventListener('click', () => alElegirSeccion?.(ENLACES[tipo])); fila.appendChild(ir);
      detalle.appendChild(fila);
    }
  }

  function pintarLista() {
    const r = filtrar(requisitos, q.value);
    conteo.textContent = `${r.length} de ${requisitos.length} requisitos`;
    lista.innerHTML = '';
    for (const req of r) {
      const li = doc.createElement('li'); const b = doc.createElement('button'); b.type = 'button';
      b.innerHTML = '<strong></strong> <span></span>'; b.querySelector('strong').textContent = req.id; b.querySelector('span').textContent = req.texto;
      b.addEventListener('click', () => { lista.querySelectorAll('button').forEach((x) => x.removeAttribute('aria-current')); b.setAttribute('aria-current', 'true'); pintarDetalle(req); });
      li.appendChild(b); lista.appendChild(li);
    }
    if (!r.length) { const li = doc.createElement('li'); li.className = 'suave'; li.textContent = 'Sin resultados para esa búsqueda.'; lista.appendChild(li); }
  }
  q.addEventListener('input', pintarLista);
  pintarLista();
  detalle.innerHTML = '<p class="suave">Elige un requisito para ver su cadena completa. Haz clic en cualquier etiqueta para ver qué otros requisitos la usan.</p>';
}
