# 04 · Lógica matemática

Cubre: RF-19, RF-20, RF-22, RF-23, RF-24, RF-25, RF-27, RF-29, RN-01 a RN-03, RN-06, RN-07, RN-08, RN-11 a RN-14, RN-16, RN-17, RNF-05, RNF-10.
Los ejemplos se comprueban con `docs/anexos/verificar_calculos.py` (35 casos, todos correctos).

## 1. Política única de números (resuelve INC-07)

| Aspecto | Regla |
|---|---|
| Moneda | COP. Los montos se guardan en `DECIMAL(15,2)` pero **siempre en pesos enteros** (escala `.00`); la BD rechaza centavos (`CHECK`). |
| Porcentajes mostrados | **Truncados** a entero (hacia cero). Nunca se muestra «80 %» si el valor real es 79,99 %. |
| Decisiones (estados, alertas, cumplimiento) | Se toman con el valor **exacto**, nunca con el porcentaje ya redondeado. Se calcula con producto cruzado (`100·G ≥ p·L`), sin división, para no depender de decimales. |
| Montos necesarios para cumplir una meta | Se redondean **hacia arriba** al peso. |
| Implementación | `BigDecimal` en Java; prohibido `double`/`float` para dinero. |
| Hora | Se guarda en UTC. Los meses y días se calculan en **America/Bogotá (UTC−5, sin horario de verano)**. |

## 2. Definiciones

| Símbolo | Significado |
|---|---|
| `G_c` | Gastos del mes en la categoría `c`: suma de `movimiento.monto` de categorías de tipo GASTO con `fecha_hora` dentro del mes local. |
| `L_c` | Límite mensual del presupuesto de `c` para ese mes (`presupuesto.limite_mensual`). |
| `a`, `p` | Umbrales del usuario para ese presupuesto: aviso (por defecto 80) y límite (por defecto 100). |
| `I`, `G` | Ingresos y gastos totales del mes (movimientos de categorías INGRESO y GASTO). |
| `O`, `S` | Monto objetivo de una meta y suma de sus abonos (`abono_meta`). |
| `M` | Meses restantes de una meta (F7). |

Solo cuentan movimientos **aprobados** (tabla `movimiento`). Los `movimiento_propuesto` no entran en ningún cálculo (RN-05).

## 3. Fórmulas

### F1 · Porcentaje de uso de un presupuesto (RN-01)
`uso_exacto = G_c / L_c` · **mostrado** `= trunc(100 · G_c / L_c)`, para `L_c > 0`.
Puede superar 100 (p. ej. 125 %).

### F2 · Estado del presupuesto (RN-02, RN-07)
| Condición (valor exacto) | Estado | Color |
|---|---|---|
| `100·G_c < a·L_c` | NORMAL | neutro |
| `a·L_c ≤ 100·G_c < p·L_c` | AVISO | naranja |
| `100·G_c ≥ p·L_c` | EXCEDIDO | rojo, siempre con acción sugerida (RW-06) |
| `L_c = 0` y `G_c = 0` | SIN_LIMITE | neutro: «sin límite definido» |
| `L_c = 0` y `G_c > 0` | EXCEDIDO | rojo con acción sugerida |

*Aclaración (INC-15):* con `p = 100` el estado EXCEDIDO empieza **al llegar** al límite (`G = L`). Para no afirmar algo falso, el texto es «Llegaste a tu límite» cuando `G = L` y «Superaste tu límite por $X» cuando `G > L`. El estado y el color son los mismos.
Restricción de datos: `1 ≤ a < p ≤ 100`.

### F3 · Balance disponible del mes (RN-05 original)
`B = I − G`. Puede ser negativo (se muestra con signo, sin usar rojo, porque el rojo se reserva a límites excedidos).

### F4 · Tasa de ahorro (RN-08)
`t = (I − G) / I`, mostrada truncada hacia cero. Si `I = 0` se muestra «no calculable».
Cumple la meta `m` del usuario (por defecto 20) si `100·(I − G) ≥ m·I` e `I > 0`. Verde solo cuando cumple.

### F5 · Aporte mensual de una meta (RN-03, RN-13, RN-14)
`A = ceil((O − S) / M)` al peso, para `S < O` y `M ≥ 1`.
- Si `S ≥ O`: meta **cumplida**, no hay aporte (RN-14).
- Si `M = 0` (fecha vencida): no se calcula; mensaje «Fecha vencida, ajusta la fecha» (RN-13).
- Como se redondea hacia arriba, la suma de `M` aportes puede superar `O` en menos de `M` pesos; el último aporte sugerido es el faltante real.

### F6 · Progreso de una meta
`progreso = min(100, trunc(100 · S / O))`. «Cumplida» no es una columna: se deduce de `S ≥ O` (evita datos contradictorios).

### F7 · Meses restantes de una meta (supuesto S-06)
`M = (año_obj − año_hoy)·12 + (mes_obj − mes_hoy) + 1` si `fecha_obj ≥ hoy`; `M = 0` si `fecha_obj < hoy`.
Cuenta el mes en curso como uno de los meses para ahorrar. *Supuesto S-06:* si el cliente prefiere no contarlo, cambia `+ 1` por `+ 0` y el resto no cambia.

