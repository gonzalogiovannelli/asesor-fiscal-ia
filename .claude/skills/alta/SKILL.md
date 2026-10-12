---
name: alta
description: Da de alta la situación fiscal del usuario o una jurisdicción nueva. En el alta inicial entrevista al usuario (residencia por país, provincia y ciudad, nacionalidades, actividad, qué factura y a quién, ingresos y bienes en otros países, sociedades) y escribe su ficha; después, por cada jurisdicción que le toca, investiga en fuentes oficiales qué obligaciones tiene y genera la referencia normativa, el calendario de vencimientos, los disparadores y el expediente con sus libros. Úsala cuando no exista contexto/ficha.md, o cuando aparezca un país nuevo (mudanza, cliente, bien, sociedad), o cuando el usuario diga "alta", "dar de alta", "me mudé", "empecé a facturar", "tengo un bien en otro país".
---

# Alta

Convierte la situación de una persona en un sistema que puede operar: **qué tiene que
presentar, dónde, cuándo, y con qué registros.** No trae ningún país precargado: lo investiga
para el caso concreto.

**Dos modos:**

- **Alta inicial**: no existe `contexto/ficha.md`. Entrevista completa y después un alta de
  jurisdicción por cada una que aparezca.
- **Alta de jurisdicción**: ya hay ficha y aparece un país, provincia o ciudad nuevos.
  Se actualiza la ficha con lo que cambió y se corre solo la parte B.

## Principios que no se saltan

- **La normativa no se afirma de memoria.** El conocimiento del modelo tiene fecha de corte.
  Toda obligación, plazo, umbral o tipo se busca con WebSearch y WebFetch **en la fuente
  oficial** de esa jurisdicción y se cita con su fecha. Prensa y asesorías sirven para
  detectar, no para afirmar.
- **Cada afirmación normativa se marca** como `CONFIRMADO` (fuente oficial, con enlace y
  fecha) o `interpretativo` (lectura propia o de terceros). Lo interpretativo que tenga
  consecuencias materiales abre un ticket para validarlo con un profesional.
- **No se inventan datos del usuario.** Lo que no sepa queda como pendiente en la ficha y,
  si importa, como ticket.
- **Una pregunta o un bloque corto por turno.** Es una entrevista, no un formulario.
- **Un solo hogar por dato:** la situación del usuario va a `contexto/`; la norma va a
  `jurisdicciones/`. La referencia normativa no repite datos personales, enlaza a la ficha.

## A. Entrevista (solo en el alta inicial)

Por bloques, en este orden. Adaptá las preguntas a lo que vaya saliendo y saltá lo que no
aplique.

1. **Residencia.** País, provincia o estado o comunidad, y ciudad. Desde cuándo. Si en el
   último año vivió en otro país, cuántos días en cada uno. Dónde está su centro de intereses
   (familia, trabajo, vivienda)
2. **Nacionalidades.** Todas. Algunos países gravan por ciudadanía y no por residencia
3. **Familia.** Estado civil y régimen económico, hijos a cargo, si declara en conjunto
4. **Actividad.** Empleado, autónomo o equivalente, sociedad propia. Desde cuándo. **Qué
   factura y a quién:** país del cliente, empresa o particular, plataformas. Si cobra en otra
   moneda
5. **Ingresos de fuera.** Alquileres, dividendos, intereses, pensiones, ventas de bienes, y
   de qué país vienen
6. **Bienes y cuentas.** Inmuebles, cuentas, inversiones, criptoactivos: en qué país y valor
   aproximado. Hace falta para los umbrales de declaraciones informativas
7. **Sociedades.** Cualquier entidad propia o participada, en cualquier país, y qué hace
8. **Situación actual.** Quién le presenta hoy (gestor, contador, nadie), qué está
   presentado, qué está pendiente, si hay algún requerimiento abierto
9. **Identificadores.** Su número fiscal en cada país, **solo si quiere guardarlo**. Lo usa
   `procesar-facturas` para comprobar que una factura va a su nombre

