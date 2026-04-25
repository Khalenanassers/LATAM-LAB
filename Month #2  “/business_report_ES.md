# ¿Quién está a punto de irse?

**AI LATAM Lab · Mes 2 de 12**
*Autopsia vs. Alerta Temprana — del análisis reactivo a la inteligencia predictiva*

---

## La Pregunta que Te Estaba Costando Dinero No Hacerte

> *¿Cuáles clientes de postpago están por cancelar — y a quién llamo primero?*

La mayoría de los operadores de telecomunicaciones en América Latina se enteran de que un cliente se va cuando ese cliente llama para cancelar. Para ese momento, la relación ya terminó. El equipo ofrece un descuento. A veces funciona. Normalmente no.

Con inteligencia artificial — más específicamente, con machine learning — podemos predecir si un cliente va a irse. Con suficiente anticipación para que el equipo tenga un plan de defensa.

---

## ¿Qué es el Churn?

El **churn** es la tasa a la que los clientes dejan de hacer negocios con una empresa en un período determinado — lo opuesto a la retención (IBM, 2025). Existen dos tipos: **churn voluntario**, cuando un cliente decide activamente irse por precio, insatisfacción o una mejor oferta; y **churn involuntario**, cuando el cliente se va sin intención — un pago fallido, una tarjeta vencida, un contrato que expira sin renovarse. El churn involuntario representa entre el 20–40% de la deserción total dependiendo de la industria, y casi todo es prevenible (rethinkCX, 2025).

El modelo de negocio determina cuál tipo domina. En telecomunicaciones prepago en LATAM, el churn es mayormente competitivo y sin fricción — un nuevo SIM no cuesta nada. En **postpago**, el riesgo dominante es voluntario: clientes que están evaluando activamente sus opciones, sensibles al precio y a la calidad del servicio, pero que todavía pueden ser alcanzados antes de que tomen la decisión.

*Fuentes: IBM Think (2025) · rethinkCX (2025) · BNamericas*

---

## 1. El Contexto de Negocio

América Latina tiene **456 millones de suscriptores móviles en 2024** — una región donde la conectividad móvil es la columna vertebral de la vida cotidiana. También es uno de los mercados con mayor tasa de deserción en el mundo.

Cambiar de operador no cuesta casi nada. En México, el proceso de portabilidad tarda 24 horas. En Colombia, menos de 3 días. Las ofertas promocionales de Claro, Tigo y Movistar corren todo el año — y los clientes sensibles al precio las aprovechan.

**Los números detrás del problema:**

- El churn prepago en LATAM corre entre **37–62% anual** (BNamericas). Los operadores deben reemplazar toda su base de suscriptores prepago aproximadamente cada 21 meses.
- El churn anual en telecomunicaciones a nivel global oscila entre **20–50%** (CustomerGauge, 2024). Para una base de 1 millón de clientes con ARPU de $50, una tasa del 20% erosiona **$120 millones en ingresos recurrentes cada año**.
- Adquirir un nuevo cliente de telecomunicaciones cuesta **6–7 veces más** que retener uno existente. La economía de la retención no es una preferencia estratégica — es una cuestión de supervivencia.
- Un informe de McKinsey de 2024 estima que los modelos de churn con IA pueden reducir la deserción hasta en un **15%** cuando se aplican de forma proactiva.

El segmento postpago es donde esto duele más. Estos clientes generan mayor ingreso promedio por usuario (ARPU), es más probable que tengan contratos combinados (móvil + internet + TV), y son más difíciles de reemplazar. América Latina sigue siendo predominantemente un mercado prepago — México concentra el 32.3% de las suscripciones prepago de la región — pero la base postpago está creciendo, y cada cliente postpago perdido tiene un impacto desproporcionado en los ingresos.

> [!IMPORTANT]
> :rotating_light: **Nota de Gobernanza 1:** Antes de construir un modelo, pregúntate si realmente tienes un problema de churn.
>
> Revisa tu modelo de negocio primero. Telecomunicaciones prepago, SaaS, retail por suscripción — el churn se ve distinto en cada uno. Si tus clientes pueden irse sin avisarte, probablemente lo tengas.
>
> Si es así, todo lo que está en este notebook corre localmente en RStudio — gratis, sin cuenta en la nube. Cualquier LLM hoy puede generar el código. Esa no es la parte difícil.
>
> La parte difícil son las decisiones: qué métrica optimizar, dónde poner el umbral, qué significa la tasa de falsas alarmas para tus clientes. Eso se queda contigo. Usa la IA para ejecutar — pero tú haces las preguntas, tú cuestionas el resultado, y tú tomas la decisión.
>
> Especialmente si estás aprendiendo: el modelo no conoce tu negocio. Tú sí. Toma la decisión. Deja que la IA haga el trabajo.

