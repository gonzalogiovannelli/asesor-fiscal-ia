---
name: ticket
description: Gestiona los tickets del proyecto (crear, listar, actualizar y cerrar en tickets/). Úsala siempre que aparezca una tarea o pendiente que no se resuelve en el momento, o para revisar y cerrar trabajo en curso. Todo el trabajo del proyecto se gestiona por tickets.
---

# Tickets

Opera el sistema de `tickets/`. Convenciones en `tickets/README.md`. **Todo pendiente vive
como ticket.** Acciones: nuevo, listar, actualizar, cerrar.

## Nuevo

1. **Siguiente id**: el mayor `T-XXX` de `abiertos/` y `cerrados/`, más uno, con tres
   dígitos.
2. Creá `tickets/abiertos/T-XXX-<slug-corto>.md` desde `tickets/_template.md`: frontmatter
   (id, título, estado `abierto`, prioridad, etiquetas, fechas) y Objetivo, Contexto y
   Criterios de aceptación.
3. Fila en el índice de abiertos de `tickets/README.md` **y** en `contexto/INDICE.md`. El
   control de coherencia bloquea el commit si falta alguna.
4. Opcional: entrada en la bitácora si es relevante.

## Listar

Los tickets de `abiertos/` con id, título, prioridad y estado, de prioridad alta a baja.
Resaltá los 🔴 y los `bloqueado`.

## Actualizar

Cambiá el `estado`, marcá criterios cumplidos, añadí una nota fechada en "Avance" y
actualizá `actualizado:`. Si cambia el estado, también la tabla del README.

## Cerrar

1. Rellená "Resultado" con lo que se hizo y los enlaces.
2. `estado: cerrado` y `actualizado:`.
3. **Mové** el archivo a `tickets/cerrados/` con `git mv`, para conservar el historial.
4. Sacá la fila de abiertos (README e INDICE) y añadila a cerrados en el README, con fecha y
   resultado en una línea.
5. Si el cierre implica una decisión fiscal, `registrar-decision`.
6. Entrada en la bitácora.

## Notas

- No se reutilizan ids de tickets cerrados.
