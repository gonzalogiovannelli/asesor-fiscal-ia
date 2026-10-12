---
name: vigilar-normativa
description: Barrido mensual de novedades normativas en cada jurisdicción dada de alta, para detectar cambios de ley que dejen desactualizada la base del proyecto. Búsqueda web activa contra fuentes oficiales, no de memoria. Úsala en la revisión mensual, cuando el recordatorio de inicio de sesión lo pida, o cuando el usuario diga "vigilar normativa", "novedades normativas", "¿cambió alguna ley?", o quiera comprobar si una obligación o decisión sigue vigente.
---

# Vigilar normativa (barrido mensual)

El antídoto contra el riesgo más serio del proyecto: que una ley cambie y la base siga
asumiendo lo viejo sin que nadie se entere. **Un dato fiscal desactualizado no parece roto,
parece correcto**, y por eso hay que salir a buscar los cambios.

## Principio que no se salta

**El conocimiento del modelo tiene fecha de corte.** Para afirmar qué cambió se usa búsqueda
web (WebSearch, WebFetch) **contra fuentes oficiales**, nunca la memoria. La fecha de hoy está
en el contexto de la sesión: es la referencia para filtrar lo reciente.

## Qué se vigila

**No hay una lista fija: sale de lo que está dado de alta.** Por cada archivo de
`jurisdicciones/`:

- sus **fuentes oficiales** (sección "Fuentes oficiales"),
- su **lista de vigilancia** (sección "Lista de vigilancia"),
- cada **obligación** de su tabla, por si cambió plazo, formulario o umbral,
- y los **pendientes de confirmar**, por si ya se resolvieron.

Además, los **disparadores normativos** de `contexto/decisiones-y-criterios.md` y las
decisiones D-X que dependan de una norma.

Prensa y asesorías sirven para **detectar** que algo se movió; lo que se afirma se ancla en
la fuente oficial. Se marca siempre CONFIRMADO (oficial) o interpretativo.

## Procedimiento

1. **Leé la línea base:** `contexto/decisiones-y-criterios.md` y todos los
   `jurisdicciones/*.md`. Es lo que el proyecto asume hoy.
2. **Por cada ítem**, búsqueda dirigida a la fuente oficial, filtrando desde la última marca
   de `vigilancia/`.
3. **Compará** con la línea base y quedate **solo con lo que cambió** o es nuevo.
4. **Verificá** lo material en la fuente oficial antes de afirmarlo, con fecha y cita.
5. **Ante un cambio material:**
   - actualizá el `jurisdicciones/` que toque (y su "Última verificación"), y `contexto/` si
     cambia un dato,
   - actualizá `calendario/vencimientos.md` si cambia un plazo,
   - proponé un ticket para lo accionable, o reabrir la decisión afectada
     (`registrar-decision` y el log de revisiones).
6. **Dejá la marca de ejecución** (abajo). Sin ella, el recordatorio sigue avisando.
7. **Bitácora**, si hubo algo relevante.

## Informe

```
## Vigilancia normativa: AAAA-MM (hoy: fecha)

### <jurisdicción>
- [CONFIRMADO | interpretativo] <qué cambió> · <fecha> · <fuente> · <impacto: qué obligación o D-X toca>

### Sin cambios
- <ítems revisados sin novedad, en una línea>

### Acciones propuestas
- <ticket, decisión a reabrir, archivo a actualizar>
```

Si una jurisdicción no tiene novedades, se dice. **No se inventan cambios para rellenar**:
que no haya nada nuevo es un resultado válido.

## Marca de ejecución (obligatoria al terminar)

En `vigilancia/<año>.md`, al principio de las entradas:

```
## AAAA-MM: ejecutada (AAAA-MM-DD)
- Hallazgos: <ninguno | resumen de una línea>. Tickets y decisiones: <T-XXX, D-X | ninguno>
```

El recordatorio de inicio de sesión busca `## AAAA-MM` del mes en curso. Si el archivo del
año no existe, se crea con un título `# Vigilancia normativa <año>`.

## Límite

Detecta y reporta; no confirma con rango vinculante ni presenta nada. Ante un cambio
importante, el resultado natural es un ticket que diga "consultar con un profesional", no una
conclusión cerrada.