---

## 2. Lo que los Datos Nos Dijeron

Analizamos 7,043 registros de clientes con 21 variables. Después de eliminar ruido estadístico (género, tipo de servicio telefónico) y resolver la multicolinealidad (descartando Cargos Totales, que es esencialmente una fórmula derivada del tiempo como cliente y el precio), identificamos cinco variables que predicen el churn con fuerza estadísticamente significativa.

### Principales Predictores de Churn

| Variable | Asociación con Churn (V de Cramér) | Traducción al Negocio |
|---|---|---|
| Tipo de Contrato | **0.41** | Mes a mes = sin compromiso, sin fricción para irse |
| Seguridad en Línea | 0.35 | Sin bundle de seguridad = menos integrado al ecosistema |
| Soporte Técnico | 0.34 | Problemas sin resolver son la gota que derrama el vaso |
| Tipo de Servicio de Internet | 0.32 | Los clientes de Fibra Óptica son volátiles y sensibles al precio |
| Método de Pago | 0.30 | El cheque electrónico se correlaciona con mayor riesgo de churn |

*La V de Cramér mide la asociación estadística entre variables categóricas y un objetivo binario. Rango: 0 (sin asociación) a 1 (asociación perfecta). Valores superiores a 0.30 se consideran significativos para la toma de decisiones de negocio.*

### Tres Patrones que Todo Gerente de Telecomunicaciones Debería Conocer

**Patrón 1 — La Trampa Mes a Mes**
Los clientes sin contrato anual tienen tasas de churn dramáticamente más altas. El contrato en sí mismo es tanto síntoma como causa: quienes no se han comprometido ya están evaluando alternativas. La llamada a la acción del equipo de retención no debería ser un descuento — debería ser una oferta para convertir a un plan anual.

**Patrón 2 — La Paradoja de la Fibra Óptica**
La Fibra es un producto premium, con precio acorde. Pero el precio premium viene con expectativas premium. Cuando hay una interrupción del servicio, o un competidor lanza una tarifa promocional, los clientes de Fibra son más propensos a irse que los de DSL — no menos. El precio crea vulnerabilidad, no lealtad.

**Patrón 3 — La Zona de Peligro de los Primeros 12 Meses**
El riesgo de churn es más alto en el primer año. Los clientes que aún no han construido historia con el operador todavía no tienen una razón para quedarse. El análisis de dependencia parcial del tiempo como cliente confirma un punto de inflexión claro: quienes superan el mes 12 muestran una probabilidad de churn sustancialmente menor. El primer año es donde la relación se gana o se pierde.

---

## 3. Diseño del Modelo

Antes de seleccionar un modelo, hay tres preguntas que todo equipo necesita responder. El siguiente marco las hace explícitas.

<img width="2752" height="1536" alt="unnamed" src="https://github.com/user-attachments/assets/43629f13-7e49-4f8c-8821-972fd911a62d" />

*Un marco práctico para la selección de modelos en predicción de churn. Tres bloques de construcción: ¿Qué estás prediciendo? ¿Cómo son tus datos? ¿Qué restricciones tienes?*

### Los Tres Bloques de Construcción

**Bloque 1 — ¿Qué estás prediciendo?**
Existen dos problemas de churn fundamentalmente distintos. *Predecir "SI"* — ¿se irá este cliente alguna vez? — es un problema de clasificación. *Predecir "CUÁNDO"* — ¿cuánto tiempo hasta que se vaya? — es un análisis de supervivencia / valor del ciclo de vida. Este proyecto resuelve el primero: una predicción binaria Sí/No de churn en el período actual. Para las PYMEs de LATAM con historial de datos limitado, la pregunta del "SI" entrega resultados más rápidos y accionables.

