---
name: revisar-vencimientos
description: Repasa el calendario fiscal y devuelve qué vence pronto, qué falta presentar y qué umbrales están cerca, cruzando calendario/vencimientos.md con el estado real en contexto/historico-declarativo.md y en las liquidaciones de cada expediente. Úsala en cada revisión periódica o cuando el usuario pregunte "qué tengo encima", "qué vence", "qué me falta presentar".
---

# Revisar vencimientos

Un informe de obligaciones próximas que cruza **fechas** (calendario) con **estado real**
(histórico y liquidaciones). Que en cualquier momento se pueda preguntar "¿qué vence y qué me
falta?" y obtener una respuesta accionable.

## Fuentes (leer todas)

1. `calendario/vencimientos.md`: la fecha de cada obligación.
2. `contexto/historico-declarativo.md`: qué está presentado y qué pendiente en cada
   jurisdicción, y los riesgos abiertos.
3. Las liquidaciones de cada expediente (`documentos-<país>/declaraciones/`): el **estado
   vivo** de cada periodo. El calendario y el histórico pueden ir por detrás: **cruzá siempre
   contra esto** para no dar por pendiente algo ya presentado.
4. `contexto/decisiones-y-criterios.md`, sección **Disparadores**, y `contexto/mapa-activos.md`:
   por si un saldo o un evento está cerca de un umbral.

La fecha de hoy está en el contexto de la sesión. No la inventes.

## Pasos

1. **Ventana**: la que pida el usuario; por defecto, los próximos 90 días.
2. **Recolectá** del calendario todo lo que cae en la ventana, incluidas las recurrentes.
3. **Cruzá con el estado real**: ✅ presentada · ⏳ pendiente · ❓ a verificar.
4. **Detectá incoherencias** entre calendario, histórico y liquidaciones (fechas distintas
   para la misma obligación, estados que no coinciden). Valen tanto como los vencimientos.
5. **Comprobá los disparadores**: si un umbral está cerca de cruzarse, va como alerta aunque
   no tenga fecha.
6. **Redactá el informe** (abajo).
7. **Proponé tickets** para lo que requiera acción no rutinaria. No los crees sin
   confirmación, salvo que el usuario lo pida.

## Informe

> 🔴 crítico (multa automática alta) · 🟠 importante · 🟢 rutinario
> ✅ presentada · ⏳ pendiente · ❓ a verificar

```
## Vencimientos: <ventana> (hoy: <fecha>)

### 🔴 Críticos
- [estado] <obligación> · <fecha> (<jurisdicción>) · <días restantes> · <nota>

### 🟠 Importantes
### 🟢 Rutinarios

### ⚠️ Incoherencias y alertas
- <incoherencia o disparador cerca de cruzarse>

### Acciones sugeridas
- <pendiente que conviene convertir en ticket>
```

Cada bloque ordenado por fecha. Si un bloque queda vacío, se omite. Siempre con los **días
restantes**.

**Las obligaciones 🔴 se recuerdan siempre** que estén en la ventana o cerca, aunque el
usuario haya pedido otra cosa.

## Notas

- Solo lee y reporta; no marca presentaciones como hechas. Eso se actualiza en el histórico y
  en la liquidación correspondiente (skill `destilar`).
- Tras una revisión relevante, una línea en la bitácora.
