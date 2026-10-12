# Libro registro de facturas emitidas, 2026 (EJEMPLO)

> **Datos inventados.** Modelo del formato español y caso de prueba del control de
> coherencia. Lo escribe `procesar-facturas`; el esquema de columnas vive en esa skill.

| ID | Fecha devengo | Trimestre | Cliente (NIF) | Concepto | Base € | Tipo IVA | IVA rep. € | Tipo Ret. | Retención € | Total € | Archivo |
|---|---|---|---|---|---|---|---|---|---|---|---|
| F-0001-2026 | 2026-01-15 | 2026-1T | Cliente Ejemplo SL (B00000000) | Consultoría enero | 1.000,00 | 21% | 210,00 | 15% | 150,00 | 1.060,00 | F-0001-2026_2026-01-15_cliente-ejemplo_consultoria.pdf |
| F-0002-2026 | 2026-02-15 | 2026-1T | Cliente Ejemplo SL (B00000000) | Consultoría febrero | 1.000,00 | 21% | 210,00 | 15% | 150,00 | 1.060,00 | F-0002-2026_2026-02-15_cliente-ejemplo_consultoria.pdf |
| F-0003-2026 | 2026-04-15 | 2026-2T | Otra Empresa SA (A00000000) | Proyecto de implantación | 2.000,00 | 21% | 420,00 | 15% | 300,00 | 2.120,00 | F-0003-2026_2026-04-15_otra-empresa_proyecto.pdf |

**Totales emitidas 2026:** Base: 4.000,00 € · IVA repercutido: 840,00 € · Retención: 600,00 € · Facturado: 4.840,00 € · Cobrado: 4.240,00 €

> Los rótulos de la línea de totales (`Base`, `IVA repercutido`, `Facturado`, `Cobrado`) son
> **contrato con el check 4**: si se renombran, hay que tocar `scripts/check-coherencia.sh`.
