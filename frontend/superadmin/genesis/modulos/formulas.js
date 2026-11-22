// Fórmulas F1 a F13 del doc 04, con BigInt (aritmética exacta; sin coma flotante).
// Todos los montos son pesos ENTEROS (BigInt). BigInt trunca hacia cero, igual que la política del doc 04.
// Es una réplica de solo lectura para explicar el cálculo: la decisión real vive en el servidor (CalculadoraFinanciera).

/** F1 · porcentaje de uso mostrado (truncado). null si el límite es 0. */
export function porcentajeUso(gastado, limite) {
  return limite > 0n ? (100n * gastado) / limite : null;
}

/** F2 · estado con el valor EXACTO (producto cruzado, sin redondeo). */
export function estadoPresupuesto(gastado, limite, aviso = 80n, tope = 100n) {
  if (limite === 0n) return gastado > 0n ? 'EXCEDIDO' : 'SIN_LIMITE';
  if (100n * gastado >= tope * limite) return 'EXCEDIDO';
  if (100n * gastado >= aviso * limite) return 'AVISO';
  return 'NORMAL';
}

/** F13 · disponible de la categoría (puede ser negativo). */
export const disponible = (gastado, limite) => limite - gastado;

/** F3 · balance del mes. */
export const balance = (ingresos, gastos) => ingresos - gastos;

/** F4 · tasa de ahorro truncada hacia cero. null si no hay ingresos. */
export function tasaAhorro(ingresos, gastos) {
  return ingresos === 0n ? null : (100n * (ingresos - gastos)) / ingresos;
}

/** F4 · ¿cumple la meta de ahorro del usuario? */
export const cumpleMetaAhorro = (ingresos, gastos, metaPct = 20n) =>
  ingresos > 0n && 100n * (ingresos - gastos) >= metaPct * ingresos;

/** F7 · meses restantes de una meta, contando el mes en curso (supuesto S-06). Fechas {anio, mes, dia}. */
export function mesesRestantes(hoy, objetivo) {
  const t = (f) => Date.UTC(f.anio, f.mes - 1, f.dia);
  if (t(objetivo) < t(hoy)) return 0;
  return (objetivo.anio - hoy.anio) * 12 + (objetivo.mes - hoy.mes) + 1;
}

/** F5 · aporte mensual sugerido, redondeado hacia arriba al peso. null si cumplida o vencida. */
export function aporteMensual(objetivo, ahorrado, hoy, fechaObjetivo) {
  if (ahorrado >= objetivo) return null;
  const m = BigInt(mesesRestantes(hoy, fechaObjetivo));
  if (m <= 0n) return null;
  const faltante = objetivo - ahorrado;
  return (faltante + m - 1n) / m;
}

/** F6 · progreso de la meta (truncado, tope 100). */
export function progresoMeta(ahorrado, objetivo) {
  const p = (100n * ahorrado) / objetivo;
  return p > 100n ? 100n : p;
}

/** F8 · límites [inicio, fin) de un mes local de Colombia (UTC−5) expresados en UTC. */
export function limitesMesUTC(anio, mes) {
  const ini = new Date(Date.UTC(anio, mes - 1, 1, 5, 0, 0));
  const fin = new Date(Date.UTC(anio, mes, 1, 5, 0, 0));
  return { inicio: ini.toISOString(), fin: fin.toISOString() };
}
