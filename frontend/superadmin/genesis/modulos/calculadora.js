// Calculadora interactiva de la lógica matemática (doc 04). Solo explica; no guarda nada.
import { porcentajeUso, estadoPresupuesto, disponible, balance, tasaAhorro, cumpleMetaAhorro, mesesRestantes, aporteMensual, progresoMeta } from './formulas.js';
import { pesos, leerPesos, porcentaje, hoyBogota, leerFecha, fechaCorta } from './formato.js';

const TEXTO_ESTADO = {
  NORMAL: { clase: 'normal', texto: 'Normal' },
  AVISO: { clase: 'aviso', texto: 'Aviso: llegaste al umbral de alerta' },
  EXCEDIDO: { clase: 'excedido', texto: 'Límite alcanzado o superado' },
  SIN_LIMITE: { clase: 'normal', texto: 'Sin límite definido' },
};

export function montarCalculadora(contenedor) {
  const doc = contenedor.ownerDocument;
  const hoy = hoyBogota();
  const hoyTxt = `${hoy.anio}-${String(hoy.mes).padStart(2, '0')}-${String(hoy.dia).padStart(2, '0')}`;
  const objTxt = `${hoy.anio + 1}-03-31`;
  const sec = doc.createElement('section'); sec.className = 'calculadora'; sec.setAttribute('aria-labelledby', 'calc-titulo');
  sec.innerHTML = `
    <h2 id="calc-titulo">Calculadora interactiva</h2>
    <p class="suave">Cambia los valores y mira cómo se aplican F1, F2, F4, F5, F6, F7 y F13. Todo en pesos enteros. La decisión real la toma el servidor; esto solo explica la regla.</p>
    <div class="calc-rejilla">
      <fieldset><legend>Presupuesto de una categoría</legend>
        <label>Gastado ($)<input data-c="gastado" inputmode="numeric" value="168000"></label>
        <label>Límite mensual ($)<input data-c="limite" inputmode="numeric" value="200000"></label>
        <label>Umbral de aviso (%)<input data-c="aviso" inputmode="numeric" value="80"></label>
        <label>Umbral de límite (%)<input data-c="tope" inputmode="numeric" value="100"></label>
        <output data-o="presupuesto" aria-live="polite"></output>
      </fieldset>
      <fieldset><legend>Tasa de ahorro del mes</legend>
        <label>Ingresos ($)<input data-c="ingresos" inputmode="numeric" value="3200000"></label>
        <label>Gastos ($)<input data-c="gastos" inputmode="numeric" value="1959500"></label>
        <label>Meta de ahorro (%)<input data-c="meta" inputmode="numeric" value="20"></label>
        <output data-o="tasa" aria-live="polite"></output>
      </fieldset>
      <fieldset><legend>Meta de ahorro</legend>
        <label>Objetivo ($)<input data-c="objetivo" inputmode="numeric" value="3000000"></label>
        <label>Ahorrado ($)<input data-c="ahorrado" inputmode="numeric" value="450000"></label>
        <label>Hoy<input data-c="hoy" type="date" value="${hoyTxt}"></label>
        <label>Fecha objetivo<input data-c="fobj" type="date" value="${objTxt}"></label>
        <output data-o="meta" aria-live="polite"></output>
      </fieldset>
    </div>`;
  contenedor.appendChild(sec);
  const v = (n) => sec.querySelector(`[data-c="${n}"]`).value;
  const salida = (n) => sec.querySelector(`[data-o="${n}"]`);
  const aviso = (n, txt) => { salida(n).className = 'error'; salida(n).textContent = txt; };

  function calcular() {
    const g = leerPesos(v('gastado')), l = leerPesos(v('limite')), a = leerPesos(v('aviso')), t = leerPesos(v('tope'));
    const o1 = salida('presupuesto'); o1.className = '';
    if ([g, l, a, t].includes(null)) aviso('presupuesto', 'Escribe solo números enteros.');
    else if (!(a >= 1n && a < t && t <= 100n)) aviso('presupuesto', 'Los umbrales deben cumplir 1 ≤ aviso < límite ≤ 100.');
    else {
      const e = estadoPresupuesto(g, l, a, t), d = disponible(g, l), p = porcentajeUso(g, l);
      const msg = d >= 0n ? `Te quedan ${pesos(d)}` : `Superaste tu límite por ${pesos(-d)}`;
      const llegaste = e === 'EXCEDIDO' && d === 0n ? ' · «Llegaste a tu límite»' : '';
      o1.className = TEXTO_ESTADO[e].clase;
      o1.textContent = `Uso: ${porcentaje(p)} · Estado: ${TEXTO_ESTADO[e].texto}${llegaste} · ${l === 0n ? 'Sin porcentaje (límite 0)' : msg}`;
    }
    const i = leerPesos(v('ingresos')), gs = leerPesos(v('gastos')), m = leerPesos(v('meta'));
    const o2 = salida('tasa'); o2.className = '';
    if ([i, gs, m].includes(null) || m < 1n || m > 100n) aviso('tasa', 'Valores no válidos (meta entre 1 y 100).');
    else {
      const ta = tasaAhorro(i, gs), cumple = cumpleMetaAhorro(i, gs, m);
      o2.className = cumple ? 'logro' : '';
      o2.textContent = `Balance: ${pesos(balance(i, gs))} · Tasa: ${ta === null ? 'no calculable (sin ingresos)' : porcentaje(ta)} (truncada) · ${cumple ? 'Cumple tu meta de ahorro' : 'No alcanza la meta de ahorro'}`;
    }
    const ob = leerPesos(v('objetivo')), ah = leerPesos(v('ahorrado')), h = leerFecha(v('hoy')), f = leerFecha(v('fobj'));
    const o3 = salida('meta'); o3.className = '';
    if ([ob, ah].includes(null) || ob === 0n || !h || !f) aviso('meta', 'Revisa los valores y las fechas.');
    else {
      const ap = aporteMensual(ob, ah, h, f), prog = progresoMeta(ah, ob), meses = mesesRestantes(h, f);
      const estado = ah >= ob ? 'Meta cumplida' : meses === 0 ? 'Fecha vencida: ajusta la fecha' : `Aporte sugerido: ${pesos(ap)} al mes durante ${meses} ${meses === 1 ? 'mes' : 'meses'} (hasta ${fechaCorta(f)})`;
      o3.className = ah >= ob ? 'logro' : '';
      o3.textContent = `Progreso: ${porcentaje(prog)} · ${estado}`;
    }
  }
  sec.addEventListener('input', calcular);
  calcular();
  return sec;
}
