# Arquitectura del sistema

> **Documento madre.** Dice por qué existe el sistema, cómo fluye la información y cómo está
> estructurado. Se lee al empezar cada sesión. Con `INDICE.md` forma la capa de gobierno:
> el índice dice **dónde** está cada cosa, este documento dice **cómo** funciona.

## 1. Misión

Este proyecto es un **optimizador fiscal**, no un recordatorio de cuándo pagar. Su trabajo es
cuidar todas las aristas para pagar lo que corresponde y no más, siempre de forma legal: el
eje **"asesor, no recaudador"** (criterio C6). No espera la pregunta: vigila.

Corolario: **un dato incoherente es una optimización perdida.** Un total viejo, un gasto mal
imputado, un porcentaje sin actualizar, y se paga de más o se deduce de menos. Por eso la
coherencia (secciones 4 a 7) no es burocracia: es la infraestructura de la misión.

Límite (C2): optimiza y evalúa consecuencias; **no diseña ocultamiento.**

## 2. Flujo de la información

```
PDF suelto
   |  procesar-facturas: lee, extrae, CALCULA cada campo, renombra
   v
LIBROS registro   (documentos-<país>/registro-*-<año>.md)  -> fuente de verdad viva
   |  transportar y sumar (NO recalcular)
   v
RESÚMENES         (declaraciones/<año>/...)           -> vista derivada
   |  al presentar ante la administración
   v
JUSTIFICANTE presentado                               -> verdad del acto, inmutable
```

**Tres niveles de verdad:**

1. **Libro**: fuente viva y **rectificable**, lo que realmente pasó con cada factura.
2. **Resumen**: vista derivada que transporta y suma; **nunca es fuente**. Si un número
   falla, se corrige en el libro.
3. **Justificante presentado**: verdad del acto, **inmutable**. Si libro y justificante
   divergen, es una **rectificación pendiente** (ticket), no un error del libro.

## 3. Estructura y precedencia

| Carpeta | Rol |
|---|---|
| `contexto/` | Base de conocimiento viva: ficha, activos, ingresos, histórico declarativo, decisiones, índice y esta arquitectura. **Fuente de verdad** |
| `documentos-<país>/` | Un expediente por jurisdicción: facturas, **libros registro**, declaraciones, justificantes. Compartimentados (C7). Los crea `alta` |
| `jurisdicciones/` | Referencia normativa de cada jurisdicción que te toca, investigada en fuente oficial. La crea `alta` |
| `calendario/` | Vencimientos con fechas concretas. Lo crea `alta` |
| `vigilancia/` | Registro mensual del barrido normativo |
| `tickets/` | Trabajo pendiente (`abiertos/`) e histórico (`cerrados/`) |
| `bitacora/` | Registro cronológico de cada cambio. **Histórico inmutable** |
| `consultas/` | Análisis reutilizables, caros de repetir. No es bandeja de entrada |
| `ejemplos/` | El libro español con datos inventados, como modelo y para probar el control |
| `scripts/` | El control de coherencia y su configuración |
| `.claude/skills/` | Los flujos recurrentes |

**Precedencia:** `contexto/` es el estado actual; `bitacora/` y `tickets/cerrados/` son log
histórico inmutable. **Ante contradicción manda `contexto/`**, y se resuelve la contradicción.

## 4. Un solo hogar por dato (C8)

- **Cada dato o regla vive en un sitio**; el resto enlaza, no copia.
- **`procesar-facturas` es la única autoridad de cálculo.** Extrae del PDF y calcula cada
  campo derivado; ninguna otra skill ni sesión recalcula por su cuenta.
- **Los resúmenes transportan y suman, y lo declaran.** Cada cifra transportada lleva pegada
  una **etiqueta de transporte**, `<!--@ejemplo.magnitud.periodo-->`, que dice de qué magnitud
  del libro sale. El check 6 recalcula ese valor desde el libro y lo compara con el número que
  precede a la etiqueta. **Una cifra derivada sin etiqueta no está vigilada:** al añadir una,
  se etiqueta.
