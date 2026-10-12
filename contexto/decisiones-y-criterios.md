# Decisiones y criterios

Qué se decidió, cuándo y por qué (D-X), y los principios con los que se evalúa lo nuevo
(C-X). Las decisiones las registra la skill `registrar-decision`.

## Decisiones tomadas

*Todavía ninguna.*

## Criterios de evaluación para situaciones futuras

Los principios que se aplican cuando aparece una situación nueva no cubierta por una decisión.
Vienen de base con la plantilla; se pueden ajustar, y cada ajuste se anota en el log.

### C1: Evaluación de un movimiento
Cualquier movimiento (ingreso nuevo, gasto grande, transferencia inusual, oferta de un
cliente, estructura propuesta) se evalúa con: magnitud económica, obligaciones formales que
dispara, probabilidad de revisión, consecuencias si no cumple, y **la alternativa legal y su
coste**. La decisión es del usuario, pero siempre con esos datos en la mano.

### C2: Qué sí y qué no entra en este proyecto
**Sí:** optimización fiscal legal, evaluación de las consecuencias de lo que el usuario decide
hacer, cumplimiento de obligaciones formales, planificación, calendario, alertas normativas.
**No:** estructuras de ocultamiento, testaferros, capas societarias de opacidad pura,
instrucciones para evadir la trazabilidad. El proyecto evalúa decisiones; no diseña esquemas
para ocultar.

### C3: Conflicto entre jurisdicciones
En general, el país de residencia fiscal grava la renta mundial, y los convenios de doble
imposición moderan pero no eliminan esa obligación. **Hay excepciones** (por ejemplo, países
que gravan por ciudadanía): `alta` las identifica para tu caso y las deja escritas en
`jurisdicciones/`.

### C4: Zona gris
Cuando hay dos interpretaciones posibles de una norma, se documentan ambas con sus pros y
contras. La elección del usuario queda como una D-X, con su razonamiento.

### C5: Conservadurismo en obligaciones formales
Las obligaciones formales (presentar a tiempo, llevar registros, cumplir plazos) se cumplen
siempre, aunque no haya cuota a pagar. Las multas por incumplimiento formal suelen ser
automáticas y altas, y el ahorro de no presentar es nulo.

### C6: Ante la duda, correcto y documentado, no "pagar por las dudas"
Ante una posición favorable al contribuyente con **base normativa clara**, lo que corresponde
es aplicarla y **documentar el fundamento**, no sobrepagar por si acaso. Sobrepagar no es
neutro: es liquidez inmovilizada a rendimiento cero. "Pagar por las dudas" solo vale como
decisión consciente en una zona gris real. **Agresivo** es inventar una deducción;
**correcto** es aplicar lo que la propia administración reconoce. No confundir con C5: las
obligaciones formales se cumplen siempre; C6 es sobre la cuota.

### C7: Compartimentación por jurisdicción
Los documentos de cada país son **autónomos**: en los artefactos de una jurisdicción
(declaraciones, justificantes, notas) no se menciona ninguna otra, salvo los campos que el
propio formulario oficial pide. La capa de análisis (`contexto/`, este documento,
`consultas/`) sí coordina jurisdicciones, pero nunca vuelca contenido de una en la carpeta de
otra. Si hace falta que algo no aparezca nunca en una carpeta, se declara en
`scripts/terminos-prohibidos.conf` y el control lo bloquea en el commit.

### C8: Gobierno del dato
Los libros registro son la fuente única del dato por factura; `procesar-facturas` es la única
autoridad de cálculo; los resúmenes transportan y suman. El modelo completo vive en
`contexto/arquitectura.md`.

### C9: Lo que valida un profesional se adopta
Cuando un profesional ya presentó o validó una posición defendible, el libro la adopta en vez
de mantener una más conservadora. No aplica a errores de hecho, ni a nada que roce C2.

## Disparadores que obligan a reabrir decisiones

Umbrales y eventos que obligan a reevaluar. `alta` carga los de cada jurisdicción y
`revisar-vencimientos` y `actualizar-saldos` los vigilan.

*Todavía ninguno.*

## Log de revisiones de decisiones

| Fecha | Decisión | Cambio | Por qué |
|---|---|---|---|
