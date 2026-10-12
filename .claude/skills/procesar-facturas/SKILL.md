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

Modelo con datos inventados en `ejemplos/documentos-es/`. **Un libro por año:**
`documentos-es/registro-emitidas-<año>.md` y `documentos-es/registro-recibidas-<año>.md`.
A principios de enero se abren los del año nuevo, con la línea de totales en cero (los
rótulos exactos están en la skill `alta`).

### Columnas, hay que rellenarlas todas

**EMITIDAS**: `ID | Fecha devengo | Trimestre | Cliente (NIF) | Concepto | Base € | Tipo IVA |
IVA rep. € | Tipo Ret. | Retención € | Total € | Archivo`

**RECIBIDAS**: `ID | Fecha | Trim. IVA | Emisor (NIF) | Nº factura | Concepto | Base € | Tipo
IVA | IVA € | Divisa orig. | Régimen IVA | % Ded. IVA | IVA deduc. € | % Ded. IRPF | Tratam.
IRPF | IRPF deduc. € | Tipo Ret. | Retención € | Total € | Archivo`

**El orden de columnas y los rótulos de la línea de totales son contrato con el control de
coherencia** (checks 4 y 6). Si se cambian, se cambia el script en el mismo commit y se corre
`scripts/probar-check.sh`.

- **ID de emitidas**: el número legal. **Las rectificativas van en su propia serie** (por
  ejemplo `R-0001-<año>`), con importes en negativo, en el mismo libro.
- **Divisa orig.**: vacío si es EUR; si no, `<importe> <moneda> @ <tipo> (<fuente>)`. El tipo
  es el último publicado (BCE o Banco de España) **vigente en el momento del devengo** (art.
  79.Once LIVA).
- **Trimestre / Trim. IVA** (`AAAA-NT`): trimestre en que se imputa el IVA.
  - Emitidas: por **devengo** (art. 75 LIVA).
  - Recibidas: el IVA soportado se deduce en el periodo en que se tiene la factura (art.
    98.Dos LIVA), normalmente el del devengo. **Si llega tarde y su trimestre ya se presentó,
    se imputa al vigente** (hasta cuatro años, art. 99.Tres LIVA) y se anota. Esta columna es
    el control contra la doble imputación o la falta de imputación.
  - **El IRPF no sigue esta columna:** el gasto se imputa por la **fecha** de la factura. El
    control lo calcula así.
- **Tipo Ret. y Retención € (recibidas)**: la retención que **el usuario practica** al pagar,
  por ejemplo a un arrendador o a otro profesional. El tipo lleva el modelo entre paréntesis,
  `19% (115)` o `15% (111)`, porque de ahí salen las claves `recibidas.ret115` y `ret111`.
  Sin retención: tipo vacío y `0,00`.

### Deducibilidad (recibidas)

1. **Régimen IVA**:
   - `Nacional`: proveedor español, IVA deducible. `Nacional (B2C)` si facturó como a un
     consumidor.
   - `ISP servicio`: servicio de un proveedor **no establecido**. El usuario autoliquida:
     devenga el IVA y lo deduce. Extra-UE: 303 sí, 349 no. UE: 303 y 349.
   - `ISP bien`: bien de un proveedor no establecido con la mercancía ya en España: 303 sí,
     349 no.
   - `Intracom.`: adquisición intracomunitaria de bienes, también autoliquidada: 303 y 349.
   - `Exento` o no sujeto.

   En los tres regímenes de autoliquidación el proveedor no cobra IVA: **el total es la base
   menos la retención**, la columna `IVA €` es el IVA devengado y `IVA deduc. €` lo que se
   deduce. Con deducción del 100% el efecto en el 303 es neutro; con menos, no.
2. **% Ded. IVA** y **% Ded. IRPF** (firmes: 100, 50 o 0):
   - Requisito: factura al NIF del usuario y relación con la actividad.
   - Coste indivisible (una habitación de hotel) entero; coste por persona (un pasaje) solo
     el propio.
   - **Turismo de uso mixto** (coche, renting, combustible): IVA 50% (presunción del art.
     95.Tres LIVA, que admite prueba en contrario) e IRPF 0% salvo afectación exclusiva.
   - Software y servicios de la actividad: 100%.
   - Gasto personal: 0%.
3. **IVA deduc. €** = cuota × % Ded. IVA. En autoliquidación, la cuota devengada.
4. **IRPF deduc. €** = base × % Ded. IRPF, con dos excepciones:
   - Si el IVA no se recupera (`% Ded. IVA = 0`), se incorpora al coste: IRPF sobre base +
     IVA.
   - **Elemento del inmovilizado de más de 300 € por unidad** (`Tratam. IRPF = Amortización`):
     no se deduce de golpe; se amortiza. Los de hasta 300 € pueden deducirse enteros (art.
     12.3.e de la Ley del Impuesto sobre Sociedades, con un límite de 25.000 € al año). En
     estimación directa simplificada se usa la **tabla simplificada** (equipos informáticos:
     26%); en directa normal, la tabla general de esa ley. Se prorratea por días el año de
     alta. La celda dice `ver cuadro` y el bien va al **Cuadro de amortizaciones** al pie del
     libro. No confundir con los "bienes de inversión" del IVA (art. 108 LIVA), que es otro
     concepto y otro umbral.
5. **Tratam. IRPF**: `Corriente` o `Amortización`.

### Resúmenes

`documentos-es/declaraciones/<año>/<año-trimestre>/liquidacion.md` (303, 111, 115 y 130 del
trimestre) y `<año>_resumen-anual.md`. El 130 es **acumulado desde el 1 de enero**: se usan
las claves `AAAA-ACNT`. Las claves disponibles están en la cabecera del check 6 de
`scripts/check-coherencia.sh`; un trimestre sin facturas tiene sus claves en cero, así que un
303 a cero también se etiqueta.

Si el año anterior al menos el 70% de los ingresos de la actividad llevó retención, no hay
obligación de presentar el 130 (art. 109.1 del Reglamento del IRPF). Se anota en la
liquidación como exento, con la fuente, en lugar de dejarlo como pendiente.

---

## Otros países

`alta` añade aquí una sección por cada país con libros: columnas, reglas de cálculo y
resúmenes, con la misma estructura que España.

## Límite

Organiza, extrae y **calcula** la deducibilidad propuesta. La validación fiscal final y la
presentación son de un profesional. No inventa importes: si un dato no se lee, lo pide.