**Bloque 2 — ¿Cómo son tus datos?**
Nuestro conjunto de datos es tabular: tiempo como cliente, cargos mensuales, tipo de contrato, servicios adicionales. Esto descarta el aprendizaje profundo (diseñado para datos secuenciales como flujos de clics) y apunta claramente a algoritmos estándar construidos para perfiles estructurados de "Gasto y Tiempo".

**Bloque 3 — ¿Cuáles son las restricciones?**
El tamaño del conjunto de datos es de 7,043 filas — pequeño a mediano según los estándares de ML. En un despliegue real, aplica la legislación de protección de datos de LATAM. Estas restricciones informan directamente la elección del modelo: una herramienta costosa computacionalmente y hambrienta de datos es la herramienta equivocada aquí.

### Los Tres Enfoques Evaluados

**Regresión Logística — La Línea Base Transparente**
Asume que el comportamiento del cliente sigue una línea recta: "Cada dólar adicional en cargos mensuales aumenta la probabilidad de churn en X%." Fácil de auditar. Fácil de explicar a un regulador o a un ejecutivo no técnico. Tiene dificultades con perfiles complejos y superpuestos. Establece el piso de rendimiento.

**XGBoost — La Recomendación de Producción**
Construye 100 árboles de decisión secuenciales, cada uno corrigiendo los errores del anterior. Logra el mayor recall en este conjunto de datos. Para una campaña automatizada de bajo costo, este es el modelo correcto: maximiza el alcance, acepta las falsas alarmas, y deja que la economía de la campaña haga el trabajo.

**Random Forest — La Alternativa de Precisión**
Construye 500 árboles de decisión independientes y toma el voto mayoritario. Menos falsas alarmas (253 vs. 381), pero pierde 74 churners reales adicionales en el proceso. La elección correcta cuando la intervención de retención es costosa — llamadas VIP, créditos en cuenta de $50 — donde cada falsa alarma tiene un costo real.

### Por Qué Fijamos el Umbral en 30%

El umbral de clasificación estándar es 50% — un modelo marca a un cliente como "riesgo de churn" solo si tiene más del 50% de confianza. Ese es el umbral correcto cuando cada falsa alarma es costosa.

En un contexto de retención en telecomunicaciones, la lógica cambia. El costo de un correo automatizado o un 10% de descuento en la próxima factura es insignificante. El costo de perder un churner — perder sus ingresos recurrentes permanentemente — no lo es. Bajamos el umbral al 30% para lanzar una red más amplia, aceptando algunas falsas alarmas a cambio de capturar significativamente más churners reales a tiempo.

---

## 4. Resultados del Modelo

Todos los modelos fueron evaluados en un conjunto de prueba separado de 2,113 clientes, de los cuales 534 eran churners confirmados.

### Resumen de la Matriz de Confusión — Con Umbral del 30%

| Modelo | Exactitud | Churners Capturados | Churners Perdidos | Falsas Alarmas |
|---|---|---|---|---|
| Regresión Logística | 75.96% | 421 (78.8%) | 113 | 395 |
| Random Forest | 79.08% | 345 (64.6%) | 189 | 253 |
| **XGBoost** | **76.53%** | **419 (78.5%)** | **115** | **381** |

**Leyendo esta tabla:** XGBoost al 30% es la recomendación de producción — captura más churners (419 vs. 345 del Random Forest), pierde menos (115 vs. 189), y genera 381 falsas alarmas. En un contexto de campaña automatizada, esas falsas alarmas no son un costo — son clientes que no iban a irse y que acaban de recibir una oferta de retención. El peor resultado es un cliente un poco más contento. Los 74 churners adicionales que pierde el Random Forest representan ingresos recurrentes reales saliendo permanentemente. Además, la Regresión Logística tiene buenos resultados y puede usarse como punto de partida — XGBoost simplemente tiene un 3% menos de falsas alarmas.

---

## 5. Impacto en el Negocio

El modelo identificó **419 de 534 churners reales** en el conjunto de prueba — clientes que estaban a punto de irse y que ahora pueden ser contactados antes de que lo hagan.

Asumiendo que un 30% conservador responde a una oferta de retención. Con un ARPU (Ingreso Promedio por Usuario) de $45 y una vida útil promedio de 24 meses, eso representa **~126 clientes retenidos** y **~$136,000 en ingresos recurrentes protegidos**. La campaña automatizada cuesta aproximadamente $840 en ejecutarse.

