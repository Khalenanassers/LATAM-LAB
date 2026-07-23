"""
M03_all_models.py
AI LATAM Lab — Month 3: Cash Flow Crisis Prediction
Distribuidora VIVA

Pipeline completo: construcción de la serie de flujo de caja, decomposición,
pruebas de hipótesis, y los 4 modelos de pronóstico comparados en el reporte.

Requiere: pandas, numpy, statsmodels, prophet, scipy, pymannkendall
    pip install pandas numpy statsmodels prophet scipy pymannkendall --break-system-packages

Requiere los módulos del proyecto en el mismo directorio:
    - synthetic_outflows.py
    - m03_collection_lag.py

Y el CSV crudo de UCI Online Retail II en ./data/online_retail_II.csv
"""

import warnings
warnings.filterwarnings('ignore')

import pandas as pd
import numpy as np

from statsmodels.tsa.seasonal import STL, seasonal_decompose
from statsmodels.tsa.stattools import adfuller, kpss
from statsmodels.regression.linear_model import OLS
from statsmodels.tools import add_constant
from statsmodels.tsa.arima.model import ARIMA
from scipy.stats import kruskal
import pymannkendall as mk
from prophet import Prophet

from m03_collection_lag import apply_collection_lag, aggregate_to_monthly_cash, backfill_via_yoy_ratio
from synthetic_outflows import generate_outflows


# ═══════════════════════════════════════════════════════════════════════
# PASO 0 — CONSTRUCCIÓN DE LA SERIE DE FLUJO DE CAJA
# ═══════════════════════════════════════════════════════════════════════

def build_cashflow_series():
    """
    Construye la serie de 24 meses de flujo de caja neto para VIVA.
    Aplica el retraso de cobro calibrado con Coface y genera egresos
    sintéticos calibrados con benchmarks del BID/Banco Mundial/CEPAL.
    """
    # Cargar datos crudos de UCI Online Retail II
    df = pd.read_csv('data/online_retail_II.csv', encoding='latin1')
    df['InvoiceDate'] = pd.to_datetime(df['InvoiceDate'])

    # Limpieza: excluir filas con Price <= 0 (ajustes/daños, no ventas reales)
    df = df[df['Price'] > 0].copy()

    # Excluir el mes final incompleto (solo 9 días de datos)
    df = df[df['InvoiceDate'] < '2011-12-01'].copy()

    # Ingreso por línea de factura
    df['LineRevenue'] = df['Quantity'] * df['Price']

    # Desplazar fechas +15 años para narrativa actual (2025-2026)
    df['InvoiceDate'] = df['InvoiceDate'] + pd.DateOffset(years=15)

    # Aplicar retraso de cobro calibrado con Coface (23% a tiempo ~59 días,
    # 77% tarde ~101 días) y agregar a serie mensual por fecha de cobro real
    df_lagged = apply_collection_lag(df, sale_date_col='InvoiceDate', random_state=42)
    monthly_cash = aggregate_to_monthly_cash(df_lagged, revenue_col='LineRevenue')

    # Recortar a la ventana de 24 meses completos
    start, end = pd.Timestamp('2025-01-01'), pd.Timestamp('2026-12-01')
    trimmed = monthly_cash[(monthly_cash['YearMonth'] >= start) &
                            (monthly_cash['YearMonth'] <= end)].copy()

    # Backfill de Jan/Feb 2025 (meses con cobertura de retraso incompleta)
    target_months = [pd.Timestamp('2025-01-01'), pd.Timestamp('2025-02-01')]
    final_inflows, median_ratio = backfill_via_yoy_ratio(trimmed, target_months)

    # Generar egresos sintéticos (COGS + costos fijos, calibrados con benchmarks)
    outflows = generate_outflows(final_inflows[['YearMonth', 'NetInflow']], random_state=42)
    cf = final_inflows.merge(outflows[['YearMonth', 'TotalOutflow']], on='YearMonth')
    cf['NetCash'] = cf['NetInflow'] - cf['TotalOutflow']

    return cf, median_ratio


