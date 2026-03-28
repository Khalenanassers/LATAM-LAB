# Deja de alimentar el basurero
## Cómo un modelo de pronóstico gratuito recupera $15.000 al mes en pérdidas de perecederos — en una sola tienda

> América Latina tiene la tasa de desperdicio en retail más alta del mundo: el 17% del producto se pierde antes de llegar al consumidor. Una tienda en Quito perdía más de $1,4M en frutas y verduras dañadas — no porque la demanda fuera impredecible, sino porque quienes hacían los pedidos no reaccionaban a ella con suficiente rapidez. Un modelo de pronóstico, construido en una semana con herramientas de código abierto, reduce ese desperdicio un 43% en los primeros 30 días. Así es exactamente cómo — y por qué tú también puedes hacerlo.

---

## 🎯 Contexto del negocio

Cada supermercado en América Latina hace el mismo cálculo silencioso: pedir suficiente para no quedarse sin stock, aceptar que algo se va a dañar. Parece el costo inevitable del negocio.

No lo es. Es un problema de decisiones.

La región produce suficiente alimento para abastecerse y exportar al mundo — y aún así, **el 15% de la producción alimentaria total de América Latina y el Caribe se pierde o desperdicia** a lo largo de la cadena de suministro (BID / FAO). De todas las etapas donde ocurre ese desperdicio, el retail es donde la región está más expuesta: **América Latina tiene la tasa de desperdicio en el comercio minorista más alta de cualquier región del mundo, con un 17%** — por encima de Europa, Norteamérica y Asia (Journal of Consumer Protection and Food Safety, 2025). Y aunque su peso económico global es limitado, la región genera **el 20% de toda la pérdida alimentaria mundial entre la postcosecha y el retail** (FAO) — una proporción desproporcionada.

El argumento de negocio para resolverlo es contundente: por cada **$1 invertido** en reducción de desperdicio alimentario, el retorno promedio es de **$14 en ahorro de costos** (Banco Mundial / FAO).

La Tienda 47 — una sucursal insignia de Supermaxi en Quito — generó un estimado de **$1,46M en pérdidas de perecederos** durante el período de análisis. No porque los clientes fueran impredecibles. Sino porque el sistema de pedidos no los estaba escuchando.

Este proyecto construye un modelo de pronóstico que sí los escucha — y cuantifica exactamente cuánto vale eso.

---

## 📙 Informe de negocio

### El problema en números concretos

El retail de alimentos en América Latina opera con márgenes netos de 2 a 3%. En ese entorno, cada dólar de desperdicio no es una molestia — es un golpe directo a la utilidad.

El departamento de Producidos de la Tienda 47 generó un estimado de **$1,46M en pérdidas** a lo largo del período de análisis. Solo tres productos acumularon más de $235.000:

| Producto | Pérdida estimada |
|---|---:|
| Plátano (Maqueño) | $92.983 |
| Tomate (Riñón) | $76.257 |
| Durazno Amarillo | $66.749 |
| Sandía | $58.282 |
| Banano Verde (Orito) | $37.505 |

Este es el desajuste clásico entre ventas y utilidad: los pasillos que más venden no son los que destruyen el margen. Los que destruyen el margen son los que tienen la vida útil más corta.

---

### Tres hallazgos que cambian cómo piensas sobre los pedidos

Antes de construir cualquier modelo, corrimos pruebas estadísticas formales para entender *por qué* ocurre el desperdicio. Los resultados desmantelaron varios supuestos comunes.

**1. La reacción humana a la demanda es más volátil que la demanda misma.**

Medimos la variabilidad usando el Coeficiente de Variación (CV) — un índice que indica qué tan errático es un número en relación con su promedio.

- CV de la demanda del cliente: **0,33** (relativamente estable)
- CV del desperdicio generado por los pedidos: **0,52** (altamente errático)

No es el cliente quien introduce el caos en el inventario. Es la decisión de pedido. Ese es el problema que vale la pena resolver.

