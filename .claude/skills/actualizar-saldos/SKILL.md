---
name: actualizar-saldos
description: Actualiza saldos y valoraciones en contexto/mapa-activos.md, recalcula los bloques que usan las declaraciones informativas de cada jurisdicción y avisa si se cruza un umbral o un disparador de revisión. Úsala cuando lleguen saldos nuevos (cierre de año, apertura o cierre de una cuenta, compra o venta, cambio de valoración).
---

# Actualizar saldos y umbrales

Mantiene vivo `contexto/mapa-activos.md` y, sobre todo, **vigila los umbrales que disparan
obligaciones o decisiones.** El valor no es el dato en sí: es avisar a tiempo de que un saldo
cruza una línea que obliga a reaccionar.

## Cuándo se usa

- **Cierre de año:** saldos al 31 de diciembre (o la fecha que fije cada jurisdicción) y, si
  la norma lo pide, saldos medios. Es el momento clave de las declaraciones informativas.
- **Cambio material en cualquier momento:** apertura o cierre de una cuenta, entrada o
  salida grande de fondos, compra o venta, nueva valoración.

## Pasos

1. **Leé** `contexto/mapa-activos.md`, la sección **Disparadores** de
   `contexto/decisiones-y-criterios.md` y las **declaraciones informativas** de cada
   `jurisdicciones/*.md` (qué bloques agrupan y con qué umbral).
2. **Pedí o leé los datos nuevos.** No los inventes. Cada saldo con su fecha y su moneda.
3. **Convertí** a la moneda de cada jurisdicción con el tipo que fije su norma, y anotá cuál.
4. **Actualizá** el mapa y su "Última actualización".
5. **Recalculá los bloques** de cada declaración informativa y compará con su umbral y con
   lo ya declarado (algunas obligan a volver a presentar si un bloque sube cierto importe o
   se cierra una posición).
6. **Comprobá los disparadores.** Si alguno se cruza o está cerca, avisá y proponé reabrir
   la decisión afectada o abrir un ticket.
7. **Bitácora** si hubo un cambio relevante, y `bash scripts/check-coherencia.sh`.

## Salida

Tabla de bloques por jurisdicción (valor, umbral, distancia al umbral, ¿obliga a presentar?)
y la lista de disparadores cruzados o cercanos, con la acción propuesta.

## Límite

Calcula y avisa. Si un umbral tiene matices de interpretación (qué cuenta, qué fecha, qué
tipo de cambio), se marca como interpretativo y se propone validarlo.