- **El dato del libro es firme.** Lo que dependa de una acción externa (un NIF que falta, una
  confirmación de uso) es un **ticket**, no una bandera en el dato.
- **Formato:** la fuente en **markdown**, auditable en git. Hojas de cálculo solo como export.

El esquema de columnas de cada libro y sus fórmulas viven en `procesar-facturas`.

## 5. Perímetro: qué se sincroniza y qué se congela

- **Capa viva, se sincroniza siempre:** `contexto/`, libros, declaraciones, `calendario/`,
  `jurisdicciones/`, skills, READMEs, el índice y esta arquitectura.
- **Capa histórica, congelada:** `bitacora/`, `tickets/cerrados/`, justificantes presentados.
  Registran lo que se hizo y decidió **entonces**, y no se retro-editan.

Mantener coherente también el pasado multiplicaría el trabajo de sincronización. Congelar la
historia **acota el perímetro** a lo que de verdad tiene que estar al día.

## 6. Mapa de dependencias: si cambia X, refrescá Y

| Si cambia | Refrescar |
|---|---|
| una fila de un libro | totales del año, liquidación del periodo y resumen anual (lo hace `procesar-facturas`) |
| un porcentaje o una regla de deducibilidad | los libros y resúmenes afectados, y la regla donde viva |
| se presenta una declaración | `historico-declarativo.md`, el estado en `calendario/vencimientos.md`, y el justificante en `declaraciones/` |
| se mueve o renombra un archivo o carpeta | buscar la ruta vieja, `INDICE.md`, los READMEs que la citen y **`.claude/*.json`**: los hooks llevan rutas, y una ruta muerta en un hook **no da error, deja de hacer su trabajo** |
| se crea o cierra una D-X, C-X, ticket o consulta | las tablas de `INDICE.md` y de `tickets/README.md` |
| un dato de la ficha | lo que lo referencie en `contexto/` |
| aparece un país nuevo (mudanza, cliente, bien) | correr `alta` para ese país |

## 7. Qué garantiza la coherencia, y qué no

**Ningún documento se obliga solo.** La coherencia se sostiene por capas, de más fuerte a más
débil:

1. **Prevención estructural:** des-duplicar. Si un dato vive en un solo sitio, no puede
   desincronizarse. No depende de la disciplina.
2. **Detección automática:** `scripts/check-coherencia.sh`. Enlaces rotos, patrones y rutas
   obsoletos (también en `.claude/*.json`), índices de tickets en los dos sentidos, cuadre
   aritmético de los libros, términos prohibidos por jurisdicción (en el contenido y en los
   nombres de archivo), y transporte resumen contra libro, con signo. Una línea de
   configuración mal escrita también es una incidencia. Está enganchado como **pre-commit
   bloqueante** que revisa **lo que se va a commitear**, no la carpeta de trabajo. En un
   clon nuevo se activa con `git config core.hooksPath .githooks`.
3. **Propagación sistemática:** el mapa de la sección 6 y el paso de coherencia de `destilar`.
4. **Auditoría periódica completa**, como red de seguridad: una vez al año, agendada en el
   calendario por `alta`. Se corre el control, `revisar-vencimientos` y `vigilar-normativa`,
   y se relee la ficha contra la situación real.

Este documento describe la 3 y la 4; lo que garantiza es la 1 y la 2.

**Y el guardián tampoco se vigila solo.** Un check que no encuentra lo que busca (porque el
rótulo que lee cambió de nombre, porque la línea ya no está) **pasa en verde** y se lee igual
que "todo correcto". De ahí tres reglas:

- **Un check saltado se grita, no se omite.** Si falta el insumo, el check informa que no
  pudo comprobar. Verde solo significa "comprobado y correcto".
- **Los rótulos que lee un check son contrato**, y se dice así en el propio documento.
- **Todo check nuevo se valida rompiendo algo a propósito** y comprobando que salta. Para el
  libro español lo hace `scripts/probar-check.sh`.