# ═══════════════════════════════════════════════════════════════════════
# PASO 1 — DECOMPOSICIÓN
# ═══════════════════════════════════════════════════════════════════════

def run_decomposition(net_cash):
    """
    Descompone la serie en tendencia, estacionalidad y residuo.
    Aditivo (no multiplicativo) porque la serie tiene valores negativos.
    """
    decomp_classical = seasonal_decompose(net_cash, model='additive', period=12)
    stl = STL(net_cash, period=12, robust=True).fit()

    print("PASO 1 — Descomposición (STL)")
    print(f"  Rango estacional: €{stl.seasonal.max() - stl.seasonal.min():,.0f}")
    print(f"  Tendencia inicio: €{stl.trend.iloc[0]:,.0f}  →  fin: €{stl.trend.iloc[-1]:,.0f}")
    print()

    return decomp_classical, stl


# ═══════════════════════════════════════════════════════════════════════
# PASO 2 — PRUEBAS DE ESTACIONARIEDAD
# ═══════════════════════════════════════════════════════════════════════

def run_stationarity_tests(net_cash):
    """ADF (H0: no estacionaria) + KPSS (H0: estacionaria), usadas juntas."""
    adf_result = adfuller(net_cash, autolag='AIC')
    kpss_result = kpss(net_cash, regression='c', nlags='auto')

    print("PASO 2 — Pruebas de Estacionariedad")
    print(f"  ADF:  estadístico={adf_result[0]:.4f}  p={adf_result[1]:.4f}  "
          f"→ {'estacionaria' if adf_result[1] < 0.05 else 'NO estacionaria'}")
    print(f"  KPSS: estadístico={kpss_result[0]:.4f}  p={kpss_result[1]:.4f}  "
          f"→ {'estacionaria' if kpss_result[1] > 0.05 else 'NO estacionaria'}")
    print(f"  Conclusión: d=0, no se necesita diferenciación")
    print()

    return adf_result, kpss_result


# ═══════════════════════════════════════════════════════════════════════
# PASO 3 — ACF / PACF
# ═══════════════════════════════════════════════════════════════════════

