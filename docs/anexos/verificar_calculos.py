#!/usr/bin/env python3
"""Verifica los ejemplos numéricos de docs/04-logica-matematica.md.
Usa Decimal y aritmética entera para evitar errores de coma flotante.
Ejecutar: python3 docs/anexos/verificar_calculos.py
"""
from decimal import Decimal, ROUND_DOWN, ROUND_CEILING
from datetime import date, datetime, timezone, timedelta

D = Decimal
TRUNC = ROUND_DOWN      # truncamiento hacia cero (RN-01)
CEIL = ROUND_CEILING    # hacia arriba al peso (RN-03)

def pct_mostrado(gastado, limite):
    """F1: porcentaje de uso mostrado, truncado a entero. limite > 0."""
    return int((D(100) * D(gastado) / D(limite)).to_integral_value(TRUNC))

def estado_presupuesto(gastado, limite, aviso=80, tope=100):
    """F2: compara con el valor EXACTO (producto cruzado, sin redondeo)."""
    g, l = D(gastado), D(limite)
    if l == 0:
        return "SIN_LIMITE_EXCEDIDO" if g > 0 else "SIN_LIMITE"
    if 100 * g >= tope * l:
        return "EXCEDIDO"
    if 100 * g >= aviso * l:
        return "AVISO"
    return "NORMAL"

def tasa_ahorro(ingresos, gastos):
    """F4: (I-G)/I truncada hacia cero; None si I = 0 (RN-08)."""
    i, g = D(ingresos), D(gastos)
    if i == 0:
        return None
    return int((D(100) * (i - g) / i).to_integral_value(TRUNC))

def cumple_meta_ahorro(ingresos, gastos, meta_pct=20):
    i, g = D(ingresos), D(gastos)
    return i > 0 and 100 * (i - g) >= meta_pct * i

def meses_restantes(hoy, fecha_objetivo):
    """F7: meses calendario, contando el mes actual. 0 si la fecha ya pasó."""
    if fecha_objetivo < hoy:
        return 0
    return (fecha_objetivo.year - hoy.year) * 12 + (fecha_objetivo.month - hoy.month) + 1

def aporte_mensual(objetivo, ahorrado, hoy, fecha_objetivo):
    """F5: ceil((O-S)/M) al peso. None si cumplida (RN-14) o vencida (RN-13)."""
    o, s = D(objetivo), D(ahorrado)
    if s >= o:
        return None
    m = meses_restantes(hoy, fecha_objetivo)
    if m <= 0:
        return None
    return int(((o - s) / D(m)).to_integral_value(CEIL))

def progreso_meta(ahorrado, objetivo):
    """F6: porcentaje truncado, tope 100 en pantalla."""
    return min(100, int((D(100) * D(ahorrado) / D(objetivo)).to_integral_value(TRUNC)))

def limites_mes_utc(anio, mes):
    """F8: mes local America/Bogota (UTC-5, sin horario de verano) -> [ini, fin) en UTC."""
    ini = datetime(anio, mes, 1, 5, 0, tzinfo=timezone.utc)
    fin = datetime(anio + (mes == 12), 1 if mes == 12 else mes + 1, 1, 5, 0, tzinfo=timezone.utc)
    return ini, fin

# ---------------------------------------------------------------- pruebas
casos = []
def ok(nombre, obtenido, esperado):
    casos.append((nombre, obtenido, esperado, obtenido == esperado))

