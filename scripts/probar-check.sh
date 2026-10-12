#!/usr/bin/env bash
# probar-check.sh: prueba negativa del control de coherencia.
# "Todo check nuevo se valida rompiendo algo a propósito" (arquitectura.md, sección 7).
#
# Copia el repo a una carpeta temporal, rompe una cosa por vez y comprueba que
# check-coherencia.sh falla con la incidencia esperada. El repo real no se toca.
# Uso:  bash scripts/probar-check.sh

set -uo pipefail
cd "$(dirname "$0")/.." || exit 2
ORIG="$(pwd)"
BASE="$(mktemp -d)"; trap 'rm -rf "$BASE"' EXIT
fallos=0

copia() { rm -rf "$BASE/r"; mkdir -p "$BASE/r"; (cd "$ORIG" && tar --exclude=.git -cf - .) | (cd "$BASE/r" && tar -xf -); }

caso() { # $1=nombre  $2=texto esperado en la salida  $3=comando que rompe algo
  copia
  (cd "$BASE/r" && eval "$3")
  salida="$(bash "$BASE/r/scripts/check-coherencia.sh" 2>&1)"; code=$?
  if [ "$code" -ne 0 ] && grep -q "$2" <<< "$salida"; then
    echo "  ok     $1"
  else
    echo "  FALLA  $1: el control no detectó la rotura (esperaba '$2')"; fallos=$((fallos+1))
  fi
}

echo "Línea base:"
copia
if bash "$BASE/r/scripts/check-coherencia.sh" > /dev/null 2>&1; then
  echo "  ok     el repo sin tocar pasa en verde"
else
  echo "  FALLA  el repo sin tocar no pasa: arreglalo antes de probar"; exit 1
fi

L=ejemplos/documentos-es
echo "Roturas (cada una debe hacer saltar el control):"
caso "total de una fila mal sumado"        "CUADRE"            "sed -i 's/| 1.060,00 | F-0001/| 1.070,00 | F-0001/' $L/registro-emitidas.md"
caso "suma de columna distinta del total"  "suma Base columna" "sed -i 's/Base: 1.150,00/Base: 1.160,00/' $L/registro-recibidas.md"
caso "rótulo de totales renombrado"        "ilegible"          "sed -i 's/Cobrado:/Neto:/' $L/registro-emitidas.md"
caso "resumen que no coincide con el libro" "TRANSPORTE"       "sed -i 's/399,00/398,00/' $L/declaraciones/2026/2026-1T/liquidacion.md"
caso "etiqueta que no existe en el libro"  "no existe"         "sed -i 's/@liq.303.2026-1T/@liq.303.2027-1T/' $L/declaraciones/2026/2026-1T/liquidacion.md"
caso "etiqueta fuera de un expediente"     "NO se verificaron" "printf 'Total: **5,00 €** <!--@emitidas.iva.2026-->\n' > contexto/suelto.md"
caso "enlace interno roto"                 "ENLACE ROTO"       "printf '[x](no-existe.md)\n' >> README.md"
caso "ticket sin fila en el índice"        "INDICE TICKET"     "printf -- '---\nid: T-001\n---\n' > tickets/abiertos/T-001-prueba.md"
caso "término prohibido en una carpeta"    "TERMINO PROHIBIDO" "printf '$L\tsaas inc\n' >> scripts/terminos-prohibidos.conf"
caso "patrón obsoleto en la capa viva"     "PATRON OBSOLETO"   "printf 'Proveedor Software\tnombre viejo\n' >> scripts/patrones-obsoletos.conf"
caso "sin expedientes declarados"          "SIN LIBROS"        "sed -i '/^ejemplos/d' scripts/libros.conf"
caso "formato de libro sin check"          "SIN CHECK"         "sed -i 's/^ejemplos\/documentos-es es/ejemplos\/documentos-es xx/' scripts/libros.conf"

echo
if [ "$fallos" -eq 0 ]; then echo "✅ El control detectó todas las roturas."; exit 0; fi
echo "❌ $fallos rotura(s) sin detectar."; exit 1
