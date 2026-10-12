# asesor-fiscal-ia

Un sistema para llevar tu situación fiscal con [Claude Code](https://claude.com/claude-code):
qué tenés que presentar, dónde y cuándo, tus libros de facturas, las decisiones que tomaste y
por qué, y una vigilancia periódica de los cambios de normativa.

No trae ningún país cargado. **Arranca con una entrevista** (dónde residís, en qué país,
provincia y ciudad, qué actividad tenés, qué facturás y a quién, qué tenés fuera) y a partir
de ahí investiga en fuentes oficiales qué obligaciones te tocan y arma el resto.

> **No es asesoramiento fiscal.** Te ayuda a entender, ordenar y preparar. La validación final
> y la presentación de lo complejo son de un profesional matriculado.

## Cómo se usa

1. Creá tu copia a partir de esta plantilla, **como repositorio privado**. Va a contener tus
   datos fiscales: nunca la hagas pública.
2. Activá el control de coherencia antes del primer commit:
   ```bash
   git config core.hooksPath .githooks
   ```
3. Abrí Claude Code en la carpeta y corré **`/alta`**. Te entrevista, investiga cada
   jurisdicción que te toca y genera tu ficha, las referencias de cada país, el calendario de
   vencimientos y los libros.
4. Desde ahí se opera con las skills:

| Skill | Para qué |
|---|---|
| `/alta` | Alta inicial de tu situación, y alta de un país nuevo cuando aparece (mudanza, cliente, bien) |
| `/procesar-facturas` | Lee los PDF, les pone ID y nombre estándar, calcula lo deducible y los registra en el libro |
| `/revisar-vencimientos` | Qué vence pronto, qué falta presentar y qué umbral está cerca |
| `/vigilar-normativa` | Barrido mensual de cambios de ley contra fuentes oficiales |
| `/actualizar-saldos` | Saldos y valoraciones, y aviso si se cruza un umbral |
| `/registrar-decision` | Deja escrita una decisión fiscal, con su razonamiento y cuándo reabrirla |
| `/ticket` | Todo pendiente que no se resuelve en el momento |
| `/destilar` | Cierre de sesión: qué deja la conversación y dónde se guarda |

## Cómo está pensado

Lo explica [`contexto/arquitectura.md`](contexto/arquitectura.md). En corto:

- **Un solo hogar por dato.** Lo demás enlaza, no copia.
- **Tres niveles de verdad:** el libro de facturas es la fuente viva; los resúmenes solo
  transportan y suman; el justificante presentado es inmutable.
- **La historia se congela** (bitácora, tickets cerrados) y solo se mantiene al día la capa viva.
- **Un control que bloquea el commit** si algo no cuadra: enlaces rotos, rutas muertas,
  índices desincronizados, libros que no suman, y cifras de un resumen que no coinciden con el
  libro del que salen. Y si el control no puede comprobar algo, lo dice en vez de pasar en verde.

## El ejemplo de España

[`ejemplos/documentos-es/`](ejemplos/documentos-es/) trae un libro de emitidas, uno de
recibidas y una liquidación trimestral con **datos inventados**, en el formato del libro
registro español (IVA, retención de IRPF, inversión del sujeto pasivo, amortización). Sirve
para ver cómo funciona y como modelo: cuando `/alta` da de alta España usa este formato, y
para otro país define el suyo.

Para comprobar que el control funciona, `bash scripts/probar-check.sh` rompe una copia del
ejemplo a propósito y verifica que el control lo detecta.
