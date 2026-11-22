// Génesis del proyecto (PW-S02): lectura de la documentación con navegación, diagramas, calculadora y trazabilidad.
// Solo lectura. Nunca muestra datos de usuarios. El acceso lo protege el SERVIDOR (RF-A25, RW-09): esta página no es una barrera.
import { renderizar, posprocesar, dibujarDiagramas, tablaDeContenido, montarNavegacion, marcarActual, seccionDesdeHash, montarCalculadora, montarTrazabilidad } from './modulos/index.js';

const $ = (s) => document.querySelector(s);
const nav = $('#nav'), main = $('#contenido'), toc = $('#toc');
let secciones = [];
let secuencia = 0;  // evita que una respuesta lenta pise a una sección más reciente

async function pedir(ruta, tipo = 'texto') {
  const r = await fetch(ruta, { credentials: 'same-origin', headers: { Accept: tipo === 'json' ? 'application/json' : 'text/plain' } });
  if (r.status === 401 || r.status === 403) throw Object.assign(new Error('Sin permiso'), { permiso: true });
  if (!r.ok) throw new Error(`HTTP ${r.status}`);
  return tipo === 'json' ? r.json() : r.text();
}

function estado(tipo, mensaje, reintentar) {
  main.setAttribute('aria-busy', String(tipo === 'carga'));
  main.innerHTML = '';
  const p = document.createElement('p'); p.className = tipo === 'error' ? 'estado error' : 'estado'; p.setAttribute('role', tipo === 'error' ? 'alert' : 'status');
  p.textContent = mensaje; main.appendChild(p);
  if (reintentar) { const b = document.createElement('button'); b.type = 'button'; b.textContent = 'Reintentar'; b.addEventListener('click', reintentar); main.appendChild(b); }
}

function pintarToc(items) {
  toc.innerHTML = '';
  if (items.length < 2) { toc.hidden = true; return; }
  toc.hidden = false;
  const h = document.createElement('h2'); h.textContent = 'En esta sección'; toc.appendChild(h);
  const ul = document.createElement('ul');
  for (const it of items) { const li = document.createElement('li'), a = document.createElement('a'); a.href = `#${it.id}`; a.textContent = it.texto; a.addEventListener('click', (e) => { e.preventDefault(); document.getElementById(it.id)?.scrollIntoView({ behavior: matchMedia('(prefers-reduced-motion: reduce)').matches ? 'auto' : 'smooth' }); }); li.appendChild(a); ul.appendChild(li); }
  toc.appendChild(ul);
}

async function mostrar(sec) {
  const mio = ++secuencia;
  marcarActual(nav, sec.id); document.title = `${sec.titulo} · Génesis · FinanSmart`;
  estado('carga', 'Cargando…');
  try {
    const articulo = document.createElement('article');
    if (sec.componente === 'trazabilidad') {
      const datos = await pedir('contenido/trazabilidad.json', 'json');
      if (mio !== secuencia) return;
      const h = document.createElement('h1'); h.textContent = sec.titulo; articulo.appendChild(h);
      const intro = document.createElement('p'); intro.className = 'suave'; intro.textContent = `Cada requisito vincula caso de uso, clase, tabla y pantalla (RNF-13). Generado el ${datos.generado}; ${datos.requisitos.length} requisitos sin rupturas.`; articulo.appendChild(intro);
      const caja = document.createElement('div'); articulo.appendChild(caja);
      main.innerHTML = ''; main.appendChild(articulo);
      montarTrazabilidad(caja, datos.requisitos, { alElegirSeccion: (h2) => { location.hash = h2; } });
      pintarToc([]);
    } else if (sec.tipo === 'codigo') {
      const sql = await pedir(`contenido/${sec.archivo}`);
      if (mio !== secuencia) return;
      const h = document.createElement('h1'); h.textContent = sec.titulo; articulo.appendChild(h);
      const nota = document.createElement('p'); nota.className = 'suave'; nota.textContent = 'Script de solo lectura. La fuente de verdad es database/01_schema.sql.'; articulo.appendChild(nota);
      const pre = document.createElement('pre'), code = document.createElement('code'); code.textContent = sql; pre.appendChild(code); pre.tabIndex = 0; articulo.appendChild(pre);
      main.innerHTML = ''; main.appendChild(articulo); pintarToc([]);
    } else {
      const texto = await pedir(`contenido/${sec.archivo}`);
      if (mio !== secuencia) return;
      articulo.innerHTML = renderizar(texto, { marked: window.marked, purify: window.DOMPurify });
      const bloques = posprocesar(articulo);
      main.innerHTML = ''; main.appendChild(articulo);
      if (sec.componente === 'calculadora') montarCalculadora(main);
      pintarToc(tablaDeContenido(articulo));
      if (bloques.length) {
        window.mermaid.initialize({ startOnLoad: false, securityLevel: 'strict', theme: 'base', themeVariables: { primaryColor: '#EEF4FA', primaryBorderColor: '#15579A', primaryTextColor: '#0D3B69', lineColor: '#15579A', fontFamily: 'system-ui, sans-serif' } });
        const fallos = await dibujarDiagramas(bloques, window.mermaid);
        if (fallos) { const av = document.createElement('p'); av.className = 'estado error'; av.setAttribute('role', 'alert'); av.textContent = `${fallos} diagrama(s) no se pudieron dibujar; se muestra su texto.`; articulo.prepend(av); }
      }
    }
    main.setAttribute('aria-busy', 'false'); main.focus({ preventScroll: true }); window.scrollTo(0, 0);
  } catch (e) {
    if (mio !== secuencia) return;
    if (e.permiso) estado('error', 'Esta sección solo está disponible para SUPERADMIN con sesión iniciada.');
    else estado('error', 'No pudimos cargar esta sección. Revisa tu conexión e inténtalo de nuevo.', () => mostrar(sec));
  }
}

function enrutar() {
  const sec = seccionDesdeHash(location.hash, secciones) ?? secciones[0];
  if (!sec) return;
  if (location.hash.replace('#', '') !== sec.id) history.replaceState(null, '', `#${sec.id}`);
  mostrar(sec);
}

async function iniciar() {
  if (!window.marked || !window.DOMPurify || !window.mermaid) { estado('error', 'No se cargaron las librerías de lectura (marked, DOMPurify, mermaid). Revisa la conexión.'); return; }
  try {
    const indice = await pedir('contenido/indice.json', 'json');
    secciones = indice.secciones;
    montarNavegacion(nav, secciones, null);
    $('#version').textContent = `Contenido generado el ${indice.generado}`;
    addEventListener('hashchange', enrutar);
    $('#menu-boton').addEventListener('click', () => { const abierto = nav.parentElement.classList.toggle('abierto'); $('#menu-boton').setAttribute('aria-expanded', String(abierto)); });
    nav.addEventListener('click', (e) => { if (e.target.closest('a')) { nav.parentElement.classList.remove('abierto'); $('#menu-boton').setAttribute('aria-expanded', 'false'); } });
    enrutar();
  } catch (e) {
    estado('error', e.permiso ? 'Esta página solo está disponible para SUPERADMIN con sesión iniciada.' : 'No pudimos cargar el índice de Génesis.', e.permiso ? null : iniciar);
  }
}
iniciar();