# F1 / INC-04: ejemplo corregido (límite 400.000)
ok("F1 uso 196.000/200.000", pct_mostrado(196000, 200000), 98)
ok("F1 uso 168.000/200.000 (tras borrar 28.000, Figma)", pct_mostrado(168000, 200000), 84)
ok("F13 disponible 200.000-168.000", D(200000) - D(168000), D(32000))
ok("F1 Ocio 118.000/100.000 (Figma)", pct_mostrado(118000, 100000), 118)
ok("F1 uso truncado 79,99%", pct_mostrado(79999, 100000), 79)
ok("F1 uso 0 gastado", pct_mostrado(0, 500000), 0)
# F2 estados
ok("F2 79,99 % -> NORMAL", estado_presupuesto(79999, 100000), "NORMAL")
ok("F2 80,00 % -> AVISO", estado_presupuesto(80000, 100000), "AVISO")
ok("F2 99,99 % -> AVISO", estado_presupuesto(99999, 100000), "AVISO")
ok("F2 100,00 % -> EXCEDIDO", estado_presupuesto(100000, 100000), "EXCEDIDO")
ok("F2 umbrales 70/90, 72 % -> AVISO", estado_presupuesto(72, 100, 70, 90), "AVISO")
ok("F2 límite 0 sin gasto", estado_presupuesto(0, 0), "SIN_LIMITE")
ok("F2 límite 0 con gasto", estado_presupuesto(1000, 0), "SIN_LIMITE_EXCEDIDO")
# F3 balance
ok("F3 balance", D(3200000) - D(2150000), D(1050000))
# F4 tasa de ahorro
ok("F4 tasa 3.200.000 / 2.560.000", tasa_ahorro(3200000, 2560000), 20)
ok("F4 tasa 3.200.000 / 2.559.999 (truncada)", tasa_ahorro(3200000, 2559999), 20)
ok("F4 tasa gasta más que ingreso", tasa_ahorro(1000000, 1250000), -25)
ok("F4 ingreso 0 -> no calculable", tasa_ahorro(0, 500000), None)
ok("F4 Inicio del Figma: 1.240.500/3.200.000 se muestra 38 (no 39)", tasa_ahorro(3200000, 1959500), 38)
ok("F4 cumple meta 20 % justo", cumple_meta_ahorro(3200000, 2560000), True)
ok("F4 no cumple con 19,99 %", cumple_meta_ahorro(3200000, 2560001), False)
# F7 meses restantes
hoy = date(2026, 11, 17)
ok("F7 mismo mes (30-nov-2026)", meses_restantes(hoy, date(2026, 11, 30)), 1)
ok("F7 31-dic-2026", meses_restantes(hoy, date(2026, 12, 31)), 2)
ok("F7 31-mar-2027", meses_restantes(hoy, date(2027, 3, 31)), 5)
ok("F7 fecha vencida", meses_restantes(hoy, date(2026, 11, 16)), 0)
ok("F7 hoy mismo", meses_restantes(hoy, hoy), 1)
# F5 aporte
ok("F5 aporte exacto", aporte_mensual(3000000, 450000, hoy, date(2027, 3, 31)), 510000)
ok("F5 aporte con redondeo arriba", aporte_mensual(1000000, 0, hoy, date(2027, 1, 31)), 333334)
ok("F5 meta cumplida", aporte_mensual(1000000, 1000000, hoy, date(2027, 1, 31)), None)
ok("F5 fecha vencida", aporte_mensual(1000000, 100000, hoy, date(2026, 11, 1)), None)
# F6 progreso
ok("F6 progreso 450.000/3.000.000", progreso_meta(450000, 3000000), 15)
ok("F6 progreso tope 100", progreso_meta(3500000, 3000000), 100)
ok("F6 progreso truncado 99,99", progreso_meta(2999999, 3000000), 99)
# F8 límites de mes en UTC
ini, fin = limites_mes_utc(2026, 11)
ok("F8 inicio nov-2026 UTC", ini.isoformat(), "2026-11-01T05:00:00+00:00")
ok("F8 fin nov-2026 UTC", fin.isoformat(), "2026-12-01T05:00:00+00:00")
ini, fin = limites_mes_utc(2026, 12)
ok("F8 fin dic-2026 UTC", fin.isoformat(), "2027-01-01T05:00:00+00:00")
# Movimiento a las 23:30 hora Colombia del 30-nov = 04:30 UTC del 1-dic -> pertenece a noviembre
mov = datetime(2026, 12, 1, 4, 30, tzinfo=timezone.utc)
ini, fin = limites_mes_utc(2026, 11)
ok("F8 23:30 del 30-nov (Colombia) cae en noviembre", ini <= mov < fin, True)

malos = [c for c in casos if not c[3]]
for n, o, e, b in casos:
    print(("OK  " if b else "FALLA"), n, "->", o, "" if b else f"(esperado {e})")
print(f"\n{len(casos) - len(malos)}/{len(casos)} casos correctos")
raise SystemExit(1 if malos else 0)
