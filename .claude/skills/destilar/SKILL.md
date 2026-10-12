---
name: destilar
description: Cierre de sesión. Decide qué residuo permanente deja la conversación (dato, decisión D-X, criterio C-X, análisis reutilizable o pendiente) y lo archiva en un solo sitio, actualizando contexto/INDICE.md. Ejecútala al terminar cualquier sesión de trabajo fiscal, o cuando el usuario diga "guardá esto" o "cerrá".
---

# Destilar (cierre de sesión)

El trabajo de este proyecto **no es capturar conversaciones, es destilar su residuo.** La
charla es desechable; lo que importa es lo que cambia de forma permanente.

## Modelo de tres estados

1. **Chat**: no cambia nada permanente. Muere al cerrar, y está bien que muera.
2. **Residuo**: la conversación cambió qué se sabe o qué se va a hacer, o produjo un análisis
   caro de repetir. Va a **un** hogar.
3. **Pendiente**: queda una acción futura. Va a un **ticket**.

Una sesión puede no producir nada, o varios residuos y un ticket. **No fuerces artefactos:**
la fricción de guardar debe ser menor que el dolor de re-pensarlo.

## Pasos

1. **Pregunta de cierre**, la proponés vos: *"Cierre: ¿esto deja algún residuo permanente
   (dato, decisión, criterio, análisis) o algún pendiente? ¿O muere en el chat?"*
2. **Enrutá cada residuo a su único hogar** (no copies; enlazá):

   | Residuo | Dónde vive | Cómo |
   |---|---|---|
   | Cambió un **dato** (saldo, alta, fecha) | `contexto/` | Editá el archivo y su "Última actualización" |
   | **Estado de una presentación** | la liquidación del expediente; histórico y calendario la reflejan | No dupliques: la liquidación manda |
   | Importes de **facturas** | los libros, vía `procesar-facturas` | Nunca a mano en los resúmenes |
   | **Regla de gobierno o de estructura** | `contexto/arquitectura.md` | Un solo hogar |
   | **Decisión** (se eligió un camino) | `contexto/decisiones-y-criterios.md` (D-X) | Skill `registrar-decision` |
   | **Criterio** reutilizable nuevo | `contexto/decisiones-y-criterios.md` (C-X) | En la sección de criterios |
   | **Cambio de norma** | `jurisdicciones/<país>.md` | Con fuente y fecha |
   | **Análisis reutilizable** sin elección | `consultas/AAAA-MM-DD-tema.md` | Plantilla de abajo |
   | **Acción futura** | `tickets/abiertos/` | Skill `ticket` |

3. **Actualizá `contexto/INDICE.md`**: la fila de la decisión, ticket o consulta. Solo
   enlaces, nunca contenido copiado.
4. **Bitácora**: si hubo un cambio relevante, una línea en `bitacora/<año>.md`.
5. **Coherencia** (`contexto/arquitectura.md`, secciones 5 y 6): si el cambio tocó un dato con
   dependientes, **propagalo en la misma sesión**. Si moviste o renombraste algo, buscá la
   ruta vieja y arreglá las referencias. La historia congelada no se retro-edita. Y
   `bash scripts/check-coherencia.sh` en verde.

## Regla de bifurcación

- Pregunta rápida sin consecuencia: **nada**.
- Análisis que conviene no repetir: **consulta**.
- Si además se eligió un camino: **D-X**.
- Si además queda algo por hacer: **ticket**.

## Plantilla de consulta (cinco campos, no más)

```markdown
# <tema>: AAAA-MM-DD
- **Pregunta**: <qué se preguntó>
- **Respuesta corta**: <conclusión en una a tres líneas>
- **Razonamiento**: <por qué, lo justo para no rehacerlo>
- **Referencias**: <D-X, C-X, archivo de contexto, norma en jurisdicciones/>
- **Deja residuo**: <ninguno | D-X creada | ticket T-XXX | dato actualizado en ...>
```

## Higiene

- Todo dato fiscal relevante lleva **fecha** y, si depende de la norma, **ejercicio
  aplicable** y **fuente**. Un dato sin fecha de caducidad es una mentira futura.
- `consultas/` no es una bandeja de entrada: solo entra lo reutilizable.

## Límite

Organiza y archiva; **no valida la exactitud fiscal**.
