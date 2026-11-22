// Navegación por secciones con rutas de hash simples (#contexto).

export function montarNavegacion(nav, secciones, actual) {
  const doc = nav.ownerDocument;
  nav.innerHTML = '';
  const ul = doc.createElement('ul');
  for (const s of secciones) {
    const li = doc.createElement('li'), a = doc.createElement('a');
    a.href = `#${s.id}`; a.textContent = s.titulo; a.dataset.id = s.id;
    if (s.id === actual) a.setAttribute('aria-current', 'page');
    li.appendChild(a); ul.appendChild(li);
  }
  nav.appendChild(ul);
}

export function marcarActual(nav, id) {
  nav.querySelectorAll('a').forEach((a) => (a.dataset.id === id ? a.setAttribute('aria-current', 'page') : a.removeAttribute('aria-current')));
}

/** Lee el id de la sección desde el hash; si no existe, devuelve la primera. */
export function seccionDesdeHash(hash, secciones) {
  const id = (hash || '').replace(/^#\/?/, '');
  return secciones.find((s) => s.id === id) ?? null;
}