**2. Los días lentos son los más peligrosos.**

La prueba de correlación de Pearson confirmó una relación inversa fuerte entre las ventas diarias y el desperdicio diario. Cuando menos clientes compran, los gerentes no piden menos — piden para el fin de semana concurrido que esperan. El exceso se queda en el estante y se daña.

**3. El jueves siempre es el peor día — y podemos predecirlo.**

El análisis ANOVA confirmó que el desperdicio no se distribuye de forma aleatoria durante la semana. Los gerentes piden de más anticipando el pico del sábado y domingo. Para el jueves, ese colchón lleva cuatro días en estante. El resultado es un pico de desperdicio semanal predecible — el mismo día, todas las semanas.

Los problemas predecibles son problemas solucionables.

> [!IMPORTANT]
>  *Nota de gobernanza #1:* Cuando las decisiones de pedido son informales, no documentadas e invisibles para la gerencia, no hay manera de auditarlas, mejorarlas ni rendirle cuentas a nadie. Un modelo de pronóstico no solo mejora la precisión — hace que el proceso de toma de decisiones sea transparente.

---

### Por qué rechazamos el modelo de IA "más preciso"

Evaluamos seis métodos de pronóstico contra la línea base del gerente. La primera ronda fue de precisión pura.

| Modelo | Precisión | MAPE | MAE (Unidades) | RMSE | Sesgo |
|---|---:|---:|---:|---:|---:|
| **Random Forest** | **91,87%** | **8,13%** | 454,69 | 571,49 | +0,65% |
| Holt-Winters | 91,14% | 8,86% | 499,79 | 669,28 | -2,00% |
| FB Prophet | 91,08% | 8,92% | 473,67 | 594,75 | +5,72% |
| Gerente (repite últimos 7 días) | 90,92% | 9,08% | 515,15 | 657,51 | -3,02% |
| Promedio 30 días | 79,79% | 20,21% | 1.053,05 | 1.238,86 | +7,61% |
| Regresión Lineal | 54,41% | 45,59% | 2.341,06 | 2.559,12 | +40,69% |

Random Forest gana en MAPE. Aun así, no lo elegimos. Aquí está el motivo.

<img width="2684" height="885" alt="image" src="https://github.com/user-attachments/assets/0f25beda-1164-430d-a9ff-429ea0936f11" />

Todo modelo descansa sobre supuestos estadísticos sobre cómo se comportan sus errores. Antes de confiar en un modelo en producción, se verifican esos supuestos — igual que compruebas que tienes todos los ingredientes antes de cocinar una receta. Random Forest falló en dos de ellos:

- **Heterocedasticidad** (prueba de Levene): sus errores crecían de forma impredecible en condiciones de alto volumen — exactamente cuando más importa la precisión.
- **Distribución no normal de errores** (prueba de Shapiro-Wilk): sus residuales estaban sesgados, lo que hace que sus métricas de precisión reportadas sean poco confiables.

Un modelo que viola estos supuestos no solo tiene errores más grandes — tiene errores *impredecibles*. Un gerente que lo use durante una semana festiva estaría tomando decisiones a ciegas, con una falsa confianza basada en un número de ranking.

**Holt-Winters**, en cambio, mostró errores consistentes y simétricos — una campana limpia. Capturó la estacionalidad semanal de 7 días con claridad. Su leve sesgo negativo (-2%) significa que prefiere dejar el estante levemente corto antes que enterrarlo en desperdicio.

En gestión de cadena de suministro, un error predecible y estable vale más que uno brillante que falla sin aviso.

> **Sobre la línea base del gerente:** El 90,92% de precisión del gerente parece respetable — pero es un artefacto de los datos. La fuerte ciclicidad semanal infla la precisión de cualquier método que repita la semana anterior. En condiciones reales con shocks de demanda irregulares — feriados, clima, promociones, caídas del precio del petróleo — este enfoque falla de forma repentina y sin advertencia.

---

### Los números que importan

