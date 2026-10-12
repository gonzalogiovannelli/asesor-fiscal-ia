---
name: procesar-facturas
description: Detecta facturas nuevas (sin indexar) en las carpetas de facturas de cada expediente documentos-<país>/, lee cada PDF, extrae sus datos, les asigna un identificador y un nombre estandarizado, calcula lo deducible según las reglas del país y las registra en los libros registro. Es la única autoridad de cálculo del sistema. Úsala cuando el usuario cargue facturas nuevas o diga "procesá las facturas", "indexá facturas", "registro de facturas", "renombrá las facturas".
---

# Procesar e indexar facturas

Convierte facturas sueltas en el **libro registro**, que es la fuente de verdad. Donde llevar
libros es obligatorio, esto **es** una obligación formal, no solo orden.

**Esta skill es la única autoridad de cálculo del sistema.** Aquí se extrae cada dato crudo
del PDF y se **calcula cada campo derivado** (deducibilidad, importes deducibles, periodo de
imputación). Los resúmenes solo **transportan y suman** lo que el libro ya calculó. Si un
número está mal, se arregla en el libro, no en el resumen.

## Lo común a todos los países

### Dónde se dejan las facturas

`documentos-<país>/facturas-emitidas/<año>/` y `documentos-<país>/facturas-recibidas/<año>/`.

### Identificadores y nombres

- **Emitidas**: ID = **número legal real** de la factura, de su serie, correlativo y sin
  huecos.
- **Recibidas**: ID interno por serie y año (`G-<año>-NNN`), correlativo, sin huecos. El
  orden es de procesamiento, no estrictamente por fecha.
- **Nombre de archivo**:
  - Recibidas: `G-<año>-NNN_AAAA-MM-DD_emisor_concepto.pdf`
  - Emitidas: `<nº legal>_AAAA-MM-DD_cliente_concepto.pdf`
  - Fecha de emisión; emisor o cliente y concepto en minúsculas-con-guiones.

### Reglas que valen en cualquier país

- **Lo crudo sale del PDF y no se inventa.** Si un dato no se lee, se pide.
- **La factura tiene que ir a nombre del usuario** (identificador de la ficha). Un ticket o
  recibo de consumidor normalmente no da derecho a deducir el impuesto: se avisa y se pide
  la factura.
- **Divisa extranjera**: se convierte con el tipo oficial que fije la norma del país (en
  España, el del BCE del último día hábil previo al devengo) y se deja anotado el importe y
  el tipo de origen.
- **Solo la parte propia**: un gasto que incluye a un tercero se deduce en la parte que
  corresponde al usuario.
- **Duplicados**: antes de registrar, se busca el mismo número de factura y emisor.

### Banderas

- **El porcentaje del libro es firme.** Si falta una acción externa (que el proveedor ponga
  el identificador, confirmar el uso profesional), eso es un **ticket**, no una bandera.
- Solo se usa 🚩 para un porcentaje genuinamente indeterminado. La meta es una tabla sin
  banderas.

### Pasos

1. **Escaneá** las carpetas de año de cada expediente y **detectá las no indexadas**.
2. **Leé cada PDF** (si es un escaneo, con OCR). Confirmá que va a nombre del usuario.
3. **Extraé** los campos crudos. Si hay otra moneda, convertí y anotá el origen.
4. **Clasificá** (emitida o recibida), asigná el **siguiente ID** y **renombrá** el archivo.
5. **Calculá** todas las columnas derivadas con las reglas del país (abajo).
6. **Registrá la fila** en el libro y **recalculá la línea de totales** del año. Si es un
   bien de inversión, actualizá el cuadro de amortizaciones.
7. **Transportá a los resúmenes** del periodo bajo `declaraciones/<año>/`, **con su etiqueta
   de transporte** pegada a cada cifra (ver `contexto/arquitectura.md`, sección 4). No
   recalculan nada: suman lo que el libro ya dejó.
8. **Avisá** de problemas: falta el identificador del usuario, es recibo y no factura, gasto
   de tercero, duplicado, factura a corregir.
9. **Cerrá**: `bash scripts/check-coherencia.sh` en verde, línea en la bitácora, ticket para
   toda acción pendiente.

### Salida

