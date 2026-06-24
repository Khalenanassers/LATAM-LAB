# ¿Podemos verlo venir?

**AI LATAM Lab · Mes 3 de 12**
*Autopsia vs. Alerta Temprana — de la inteligencia reactiva a la predictiva*

---

## La Pregunta

> *"Sé que voy a quedar corto de efectivo. Lo que no sé es cuándo — hasta que ya es demasiado tarde para llamar a mi proveedor."*

Este mes construimos un sistema de alerta temprana para Distribuidora VIVA — un distribuidor de alimentos y bebidas de tamaño mediano que opera en toda Latinoamérica. La pregunta no es si la próxima brecha de efectivo va a ocurrir. Va a ocurrir. La pregunta es si podemos verla llegar con 2–3 meses de anticipación.

---

## El Contexto

La cultura de pagos en América Latina no está rota — simplemente es lenta. Según la Encuesta de Comportamiento de Pagos de Coface 2025 (300+ empresas en seis países): el plazo de pago promedio B2B es **59 días**, el **77% de las empresas** reporta pagos tardíos, y el retraso promedio adicional es de **42 días**.

El efectivo de una venta llega en aproximadamente 3 meses. La factura del proveedor llega en 2. Esa diferencia de un mes es donde vive la crisis.

VIVA queda corta en cuatro meses de cada 24. No porque el negocio falle. Porque el timing es estructural, predecible y prevenible.

<img width="1570" height="962" alt="image" src="https://github.com/user-attachments/assets/71ecfe81-e04d-4d1c-bb51-1c924f67ec76" />

*Zonas en rojo = meses con efectivo neto negativo. Ambos clústeres tienen el mismo origen: las facturas de COGS llegan antes que los cobros de la temporada alta.*

---

## Lo Que Los Datos Revelaron

Construimos una serie de flujo de caja de 24 meses usando datos reales de facturas (UCI Online Retail II, adaptados al contexto LATAM) con egresos sintéticos calibrados con benchmarks del BID, Banco Mundial y CEPAL.

Ambos clústeres de crisis siguen el mismo patrón. Las ventas de temporada alta generan facturas de proveedores 2 meses después — pero el efectivo de esas ventas no llega hasta 3 meses después, porque los clientes pagan tarde. La factura llega antes que el dinero. Este es un problema de timing. Y los problemas de timing son predecibles.

La serie se descompone en una tendencia levemente descendente (el colchón de efectivo se reduce lentamente), un ritmo estacional anual fuerte (picos en enero, mínimos en abril–mayo) y ruido. La posición de efectivo es estacionaria — las crisis son shocks recurrentes dentro de un proceso estable, no una espiral descendente.

---

## Cuatro Modelos, Un Ganador

Ejecutamos cuatro enfoques de pronóstico, cada uno con una filosofía distinta. El objetivo no era el mejor algoritmo — era la respuesta más honesta.

<img width="2320" height="1785" alt="image" src="https://github.com/user-attachments/assets/0b4046a2-89b6-4fe2-8106-39d5617fec71" />

| Métrica | Lógica Negocio | Regresión Fourier | Prophet | ARIMA(1,0,2) |
|---|---|---|---|---|
| MAE | **€37k** | €74k | €67k | €97k |
| R² | **0.880** | 0.550 | 0.585 | 0.296 |
| F1 (detección de crisis) | **1.000** | 0.571 | 0.857 | 0.667 |
| Falsas alarmas | **0** | 1 | 0 | **0** |
| Sesgo general (PBIAS) | **-0.6%** ✓ | 0.0% | -0.1% ✓ | +6.0% ⚠️ |
| Sesgo en meses de crisis | **-€71k** ✓ | +€128k ⚠️ | +€112k ⚠️ | +€164k ⚠️ |

**Lógica de Negocio** — aritmética pura con benchmarks de Coface y del BID, sin ajuste — supera a todos los modelos ML y estadísticos en todas las métricas. Con 24 observaciones y un mecanismo conocido, codificar la lógica de negocio directamente supera a intentar aprenderla de datos limitados.

**El hallazgo de sesgo es el argumento más fuerte.** La Lógica de Negocio es el único modelo pesimista en meses de crisis — cuando las cosas van mal, predice que son peores de lo que realmente son (por €71k en promedio). Eso es exactamente lo que un sistema de alerta temprana debe hacer. Todos los demás modelos son optimistas en meses de crisis (por €112k–€164k), subestimando sistemáticamente el peligro justo cuando la alerta necesita activarse.

**Prophet** es el mejor modelo basado en datos (F1=0.857, cero falsas alarmas), pero su sesgo optimista en crisis suaviza la alarma. **Regresión de Fourier** conecta ambos enfoques con términos sin/cos interpretables ajustados por MCO. **ARIMA(1,0,2)** reemplazó al SARIMA original — el término MA estacional generaba falsas alarmas porque 24 meses no es suficiente para una estructura estacional de 12 meses.

---

## Pronóstico a 3 Meses

| Mes | Lógica Negocio | Prophet | Regresión Fourier | ARIMA(1,0,2) |
|---|---|---|---|---|
| Ene 2027 | €199k | €424k | €379k | €225k |
| Feb 2027 | €85k | €292k | €251k | €45k |
| Mar 2027 | €174k | €60k | €74k | €100k |

El pronóstico puntual de ningún modelo cae por debajo de cero. Pero la Lógica de Negocio muestra febrero reduciéndose a €85k, y Prophet muestra marzo por debajo de €100k con intervalos de confianza en territorio negativo. Los modelos no coinciden en dónde exactamente está el riesgo. Coinciden en que existe.

---

## Qué Puede Salir Mal

**Deriva del modelo.** Los datos subyacentes son de un mayorista del Reino Unido adaptados a un escenario LATAM. Los negocios reales enfrentan fluctuaciones cambiarias, crédito informal y patrones estacionales locales. Calibra con tus propios números.

**Tamaño de muestra.** 24 meses es el mínimo, no el ideal. El ARIMA puro funciona a esta escala — la capa estacional del SARIMA no. Más historia mejora todos los modelos.

**Meses estimados.** Enero y febrero de 2025 son valores estimados (ratio YoY mediano de meses limpios superpuestos), no datos directos. Supuesto documentado.

**Colchón de seguridad.** El umbral p10 (€-84k) es un punto de partida. El colchón correcto depende del costo de actuar temprano versus actuar tarde. Revísalo cada trimestre.

---

## La Regla del Lunes por la Mañana

> 📌 La Lógica de Negocio muestra febrero 2027 con un margen de €85k — el punto más estrecho en los próximos 3 meses. Prophet y la Regresión de Fourier muestran marzo por debajo de €100k.
>
> Ningún modelo está gritando crisis. Todos están diciendo: el margen se reduce.
>
> **"Tienes 2 meses. Llama a tu proveedor. El costo de esta conversación es cero. El costo de no tenerla es una línea de crédito de emergencia al 18%."**

El modelo encuentra la ventana. Tú haces la llamada.

---

*Parte del [AI LATAM Lab](https://github.com/Khalenanassers/LATAM-LAB) · Mes 3 de 12*
*Por [Khalena Nasser](https://linkedin.com/in/khalenanassers) · Business Intelligence & Strategy · Hamburgo*