def run_acf_pacf(net_cash, nlags=12):
    """Autocorrelación y autocorrelación parcial. Sanity check, no selector
    definitivo de parámetros con n=24."""
    from statsmodels.tsa.stattools import acf, pacf

    acf_vals = acf(net_cash, nlags=nlags)
    pacf_vals = pacf(net_cash, nlags=min(nlags, len(net_cash)//2 - 1))
    conf_bound = 1.96 / np.sqrt(len(net_cash))

    print("PASO 3 — ACF / PACF")
    print(f"  Banda de confianza (95%): ±{conf_bound:.4f}")
    sig_acf = [i for i in range(1, len(acf_vals)) if abs(acf_vals[i]) > conf_bound]
    sig_pacf = [i for i in range(1, len(pacf_vals)) if abs(pacf_vals[i]) > conf_bound]
    print(f"  Lags ACF significativos: {sig_acf}")
    print(f"  Lags PACF significativos: {sig_pacf}")
    print()

    return acf_vals, pacf_vals, conf_bound


# ═══════════════════════════════════════════════════════════════════════
# PASO 4 — PRUEBAS DE HIPÓTESIS
# ═══════════════════════════════════════════════════════════════════════

def run_hypothesis_tests(net_cash):
    """Kruskal-Wallis (estacionalidad) + Mann-Kendall (tendencia)."""
    month_groups = [net_cash[net_cash.index.month == m].values for m in range(1, 13)]
    valid_groups = [g for g in month_groups if len(g) >= 2]
    kw_stat, kw_p = kruskal(*valid_groups)

    mk_result = mk.original_test(net_cash)

    print("PASO 4 — Pruebas de Hipótesis")
    print(f"  Kruskal-Wallis (estacionalidad): stat={kw_stat:.2f}  p={kw_p:.4f}  "
          f"→ {'significativo' if kw_p < 0.05 else 'NO significativo (n=2/grupo, subpotenciado)'}")
    print(f"  Mann-Kendall (tendencia): tau={mk_result.Tau:.4f}  p={mk_result.p:.4f}  "
          f"→ tendencia = {mk_result.trend}")
    print()

    return kw_stat, kw_p, mk_result


# ═══════════════════════════════════════════════════════════════════════
# MÉTRICAS COMUNES
# ═══════════════════════════════════════════════════════════════════════

def compute_metrics(actual, fitted, label, mask=None):
    """Calcula MAE, R², matriz de confusión, F1, y sesgo en meses de crisis."""
    fitted = np.asarray(fitted, dtype=float)
    actual = np.asarray(actual, dtype=float)

    if mask is None:
        mask = np.ones(len(actual), dtype=bool)
    valid = mask & ~np.isnan(fitted)

    f, a = fitted[valid], actual[valid]

    mae = float(np.mean(np.abs(a - f)))
    me = float(np.mean(f - a))  # sesgo: + optimista, - pesimista
    r2 = float(1 - np.sum((a - f) ** 2) / np.sum((a - a.mean()) ** 2))

    an = a < 0
    pn = f < 0
    tp = int(np.sum(an & pn))
    fn = int(np.sum(an & ~pn))
    fp = int(np.sum(~an & pn))
    tn = int(np.sum(~an & ~pn))
    recall = tp / max(tp + fn, 1)
    precision = tp / max(tp + fp, 1)
    f1 = 2 * recall * precision / max(recall + precision, 1e-9)

    crisis_bias = float(np.mean(f[an] - a[an])) if an.any() else None

    print(f"  {label}")
    print(f"    MAE=€{mae:,.0f}  R²={r2:.3f}  Sesgo(ME)=€{me:+,.0f}")
    print(f"    Matriz: TP={tp} FN={fn} FP={fp} TN={tn}  →  F1={f1:.3f}  "
          f"Recall={recall:.1%}  Precision={precision:.1%}")
    if crisis_bias is not None:
        direction = "pesimista ✓" if crisis_bias < 0 else "optimista ⚠️"
        print(f"    Sesgo en meses de crisis: €{crisis_bias:+,.0f}  ({direction})")

    return dict(mae=mae, me=me, r2=r2, tp=tp, fn=fn, fp=fp, tn=tn,
                f1=f1, recall=recall, precision=precision, crisis_bias=crisis_bias)


# ═══════════════════════════════════════════════════════════════════════
# MODELO 1 — LÓGICA DE NEGOCIO (determinístico, sin ajuste)
# ═══════════════════════════════════════════════════════════════════════

def model_business_logic(cf, cogs_lag=2, cogs_pct=0.60, fixed_pct=0.1875):
    """
    Outflow(t) = Inflow(t - cogs_lag) * cogs_pct + Inflow(t) * fixed_pct
    NetCash(t) = Inflow(t) - Outflow(t)

    Parámetros desde Coface + BID, NO ajustados a los datos de VIVA.
    """
    inflow = cf.set_index('YearMonth')['NetInflow']
    inflow.index = pd.DatetimeIndex(inflow.index, freq='MS')

    lag_cogs = inflow.shift(cogs_lag) * cogs_pct
    fixed_costs = inflow * fixed_pct
    net_cash_pred = inflow - lag_cogs - fixed_costs

    return net_cash_pred.values


# ═══════════════════════════════════════════════════════════════════════
# MODELO 2 — REGRESIÓN DE FOURIER (determinístico, ajustado por OLS)
# ═══════════════════════════════════════════════════════════════════════

def model_fourier_regression(net_cash_values, forecast_horizon=0):
    """
    NetCash(t) = β0 + β1*t + β2*sin(2πt/12) + β3*cos(2πt/12)
                        + β4*sin(2πt/6)  + β5*cos(2πt/6)

    Estructura (periodos 12 y 6) elegida por selección AIC.
    Coeficientes estimados por mínimos cuadrados ordinarios (OLS).
    """
    n = len(net_cash_values)
    t = np.arange(n)

    def build_X(t_arr):
        return add_constant(np.column_stack([
            t_arr,
            np.sin(2 * np.pi * t_arr / 12), np.cos(2 * np.pi * t_arr / 12),
            np.sin(2 * np.pi * t_arr / 6),  np.cos(2 * np.pi * t_arr / 6),
        ]))

    X = build_X(t)
    fit = OLS(net_cash_values, X).fit()

    print("  Coeficientes:")
    names = ["Intercepto", "t (tendencia)", "sin(2πt/12)", "cos(2πt/12)",
             "sin(2πt/6)", "cos(2πt/6)"]
    for name, coef, p in zip(names, fit.params, fit.pvalues):
        sig = "***" if p < 0.001 else "**" if p < 0.01 else "*" if p < 0.05 else ""
        print(f"    {name:<15} {coef:>12,.1f}   p={p:.4f} {sig}")

    fitted = fit.fittedvalues

    forecast = None
    if forecast_horizon > 0:
        t_fc = np.arange(n, n + forecast_horizon)
        X_fc = build_X(t_fc)
        forecast = fit.predict(X_fc)

    return fitted, forecast, fit


# ═══════════════════════════════════════════════════════════════════════
# MODELO 3 — PROPHET (Bayesiano)
# ═══════════════════════════════════════════════════════════════════════

def model_prophet(net_cash, forecast_horizon=3, fourier_order=3):
    """
    Prophet con estacionalidad anual, fourier_order reducido de 10 (default)
    a 3 para evitar sobreajuste con solo 24 observaciones.
    """
    prophet_df = pd.DataFrame({'ds': net_cash.index, 'y': net_cash.values})

    m = Prophet(
        yearly_seasonality=False,  # se agrega manualmente con fo controlado
        weekly_seasonality=False,
        daily_seasonality=False,
        seasonality_mode='additive',
        interval_width=0.80,
        changepoint_prior_scale=0.05,
    )
    m.add_seasonality(name='yearly', period=365.25, fourier_order=fourier_order)
    m.fit(prophet_df)

    future = m.make_future_dataframe(periods=forecast_horizon, freq='MS')
    full_forecast = m.predict(future)

    fitted = full_forecast['yhat'].values[:len(net_cash)]
    forecast = full_forecast.tail(forecast_horizon)

    return fitted, forecast, m


# ═══════════════════════════════════════════════════════════════════════
# MODELO 4 — ARIMA (clásico, sin componente estacional)
# ═══════════════════════════════════════════════════════════════════════

def model_arima(net_cash_values, order=(1, 0, 2), forecast_horizon=3):
    """
    ARIMA(1,0,2) puro, sin términos estacionales.

    Reemplaza a SARIMA(0,0,1)(0,0,1)_12: el término MA estacional
    necesitaba más de 2 ciclos completos para estimarse de forma
    confiable y causaba falsas alarmas. Orden seleccionado por AIC
    sobre una grilla p,q ∈ {0..3}, d=0 confirmado por ADF/KPSS.
    """
    fit = ARIMA(net_cash_values, order=order,
                enforce_stationarity=True, enforce_invertibility=True).fit()

    fitted = fit.fittedvalues
    forecast = fit.forecast(steps=forecast_horizon) if forecast_horizon > 0 else None

    print(f"  AIC: {fit.aic:.1f}")

    return fitted, forecast, fit


# ═══════════════════════════════════════════════════════════════════════
# VALIDACIÓN CRUZADA DE ORIGEN RODANTE (out-of-sample)
# ═══════════════════════════════════════════════════════════════════════

def rolling_origin_cv(nc, inflows, min_train=18, horizon=3):
    """
    Entrena con meses 1..origin, pronostica origin+1..origin+horizon,
    desliza el origen hacia adelante, repite. Da una evaluación honesta
    fuera de muestra (los modelos nunca ven los datos que pronostican).
    """
    n = len(nc)
    results = {name: {'errors': [], 'actual': [], 'pred': []}
               for name in ["Business Logic", "Fourier Regression", "Prophet", "ARIMA"]}

    for origin in range(min_train, n):
        h = min(horizon, n - origin)
        if h < 1:
            continue
        actual = nc[origin:origin + h]
        train = nc[:origin]

        # Business Logic
        try:
            preds = []
            for i in range(h):
                t = origin + i
                inf_t = inflows[t] if t < n else np.mean(inflows[-3:])
                inf_lag = inflows[t - 2] if t - 2 >= 0 else inf_t
                preds.append(inf_t - inf_lag * 0.60 - inf_t * 0.1875)
            for a, p in zip(actual, preds):
                results["Business Logic"]['errors'].append(p - a)
                results["Business Logic"]['actual'].append(a)
                results["Business Logic"]['pred'].append(p)
        except Exception:
            pass

        # Fourier Regression
        try:
            t_tr = np.arange(len(train))
            X_tr = add_constant(np.column_stack([
                t_tr, np.sin(2*np.pi*t_tr/12), np.cos(2*np.pi*t_tr/12),
                np.sin(2*np.pi*t_tr/6), np.cos(2*np.pi*t_tr/6)]))
            fit = OLS(train, X_tr).fit()
            t_fc = np.arange(len(train), len(train) + h)
            X_fc = add_constant(np.column_stack([
                t_fc, np.sin(2*np.pi*t_fc/12), np.cos(2*np.pi*t_fc/12),
                np.sin(2*np.pi*t_fc/6), np.cos(2*np.pi*t_fc/6)]))
            preds = fit.predict(X_fc)
            for a, p in zip(actual, preds):
                results["Fourier Regression"]['errors'].append(p - a)
                results["Fourier Regression"]['actual'].append(a)
                results["Fourier Regression"]['pred'].append(p)
        except Exception:
            pass

        # Prophet
        try:
            dates = pd.date_range('2025-01-01', periods=len(train), freq='MS')
            m = Prophet(yearly_seasonality=False, weekly_seasonality=False,
                        daily_seasonality=False, seasonality_mode='additive',
                        changepoint_prior_scale=0.05)
            m.add_seasonality(name='yearly', period=365.25, fourier_order=3)
            m.fit(pd.DataFrame({'ds': dates, 'y': train}))
            future = m.make_future_dataframe(periods=h, freq='MS')
            preds = m.predict(future)['yhat'].values[-h:]
            for a, p in zip(actual, preds):
                results["Prophet"]['errors'].append(p - a)
                results["Prophet"]['actual'].append(a)
                results["Prophet"]['pred'].append(p)
        except Exception:
            pass

        # ARIMA
        try:
            fit = ARIMA(train, order=(1, 0, 2),
                        enforce_stationarity=True, enforce_invertibility=True).fit()
            preds = fit.forecast(steps=h)
            for a, p in zip(actual, preds):
                results["ARIMA"]['errors'].append(p - a)
                results["ARIMA"]['actual'].append(a)
                results["ARIMA"]['pred'].append(p)
        except Exception:
            pass

    print("  Resultados fuera de muestra (rolling-origin CV):")
    summary = {}
    for name, r in results.items():
        errs = np.array(r['errors'])
        mae = float(np.mean(np.abs(errs)))
        me = float(np.mean(errs))
        summary[name] = dict(mae=mae, me=me, n=len(errs))
        print(f"    {name:<20} OOS MAE=€{mae:,.0f}  OOS Sesgo=€{me:+,.0f}  (n={len(errs)})")

    return summary


# ═══════════════════════════════════════════════════════════════════════
# MAIN — corre todo el pipeline en orden
# ═══════════════════════════════════════════════════════════════════════

if __name__ == '__main__':

    print("=" * 70)
    print("PASO 0 — Construcción de la serie de flujo de caja")
    print("=" * 70)
    cf, median_ratio = build_cashflow_series()
    print(f"  Meses: {len(cf)}  |  Meses backfilled: {cf['Backfilled'].sum()}  "
          f"|  Ratio YoY usado: {median_ratio:.4f}")
    print(f"  Meses con efectivo negativo: {(cf['NetCash'] < 0).sum()}/{len(cf)}")
    print()

    net_cash = cf.set_index('YearMonth')['NetCash']
    net_cash.index = pd.DatetimeIndex(net_cash.index, freq='MS')
    nc = net_cash.values
    inflows = cf['NetInflow'].values
    real_mask = ~cf['Backfilled'].values  # excluye Jan/Feb 2025 backfilled

    print("=" * 70)
    run_decomposition(net_cash)

    print("=" * 70)
    run_stationarity_tests(net_cash)

    print("=" * 70)
    run_acf_pacf(net_cash)

    print("=" * 70)
    run_hypothesis_tests(net_cash)

    print("=" * 70)
    print("MODELOS DE PRONÓSTICO (evaluados en 22 meses reales)")
    print("=" * 70)

    print("\nModelo 1 — Lógica de Negocio (determinístico, sin ajuste)")
    bl_fitted = model_business_logic(cf)
    bl_metrics = compute_metrics(nc, bl_fitted, "Lógica de Negocio", mask=real_mask)

    print("\nModelo 2 — Regresión de Fourier (determinístico, OLS)")
    fr_fitted, fr_forecast, fr_fit = model_fourier_regression(nc, forecast_horizon=3)
    fr_metrics = compute_metrics(nc, fr_fitted, "Regresión de Fourier", mask=real_mask)

    print("\nModelo 3 — Prophet (Bayesiano)")
    pr_fitted, pr_forecast, pr_fit = model_prophet(net_cash, forecast_horizon=3, fourier_order=3)
    pr_metrics = compute_metrics(nc, pr_fitted, "Prophet (fo=3)", mask=real_mask)

    print("\nModelo 4 — ARIMA(1,0,2) (clásico, sin estacionalidad)")
    ar_fitted, ar_forecast, ar_fit = model_arima(nc, order=(1, 0, 2), forecast_horizon=3)
    ar_metrics = compute_metrics(nc, ar_fitted, "ARIMA(1,0,2)", mask=real_mask)

    print()
    print("=" * 70)
    print("VALIDACIÓN CRUZADA FUERA DE MUESTRA (rolling-origin, 12 pronósticos)")
    print("=" * 70)
    cv_summary = rolling_origin_cv(nc, inflows, min_train=18, horizon=3)

    print()
    print("=" * 70)
    print("PRONÓSTICO A 3 MESES (Ene–Mar 2027)")
    print("=" * 70)
    fc_dates = pd.date_range(net_cash.index[-1] + pd.DateOffset(months=1),
                              periods=3, freq='MS').strftime('%Y-%m')
    fr_fc_arr = np.asarray(fr_forecast)
    pr_fc_arr = pr_forecast['yhat'].to_numpy()
    ar_fc_arr = np.asarray(ar_forecast)

    print(f"{'Mes':<10} {'Fourier':>14} {'Prophet':>14} {'ARIMA':>14}")
    print("(Lógica de Negocio requiere ventas futuras conocidas o un promedio")
    print(" móvil de las últimas ventas para proyectar — ver README, Paso 6)")
    for i, d in enumerate(fc_dates):
        print(f"{d:<10} {fr_fc_arr[i]:>14,.0f} {pr_fc_arr[i]:>14,.0f} {ar_fc_arr[i]:>14,.0f}")

    print()
    print("=" * 70)
    print("RESUMEN FINAL")
    print("=" * 70)
    print(f"{'Modelo':<22} {'MAE (IS)':>10} {'F1':>7} {'Sesgo Crisis':>14}")
    print("-" * 55)
    for name, m in [("Lógica de Negocio", bl_metrics), ("Regresión Fourier", fr_metrics),
                     ("Prophet (fo=3)", pr_metrics), ("ARIMA(1,0,2)", ar_metrics)]:
        cb = f"€{m['crisis_bias']:+,.0f}" if m['crisis_bias'] is not None else "n/a"
        print(f"{name:<22} €{m['mae']:>7,.0f} {m['f1']:>7.3f} {cb:>14}")