### F8 · Límites de un mes en UTC (RNF-05)
Mes local `YYYY-MM` = `[YYYY-MM-01 05:00Z, siguiente-mes-01 05:00Z)`. Un movimiento a las 23:30 del 30-nov en Colombia se guarda como 04:30Z del 1-dic y **pertenece a noviembre**.

### F9 · Cupo de sincronización bancaria (RN-06, RNF-10)
`cupo_restante = 2 − #sincronizaciones del usuario con resultado EXITOSA o PARCIAL en el día local`.
Si `cupo_restante ≤ 0` el servidor rechaza la ejecución. Horarios programados (supuesto S-10): 06:00 y 18:00 hora Colombia. «Próxima disponible» es el siguiente horario libre, o las 06:00 del día siguiente si el cupo se agotó. Las ejecuciones FALLIDAS no consumen cupo (supuesto S-08, ver PA-09).

### F10 · Límites de exportación (RN-16)
PDF: `n ≤ 5.000` movimientos; Excel: `n ≤ 100.000`. Sobre el tope: se rechaza con mensaje y sugerencia de acotar el periodo.

### F11 · Seguridad de códigos SMS (RN-11)
| Regla | Cálculo |
|---|---|
| Vigencia | `vence_en = emitido_en + 5 min` |
| Reenvío | permitido si `ahora − emitido_en ≥ 60 s` |
| Intentos | al 5.º intento fallido el código se invalida |
| Bloqueo | tras 5 fallos acumulados o 5 reenvíos en 1 hora: `bloqueado_hasta = ahora + 15 min` |

### F12 · Posibles duplicados (RF-18)
- Movimiento manual: mismo monto, misma fecha local y misma categoría que uno existente → aviso y confirmación.
- Movimiento propuesto del banco: mismo monto y tipo que un movimiento aprobado con diferencia de fecha ≤ 1 día → marca «posible duplicado» **calculada al mostrar** (no se guarda). Supuesto S-11.

## 4. Ejemplos verificados

**Presupuesto de Alimentación (corrige INC-04).** Límite `L = 400.000`.
| Situación | Cálculo | Resultado |
|---|---|---|
| Gastado 364.000 | `100·364.000 / 400.000` | 91 % · AVISO |
| Se elimina un movimiento de 28.000 | `G = 336.000` → `100·336.000 / 400.000` | **84 %** · AVISO |
| Gastado 79.999 de 100.000 | 79,999 % | 79 % · NORMAL (no 80 %) |
| Gastado 80.000 de 100.000 | 80 % exacto | 80 % · AVISO, se dispara la alerta |
| Gastado 100.000 de 100.000 | 100 % exacto | EXCEDIDO · «Llegaste a tu límite» |
| Gastado 500.000 de 400.000 | 125 % | EXCEDIDO · «Superaste tu límite por $100.000» |

**Mes de ejemplo.** Ingresos 3.200.000 y gastos 2.560.000: balance 640.000; tasa `= 20 %`; cumple la meta del 20 % justo. Con gastos 2.560.001 ya no cumple.

**Meta.** Objetivo 3.000.000, ahorrado 450.000, fecha 31-mar-2027, hoy 17-nov-2026: `M = 5` y `A = ceil(2.550.000 / 5) = 510.000`; progreso 15 %.
**Con redondeo:** objetivo 1.000.000, ahorrado 0, fecha 31-ene-2027: `M = 3`, `A = ceil(333.333,33) = 333.334`.

## 5. Casos límite (todos tienen prueba en el anexo o en las pruebas de servicio)

| Caso | Comportamiento |
|---|---|
| Ingresos = 0 | Tasa «no calculable»; el balance sí se calcula |
| Límite = 0 | Sin %, estado según F2 (RN-07) |
| Gasto > límite | EXCEDIDO, rojo con acción |
| Meta con `S ≥ O` | Cumplida, sin aporte |
| Meta con fecha pasada | «Fecha vencida», sin aporte |
| Meta con fecha hoy | `M = 1` |
| Categoría eliminada con movimientos | Se reasignan antes de borrar (RN-09); los totales no cambian salvo que cambie de tipo |
| Cuenta recién creada | Todo en 0 / vacío; sin %, sin tasa, sin alertas |
| Movimiento propuesto sin aprobar | No suma a nada |
| Cambio de categoría de GASTO a otra GASTO | Recalcula `G` de ambas categorías |
| Alerta ya enviada ese mes para ese umbral | No se repite (RN-17); si el usuario baja y vuelve a cruzar, no se reenvía |
| Cambio de umbrales a mitad de mes | Aplica desde la siguiente evaluación; no genera alertas retroactivas |
| Mes sin presupuesto en la categoría | No hay estado; no se alerta |
| Tercera sincronización del día | Rechazada por el servidor |
| Exportación sobre el tope | Rechazada con mensaje (RN-16) |

## 6. Verificación
Ejecutar `python3 docs/anexos/verificar_calculos.py`. Todo cambio de fórmula debe actualizar el anexo y esta tabla en el mismo Pull Request.