**Salida de la entrevista:**

| Archivo | Qué lleva |
|---|---|
| `contexto/ficha.md` | Bloques 1 a 4 y 9, con fecha de cada dato |
| `contexto/mapa-ingresos-y-flujos.md` | Bloques 4 y 5: qué entra, de dónde y en qué moneda |
| `contexto/mapa-activos.md` | Bloques 6 y 7, con valores y fecha de valoración |
| `contexto/historico-declarativo.md` | Bloque 8: presentado y pendiente por jurisdicción |

**Después, la lista de jurisdicciones.** Salen de: residencia (país, y sus niveles
subnacional y municipal), nacionalidades que tributen por ciudadanía, país de origen de
cada ingreso, país de cada bien y de cada sociedad. Se le muestra la lista con el motivo de
cada una y **se confirma con el usuario antes de investigar**.

## B. Alta de una jurisdicción

Por cada jurisdicción confirmada:

### 1. Investigar

Con WebSearch y WebFetch, priorizando las fuentes oficiales:

- La **administración tributaria** nacional y el **boletín oficial**
- La administración del **nivel subnacional** (provincia, estado, comunidad) si tiene
  tributos o tramos propios
- El **municipio**, si hay tributos locales que le toquen (inmuebles, actividad, vehículos)
- Los **convenios de doble imposición** entre esta jurisdicción y las demás de su lista

Qué buscar, siempre contra su ficha y no en general:

- Criterio de residencia fiscal y si le aplica
- Cómo tributa cada tipo de ingreso que tiene, y quién retiene
- **Obligaciones que le tocan:** cada declaración con su periodicidad, plazo, formulario o
  modelo, umbral si lo hay y sanción por incumplimiento
- **Obligaciones de registro:** si tiene que llevar libros de facturas o de ingresos y gastos,
  con qué contenido y formato, y requisitos de la factura
- Declaraciones informativas (bienes en el extranjero, operaciones con no residentes,
  cripto) y sus umbrales
- Cómo se evita la doble imposición con sus otros países

### 2. Escribir la referencia: `jurisdicciones/<país>.md`

Si hay tributos subnacionales o municipales relevantes, en una sección propia del mismo
archivo, o en `jurisdicciones/<país>-<región>.md` si es extensa.

```markdown
# Jurisdicción: <país> (<región>, <ciudad>)

Por qué aplica: <residencia | fuente de ingresos | bien | sociedad | ciudadanía>, ver `contexto/ficha.md`.
Última verificación: AAAA-MM-DD

## Fuentes oficiales
| Organismo | Sitio |

## Residencia fiscal
## Cómo tributa cada ingreso que tenés
## Obligaciones
| Obligación | Periodicidad | Plazo | Formulario | Umbral | Sanción | Estado |
## Registros y facturación
## Declaraciones informativas
## Nivel subnacional y municipal
## Convenios con tus otras jurisdicciones
## Lista de vigilancia
<qué cambios mirar cada mes en esta jurisdicción; la lee vigilar-normativa>
## Pendientes de confirmar
```

`Estado` de cada fila: `CONFIRMADO (enlace, fecha)` o `interpretativo`.

### 3. Calendario: `calendario/vencimientos.md`

Cada obligación con **fecha concreta** para lo que queda del año y el siguiente, su
jurisdicción y su gravedad: 🔴 multa automática alta · 🟠 importante · 🟢 rutinaria. Si el
archivo no existe, se crea con una tabla `| Fecha | Obligación | Jurisdicción | Gravedad | Estado |`.

### 4. Disparadores

Los umbrales que obligan a algo (declaración informativa, cambio de régimen, delito fiscal)
van a la sección **Disparadores** de `contexto/decisiones-y-criterios.md`, con su
jurisdicción y su fuente. Los vigilan `revisar-vencimientos` y `actualizar-saldos`.

### 5. Expediente: `documentos-<código>/`

