# Libro registro de facturas recibidas, 2026 (EJEMPLO)

> **Datos inventados.** Modelo del formato español y caso de prueba del control de
> coherencia. Lo escribe `procesar-facturas`; el esquema de columnas vive en esa skill.

| ID | Fecha | Trim. IVA | Emisor (NIF) | Nº factura | Concepto | Base € | Tipo IVA | IVA € | Divisa orig. | Régimen IVA | % Ded. IVA | IVA deduc. € | % Ded. IRPF | Tratam. IRPF | IRPF deduc. € | Total € | Archivo |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| G-2026-001 | 2026-01-10 | 2026-1T | Proveedor Software SL (B11111111) | A-123 | Licencia de software | 100,00 | 21% | 21,00 |  | Nacional | 100 | 21,00 | 100 | Corriente | 100,00 | 121,00 | G-2026-001_2026-01-10_proveedor-software_licencia.pdf |
| G-2026-002 | 2026-02-03 | 2026-1T | SaaS Inc (no establecido, EE. UU.) | INV-9 | Suscripción mensual | 50,00 | 21% | 10,50 | 55,00 USD @ 1,10 (BCE 2026-02-02) | ISP servicio | 100 | 10,50 | 100 | Corriente | 50,00 | 50,00 | G-2026-002_2026-02-03_saas-inc_suscripcion.pdf |
| G-2026-003 | 2026-04-20 | 2026-2T | Tienda Informática SL (B22222222) | T-77 | Portátil | 1.000,00 | 21% | 210,00 |  | Nacional | 100 | 210,00 | 100 | Amortización | ver cuadro | 1.210,00 | G-2026-003_2026-04-20_tienda-informatica_portatil.pdf |

**Totales recibidas 2026:** Base: 1.150,00 € · Total facturas: 1.381,00 €

> En `ISP servicio` el proveedor no factura IVA: se auto-repercute y se deduce, así que es
> neutro y el total es la base. Los rótulos `Base` y `Total facturas` son **contrato con el
> check 4**.

## Cuadro de amortizaciones

| Bien | ID | Alta | Valor € | Coef. | Amortización 2026 € |
|---|---|---|---|---|---|
| Portátil | G-2026-003 | 2026-04-20 | 1.000,00 | 26% | 182,36 (256 días de 365) |
