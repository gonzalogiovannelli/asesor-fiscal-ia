# Tickets

**Todo pendiente se gestiona como ticket.** Si algo no se resuelve en el momento, se abre un
ticket; no se deja en la memoria de una conversación.

## Estructura

- `abiertos/`: pendientes o en progreso
- `cerrados/`: resueltos, archivo histórico
- `_template.md`: plantilla

## Ciclo de vida

1. **Crear**: archivo en `abiertos/` con id `T-XXX` (skill `ticket`)
2. **Trabajar**: estado `en-progreso`, con notas de avance
3. **Cerrar**: resultado anotado, `estado: cerrado`, se mueve a `cerrados/`. Si genera una
   decisión fiscal, se registra como D-X. Siempre lleva entrada en la bitácora

## Numeración

Correlativa: `T-001`, `T-002`... No se reutilizan números.

## Estados y prioridad

Estados: `abierto` · `en-progreso` · `bloqueado` · `cerrado`.
Prioridad: `alta` · `media` · `baja`; 🔴 para obligaciones con multa automática.

## Índice de tickets abiertos

| ID | Título | Prioridad | Estado | Creado |
|----|--------|-----------|--------|--------|

## Índice de tickets cerrados

| ID | Título | Cerrado | Resultado |
|----|--------|---------|-----------|
