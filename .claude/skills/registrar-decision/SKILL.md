---
name: registrar-decision
description: Documenta una decisión fiscal como D-X en contexto/decisiones-y-criterios.md, con fecha, razonamiento, alternativa legal y su coste, fuente, vigencia y condiciones de revisión. Úsala siempre que el usuario tome una decisión fiscal que deba quedar registrada.
---

# Registrar decisión (D-X)

Que el proyecto recuerde **qué se decidió, cuándo y por qué**, y bajo qué condiciones hay
que reabrirlo.

## Pasos

1. **Leé** `contexto/decisiones-y-criterios.md`: las decisiones existentes y el siguiente
   número libre.
2. **Reuní con el usuario** estos campos (preguntá lo que falte; no inventes):
   - **Contenido**: qué se decide, en una o dos frases
   - **Fecha**: la de hoy, salvo que indique otra
   - **Razonamiento**, con el marco C1: magnitud económica, obligaciones formales,
     probabilidad de revisión, consecuencias si no cumple y **siempre la alternativa legal y
     su coste**
   - **Asumido por el usuario**: sí o no, y con qué información
   - **Condiciones de revisión**: qué obliga a reabrirla
3. **Escribí** la entrada `### DX: <título>` al final de "Decisiones tomadas".
4. **Disparadores**: si la decisión introduce umbrales o eventos a vigilar, a la sección de
   disparadores.
5. **Log**: si revisa una decisión anterior, una fila en el log de revisiones.
6. **Índice**: fila en la tabla de decisiones de `contexto/INDICE.md`.
7. **Bitácora**: entrada que cite la D-X.
8. Si deja tareas, **tickets**.

## Línea que no se cruza (C2)

Este registro documenta decisiones del usuario y sus **consecuencias**, con la exposición
honesta del riesgo. **No** se usa para diseñar ocultamiento. Cuando una decisión implique
renta no declarada, en la misma entrada se deja escrita la alternativa legal (por ejemplo,
una regularización voluntaria) con su coste, para que la elección sea informada.

## Plantilla

```markdown
### DX: <título corto>
- **Fecha**: AAAA-MM-DD
- **Contenido**: <qué se decide>
- **Razonamiento**:
  - <magnitud económica>
  - <obligaciones formales implicadas>
  - <probabilidad de revisión y consecuencias si no cumple>
  - <alternativa legal y su coste>
- **Asumido por el usuario**: <sí o no, con qué información>
- **Fuente / base normativa**: <norma, doctrina o archivo de jurisdicciones/; o "criterio propio, sin validar por un profesional">
- **Ejercicio aplicable**: <años>
- **Vigencia / caducidad**: <hasta cuándo vale; qué cambio normativo la invalidaría>
- **Condiciones de revisión**: <disparadores que obligan a reabrir>
```

## Exactitud, no solo consistencia

Una decisión bien archivada puede estar equivocada. Por eso cada D-X cita su **fuente** y su
**ejercicio**, y dice si la **validó un profesional** o es criterio propio. La ley cambia por
año: un dato correcto hoy caduca por cambio normativo, no solo por cambio de dato.