Código de país en minúsculas (`es`, `ar`, `mx`...). Con `declaraciones/<año>/` y, si la
jurisdicción exige llevar registros, `facturas-emitidas/<año>/`, `facturas-recibidas/<año>/`
y los libros, **uno por año**:

- **Si es España:** el formato es el de `ejemplos/documentos-es/`. Se crean
  `registro-emitidas-<año>.md` y `registro-recibidas-<año>.md` copiando la cabecera de
  columnas del ejemplo, sin filas, y con la línea de totales en cero **con estos rótulos
  exactos**, que son contrato con el control:

  ```
  **Totales emitidas <año>:** Base: 0,00 € · IVA repercutido: 0,00 € · Retención: 0,00 € · Facturado: 0,00 € · Cobrado: 0,00 €
  **Totales recibidas <año>:** Base: 0,00 € · Retención: 0,00 € · Total facturas: 0,00 €
  ```

  Y se añade `documentos-es es` a `scripts/libros.conf`.
- **Si es otro país:** se diseña el libro a partir de la obligación de registro que se
  investigó en el paso 1 (qué columnas exige la norma, qué impuesto se repercute, qué
  retenciones hay). Y entonces, **en este orden**:
  1. El esquema de columnas y las reglas de cálculo se escriben como sección del país en
     `procesar-facturas`, que es la única autoridad de cálculo
  2. En `scripts/check-coherencia.sh` se añaden `recon_<formato>` y `canon_<formato>`, con
     su vocabulario de claves de transporte, y el `case` que los llama
  3. Se crea un ejemplo con datos inventados en `ejemplos/documentos-<código>/` y sus casos
     de rotura en `scripts/probar-check.sh`
  4. **Se corre `bash scripts/probar-check.sh` y tiene que detectar todas las roturas.** Un
     check que no se probó rompiendo algo no cuenta como control
  5. Se añaden las dos líneas a `scripts/libros.conf` (el ejemplo y el expediente real)

  **El alta de un país con libros no termina sin su check.** Si el expediente se declara
  en `libros.conf` antes de que exista, el control da `SIN CHECK` y **bloquea todos los
  commits del repo**, que es lo que tiene que pasar: un libro que nadie cuadra no puede
  pasar por controlado. **No se deja el expediente fuera de `libros.conf` para esquivar el
  aviso.** Si no da el tiempo, el alta de ese país se deja a medias en un ticket y sin
  commitear los libros.
- **Si no exige registros** (por ejemplo, solo una declaración anual de un alquiler): solo
  `declaraciones/`, y nada en `libros.conf`.

**Compartimentación (C7):** se pregunta si hay algo que no deba aparecer nunca en los
documentos de esta jurisdicción (por ejemplo, una sociedad de otro país). Si lo hay, se
añade a `scripts/terminos-prohibidos.conf`.

### 6. Cerrar

1. Tickets para cada pendiente de confirmar que sea material, y para cada interpretación que
   haya que validar con un profesional
2. `contexto/INDICE.md`: la ficha, los mapas, la jurisdicción, el calendario y el expediente
3. En el calendario, una **auditoría anual completa** (arquitectura, sección 7, nivel 4) y la
   **apertura del año nuevo** de los libros a principios de enero
4. Primera marca en `vigilancia/<año>.md`: la investigación de alta cuenta como barrido de
   ese mes para esa jurisdicción
5. Entrada en `bitacora/<año>.md`
6. `bash scripts/check-coherencia.sh` en verde, y commit

## Mudanza

Una mudanza es un alta de jurisdicción para el país nuevo **y** una actualización del viejo:
en `jurisdicciones/<país-viejo>.md` se anota desde cuándo deja de ser residencia y qué
obligaciones quedan del último año (la última declaración, una posible salida o cambio de
residencia). El país viejo no se borra mientras tenga algo pendiente.

## Límite

`alta` investiga, ordena y propone. **No es asesoramiento:** la validación de lo
interpretativo y la presentación de lo complejo son de un profesional, y eso se deja escrito
como ticket cuando toca.