<img width="3571" height="1911" alt="image" src="https://github.com/user-attachments/assets/98dd23a0-7677-4dfa-ab69-f48b586d1523" />

**Piloto de 30 días — Tienda 47**

| | Situación actual | Con Holt-Winters | Diferencia |
|---|---:|---:|---:|
| Costo de desperdicio | $35.925 | $20.460 | **-$15.465** |
| Reducción | — | — | **-43%** |

**Proyección anualizada — red de 54 tiendas**

| Escenario | Ahorro anual estimado |
|---|---:|
| Las 54 tiendas adoptan Holt-Winters | **$10.021.388** |

Estas cifras son conservadoras. El piloto de 30 días usó solo el departamento de Producidos. Panadería, lácteos y carnes tienen perfiles de desperdicio comparables o más altos.

---

### ¿Puedes construir esto tú mismo?

Sí. Esto importa más que la selección del modelo.

El analytics de alto impacto no requiere un presupuesto en la nube ni un equipo de ciencia de datos. En 2026, la barrera de entrada es más baja que nunca.

**La tecnología: gratuita.**
Todo este proceso corre en Python y SQLite dentro de Jupyter Notebook — herramientas de código abierto que funcionan en cualquier computadora de oficina. Sin licencias. Sin tarifas de nube. Sin contratos con proveedores.

**El modelo: transparente.**
Holt-Winters fue elegido no solo porque funcionó bien, sino porque sus supuestos son visibles y verificables. Antes de implementarlo, confirmas que se cumplen con tus propios datos. Un modelo que puedes explicarle a tu gerente de operaciones es un modelo que realmente puedes usar.

**El asistente de IA: opcional pero poderoso.**
No necesitas programar esto desde cero. Toma tus datos de ventas, prepara el contexto del negocio y llévalo a cualquier LLM (este análisis usó Gemini 2.5 Pro vía Google AI Studio — nivel gratuito). Pídele que te guíe paso a paso en la implementación.

Pero cuestionalo. Pregunta por qué. Pone en duda los supuestos del modelo. Tu conocimiento del negocio no es reemplazable — es la razón por la que el resultado es útil. El objetivo no es automatizar tu juicio. Es darle a tu juicio mejores insumos.

> ⚠️ **Un requisito previo crítico:** La calidad de los datos no es negociable. Si tus registros de ventas tienen vacíos, mapeos inconsistentes de SKU o devoluciones sin corregir, no empieces con modelos. Empieza por los datos. Un modelo con 91% de precisión sobre datos malos sigue siendo un modelo malo.

---

### La regla del lunes en la mañana

**Esta semana:** Toma tus 10 productos perecederos con mayor volumen de ventas. Calcula la desviación estándar de los pedidos diarios para cada uno. Si la variabilidad en tus *pedidos* es mayor que la variabilidad en tus *ventas*, tienes un problema de pedidos generado por humanos — no un problema de demanda. Esa es la señal. Este análisis muestra qué hacer a continuación.

> [!IMPORTANT]
>   *Nota de gobernanza #2:* Sobre las herramientas de código abierto y tus datos. Todas las bibliotecas utilizadas en este proyecto —Python, SQLite, pandas, statsmodels, Prophet— son de código abierto. Esto significa que el código es de acceso público, se puede auditar libremente y lo mantienen comunidades de todo el mundo. No hay cajas negras. Todo el análisis se ejecuta localmente. No hay llamadas a la API de servidores externos. No hay almacenamiento en la nube. Ningún proveedor tiene acceso a su historial de transacciones. SQLite es un archivo en su ordenador: no va a ningún sitio a menos que usted lo envíe a algún lugar. El código abierto elimina el riesgo asociado al proveedor. No elimina el requisito de gobernanza. Alguien de la organización debe comprender qué hace el modelo, comprobar sus supuestos periódicamente y asumir la responsabilidad de la decisión de actuar en función de sus previsiones.

Traducción realizada con la versión gratuita del traductor DeepL.com
---


[← Volver al README de la serie](../README.md) 