Por factura: ID, nombre nuevo, emisor, total, porcentajes y importes deducibles, tickets
abiertos. Y los totales y resúmenes actualizados. Si no hay facturas nuevas, decilo.

---

## España (formato `es`, el ejemplo de la plantilla)

Modelo con datos inventados en `ejemplos/documentos-es/`. Libros:
`documentos-es/registro-emitidas.md` y `documentos-es/registro-recibidas.md`.

### Columnas, hay que rellenarlas todas

**EMITIDAS**: `ID | Fecha devengo | Trimestre | Cliente (NIF) | Concepto | Base € | Tipo IVA |
IVA rep. € | Tipo Ret. | Retención € | Total € | Archivo`

**RECIBIDAS**: `ID | Fecha | Trim. IVA | Emisor (NIF) | Nº factura | Concepto | Base € | Tipo
IVA | IVA € | Divisa orig. | Régimen IVA | % Ded. IVA | IVA deduc. € | % Ded. IRPF | Tratam.
IRPF | IRPF deduc. € | Total € | Archivo`

**El orden de columnas y los rótulos de la línea de totales son contrato con el control de
coherencia** (checks 4 y 6). Si se cambian, se cambia el script en el mismo commit y se corre
`scripts/probar-check.sh`.

- **Divisa orig.**: vacío si es EUR; si no, `<importe> <moneda> @ <tipo> (BCE <fecha>)`.
- **Trimestre / Trim. IVA** (`AAAA-NT`): trimestre en que se imputa el IVA.
  - Emitidas: por **devengo** (art. 75 LIVA).
  - Recibidas: normalmente el del devengo; **si llega tarde y su trimestre ya se presentó,
    se imputa al vigente** (derecho a deducir hasta cuatro años, art. 99.Tres LIVA) y se
    anota. Esta columna es el control contra la doble imputación o la falta de imputación.

### Deducibilidad (recibidas)

1. **Régimen IVA**:
   - `Nacional`: proveedor español, IVA deducible. `Nacional (B2C)` si facturó como a un
     consumidor.
   - `ISP servicio`: servicio de un proveedor **no establecido**. Se auto-repercute y se
     deduce, así que es **neutro**. Extra-UE: 303 sí, 349 no. UE: 303 y 349.
   - `ISP bien`: bien de un proveedor no establecido con la mercancía ya en España: 303 sí,
     349 no.
   - `Intracom.`: adquisición intracomunitaria de bienes: 303 y 349.
   - `Exento` o no sujeto.
2. **% Ded. IVA** y **% Ded. IRPF** (firmes: 100, 50 o 0):
   - Requisito: factura al NIF del usuario y relación con la actividad.
   - Coste indivisible (una habitación de hotel) entero; coste por persona (un pasaje) solo
     el propio.
   - **Turismo de uso mixto** (coche, renting, combustible): IVA 50%, IRPF 0% (art. 95.Tres
     LIVA), salvo prueba de afectación exclusiva.
   - Software y servicios de la actividad: 100%.
   - Gasto personal: 0%.
3. **IVA deduc. €** = cuota × % Ded. IVA. En ISP, la cuota auto-repercutida.
4. **IRPF deduc. €** = base × % Ded. IRPF, con dos excepciones:
   - Si el IVA no se recupera (`% Ded. IVA = 0`), se incorpora al coste: IRPF sobre base +
     IVA.
   - **Bien de inversión de más de 300 € por unidad** (`Tratam. IRPF = Amortización`): no se
     deduce de golpe. Se amortiza según la tabla simplificada, prorrateando por días el año
     de alta. La celda dice `ver cuadro` y el bien va al **Cuadro de amortizaciones** al pie
     del libro.
5. **Tratam. IRPF**: `Corriente` o `Amortización`.

### Resúmenes

`documentos-es/declaraciones/<año>/<año-trimestre>/liquidacion.md` (303 y 130 del trimestre)
y `<año>_resumen-anual.md`. Las claves de transporte disponibles están en la cabecera del
check 6 de `scripts/check-coherencia.sh`.

---

## Otros países

`alta` añade aquí una sección por cada país con libros: columnas, reglas de cálculo y
resúmenes, con la misma estructura que España.

## Límite

Organiza, extrae y **calcula** la deducibilidad propuesta. La validación fiscal final y la
presentación son de un profesional. No inventa importes: si un dato no se lee, lo pide.
