// Formato es-CO (RNF-07): 1.234.567 y DD/MM/AAAA. Solo para mostrar; nunca para decidir.

/** BigInt de pesos -> «$1.234.567» (con signo si es negativo). */
export function pesos(valor) {
  if (valor === null || valor === undefined) return '—';
  const negativo = valor < 0n;
  const digitos = (negativo ? -valor : valor).toString().replace(/\B(?=(\d{3})+(?!\d))/g, '.');
  return `${negativo ? '−' : ''}$${digitos}`;
}

/** Texto de un campo numérico -> BigInt de pesos enteros, o null si no es válido. Acepta puntos de miles. */
export function leerPesos(texto) {
  const limpio = String(texto ?? '').trim().replace(/\./g, '').replace(/^\$/, '');
  return /^\d{1,15}$/.test(limpio) ? BigInt(limpio) : null;
}

/** Porcentaje BigInt -> «84 %» */
export const porcentaje = (p) => (p === null || p === undefined ? '—' : `${p} %`);

/** Fecha {anio, mes, dia} -> DD/MM/AAAA */
export const fechaCorta = (f) => `${String(f.dia).padStart(2, '0')}/${String(f.mes).padStart(2, '0')}/${f.anio}`;

/** Hoy en America/Bogota como {anio, mes, dia}. */
export function hoyBogota(ahora = new Date()) {
  const partes = new Intl.DateTimeFormat('en-CA', { timeZone: 'America/Bogota', year: 'numeric', month: '2-digit', day: '2-digit' })
    .formatToParts(ahora).reduce((a, p) => ({ ...a, [p.type]: p.value }), {});
  return { anio: Number(partes.year), mes: Number(partes.month), dia: Number(partes.day) };
}

/** «2026-11-30» -> {anio, mes, dia} o null */
export function leerFecha(texto) {
  const m = /^(\d{4})-(\d{2})-(\d{2})$/.exec(texto ?? '');
  if (!m) return null;
  const f = { anio: Number(m[1]), mes: Number(m[2]), dia: Number(m[3]) };
  const d = new Date(Date.UTC(f.anio, f.mes - 1, f.dia));
  return d.getUTCFullYear() === f.anio && d.getUTCMonth() === f.mes - 1 && d.getUTCDate() === f.dia ? f : null;
}
