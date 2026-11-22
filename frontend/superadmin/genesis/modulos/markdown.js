// Markdown -> HTML saneado. Las librerías (marked, DOMPurify, mermaid) se INYECTAN para poder probar sin navegador.

const quitarTildes = (t) => t.normalize('NFD').replace(/[\u0300-\u036f]/g, '');
export const slug = (t) => quitarTildes(t).toLowerCase().replace(/[^a-z0-9]+/g, '-').replace(/^-|-$/g, '');

/** Convierte Markdown en HTML seguro. El contenido es del propio repositorio, pero se sanea igualmente. */
export function renderizar(texto, { marked, purify }) {
  const bruto = marked.parse(texto, { gfm: true, breaks: false });
  return purify.sanitize(bruto, { USE_PROFILES: { html: true } });
}

/** Ajustes sobre el DOM ya saneado: ids en títulos, tablas con desplazamiento, enlaces seguros, bloques Mermaid. */
export function posprocesar(raiz) {
  const usados = new Set();
  raiz.querySelectorAll('h1, h2, h3').forEach((h) => {
    let id = slug(h.textContent) || 'seccion';
    while (usados.has(id)) id += '-2';
    usados.add(id); h.id = id;
  });
  raiz.querySelectorAll('table').forEach((t) => {
    if (t.parentElement?.classList.contains('tabla-scroll')) return;
    const envoltura = raiz.ownerDocument.createElement('div');
    envoltura.className = 'tabla-scroll'; envoltura.tabIndex = 0;
    envoltura.setAttribute('role', 'region'); envoltura.setAttribute('aria-label', 'Tabla desplazable');
    t.replaceWith(envoltura); envoltura.appendChild(t);
  });
  raiz.querySelectorAll('a[href]').forEach((a) => {
    const href = a.getAttribute('href');
    if (/^https?:/i.test(href)) { a.target = '_blank'; a.rel = 'noopener noreferrer'; }
    else if (!href.startsWith('#')) { a.removeAttribute('href'); a.classList.add('enlace-interno'); }  // rutas del repo: no existen en la web
  });
  const bloques = [];
  raiz.querySelectorAll('pre > code.language-mermaid').forEach((codigo) => {
    const pre = raiz.ownerDocument.createElement('pre');
    pre.className = 'mermaid'; pre.textContent = codigo.textContent;  // textContent: nunca HTML
    codigo.parentElement.replaceWith(pre); bloques.push(pre);
  });
  return bloques;
}

/** Dibuja los diagramas; si uno falla, muestra el texto en lugar de romper la página. */
export async function dibujarDiagramas(bloques, mermaid) {
  let fallos = 0;
  for (const nodo of bloques) {
    const fuente = nodo.textContent;
    try { await mermaid.run({ nodes: [nodo] }); }
    catch { fallos++; nodo.className = 'diagrama-error'; nodo.textContent = `No se pudo dibujar el diagrama. Texto fuente:\n${fuente}`; }
  }
  return fallos;
}

/** Tabla de contenido con los h2 */
export function tablaDeContenido(raiz) {
  return [...raiz.querySelectorAll('h2')].map((h) => ({ id: h.id, texto: h.textContent }));
}