**Eso es un retorno de 160 veces el gasto en campaña** — antes de que un solo humano levante el teléfono.

*Las cifras son ilustrativas y están basadas en supuestos promedio de la industria para telecomunicaciones postpago en LATAM. Aplica tu propio ARPU y tasa de retención para calibrar el modelo a tu mercado.*

---

## 6. A Quién Dirigirse Primero (otro resultado valioso del modelo)

El siguiente gráfico muestra cuánto contribuyó cada variable a las predicciones del modelo XGBoost — las características que más importan al decidir quién está en riesgo.

<img width="778" height="547" alt="image" src="https://github.com/user-attachments/assets/1478710f-6f89-4123-87c9-62dadc5d3cd5" />

El contrato mes a mes domina con una importancia de 0.43 — casi el doble del siguiente predictor. La señal es clara.

Esto se traduce directamente en un perfil de targeting. El cliente de mayor riesgo se ve así:

| Variable | Perfil de Riesgo |
|---|---|
| Contrato | Mes a Mes |
| Servicio de Internet | Fibra Óptica |
| Tiempo como Cliente | Menos de 12 meses |
| Método de Pago | Cheque electrónico |
| Soporte Técnico | Sin suscripción activa |

Los clientes que cumplen los cinco criterios son riesgos de fuga extremos. La llamada a la acción de retención para este segmento no debería ser un descuento en la factura — debería ser una oferta de conversión a un contrato anual. El descuento es el incentivo. El contrato es el resultado. Eso elimina el principal factor de churn por completo.

---

## 7. Qué Puede Salir Mal

Construir un modelo es fácil con IA. Desplegarlo responsablemente es donde empieza el trabajo real.

**Deriva del modelo.** Este modelo fue entrenado con datos de IBM Telco — un conjunto de datos de EE.UU. usado aquí con fines educativos y adaptado al contexto postpago de LATAM. El comportamiento de los clientes en Chile, México o Colombia puede tener patrones de estacionalidad distintos, curvas de elasticidad de precio diferentes y dinámicas competitivas propias. Vuelve a entrenar el modelo con datos locales al menos trimestralmente.

**Gobernanza del umbral.** El umbral del 30% es una decisión de negocio, no técnica. Debe ser revisado por alguien que entienda la estructura de costos de cada campaña de retención. A medida que los costos de campaña cambien — o que las condiciones macroeconómicas muevan el ARPU — el umbral correcto cambia con ellos.

**Falsas alarmas a escala.** Cada falsa alarma es un cliente que recibe una oferta de retención no solicitada. A pequeña escala, es inofensivo. A gran escala, puede sentirse intrusivo y crear la percepción de que la empresa está ansiosa — no confiada. Define una tasa máxima de falsas alarmas antes del lanzamiento.

**Privacidad de datos.** Incluso los modelos de comportamiento tienen implicaciones de privacidad. Conoce qué regulaciones de protección de datos aplican en tu mercado antes de desplegar en un CRM de producción. En Brasil: LGPD. En Colombia: Ley Habeas Data. En México: Ley Federal de Datos Personales en Posesión de los Particulares.

---

## 8. Por Dónde Empezar

> :pushpin: Esto no es una plantilla para copiar directamente — los números dependen de tu contexto. Pero si tienes un negocio por suscripción, algo de esto te resultará familiar.
>
> Primero, verifica si alguien en tu equipo puede ayudarte a configurarlo. RStudio es gratis, cualquier LLM puede escribir el código, y los datos probablemente ya están en tu CRM.
>
> Empieza con Regresión Logística. Es simple, transparente y explicable para cualquier persona en tu equipo. Familiarízate con los resultados, luego sube al modelo que se ajuste a tus datos y tu escala.

El modelo encuentra los nombres. Tú tomas la decisión.

Eso es el cambio de la autopsia a la alerta temprana.

---

*Parte de [AI LATAM Lab](https://github.com/Khalenanassers/LATAM-LAB) · Mes 2 de 12*
*Por [Khalena Nasser](https://linkedin.com/in/khalenanassers) · Business Intelligence & Strategy · Hamburgo*
*"Autopsia vs. Alerta Temprana — del análisis reactivo a la inteligencia predictiva"*
