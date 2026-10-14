# asesor-fiscal-ia

Un sistema para llevar tu situación fiscal con [Claude Code](https://claude.com/claude-code):
qué tenés que presentar, dónde y cuándo, tus libros de facturas, las decisiones que tomaste y
por qué, y una vigilancia periódica de los cambios de normativa.

No trae ningún país cargado. **Arranca con una entrevista** (dónde residís, en qué país,
provincia y ciudad, qué actividad tenés, qué facturás y a quién, qué tenés fuera) y a partir
de ahí investiga en fuentes oficiales qué obligaciones te tocan y arma el resto.

> **No es asesoramiento fiscal.** Te ayuda a entender, ordenar y preparar. La validación final
> y la presentación de lo complejo son de un profesional matriculado.

## Requisitos

- [Claude Code](https://claude.com/claude-code)
- `git` y `bash` (en Windows, el de Git for Windows)
- Un `awk` que entienda UTF-8. `gawk` es lo recomendado; en macOS se instala con
  `brew install gawk`

## Cómo se usa

1. **Creá tu copia como repositorio privado.** Va a contener tus datos fiscales: nunca la
   hagas pública. En GitHub, **"Use this template"** y elegí privado. **No hagas un fork:**
   el fork de un repo público no puede ser privado.
2. Activá el control de coherencia **antes del primer commit**:
   ```bash
   git config core.hooksPath .githooks
   ```
   Desde ahí, ningún commit pasa si algo no cuadra, y cada commit sube la versión del repo
   según su prefijo (ver más abajo). Para comprobar que el control funciona
   en tu máquina: `bash scripts/probar-check.sh`.
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

`bash scripts/probar-check.sh` rompe una copia del ejemplo de muchas maneras a propósito y
verifica que el control detecta cada una. **Por eso el ejemplo no se borra** aunque ya tengas
tus libros.

## Lo que pasa solo

- **Al abrir una sesión:** si no hay ficha, te propone `/alta`; si este mes no se hizo la
  vigilancia normativa, te lo recuerda.
- **Al cerrar una sesión:** commitea lo que haya cambiado en `documentos-*/` (facturas,
  libros, justificantes), pasando por el control. **No hace push.** Si el control lo bloquea,
  deja los archivos sin commitear y te avisa al abrir la sesión siguiente.

## Versión

El repo tiene versión (`VERSION`, `CHANGELOG.md` y una etiqueta `vX.Y.Z` por versión), y sube sola
con cada commit según su prefijo, siguiendo [Conventional Commits](https://www.conventionalcommits.org/)
y [SemVer](https://semver.org/):

- `chore:` datos (facturas, libros, consultas, contexto, tickets). No sube la versión
- `fix:` un ajuste a una skill, un hook o un script. Sube el último número
- `feat:` algo nuevo (una skill, un script, un mecanismo). Sube el del medio
- `!` detrás del tipo (`feat!:`) si cambia cómo se usa el repo. Sube el primero

El hook `commit-msg` rechaza el commit que no lleve prefijo, y `post-commit` sube la versión.
Lo anterior al 2026-10-14 se reconstruyó del historial.

## Licencia

MIT. Ver [LICENSE](LICENSE).
