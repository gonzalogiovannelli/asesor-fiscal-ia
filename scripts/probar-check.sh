#!/usr/bin/env bash
# probar-check.sh: prueba negativa del control de coherencia.
# "Todo check nuevo se valida rompiendo algo a propósito" (arquitectura.md, sección 7).
#
# Copia el repo a una carpeta temporal, rompe una cosa por vez y comprueba que
# check-coherencia.sh falla con la incidencia esperada. El repo real no se toca.
# Usa el ejemplo de ejemplos/documentos-es como caso de prueba: no lo borres.
# Uso:  bash scripts/probar-check.sh

set -uo pipefail
cd "$(dirname "$0")/.." || exit 2
ORIG="$(pwd)"
BASE="$(mktemp -d)"; trap 'rm -rf "$BASE"' EXIT
fallos=0

copia() { rm -rf "$BASE/r"; mkdir -p "$BASE/r"; (cd "$ORIG" && tar --exclude=./.git -cf - .) | (cd "$BASE/r" && tar -xf -); }

# sed -i no es igual en GNU y en BSD (macOS): se edita a un temporal y se reemplaza.
sedi() { # $1=expresión  $2=archivo
  sed -E "$1" "$2" > "$2.tmp" && mv "$2.tmp" "$2"
}

caso() { # $1=nombre  $2=texto esperado en la salida  $3=comando que rompe algo
  copia
  (cd "$BASE/r" && eval "$3")
  salida="$(bash "$BASE/r/scripts/check-coherencia.sh" 2>&1)"; code=$?
  if [ "$code" -ne 0 ] && grep -q -- "$2" <<< "$salida"; then
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
E=$L/registro-emitidas-2026.md
R=$L/registro-recibidas-2026.md
Q=$L/declaraciones/2026/2026-1T/liquidacion.md
FILA_R='| R-0001-2026 | 2026-03-20 | 2026-1T | Cliente Ejemplo SL (B00000000) | Rectifica F-0002-2026 | -100,00 | 21% | -21,00 | 15% | -15,00 | -106,00 | x.pdf |'
FILA_I='| G-2026-099 | 2026-02-10 | 2026-1T | Fabricante UE GmbH (DE000000000) | 7 | Material | 100,00 | 21% | 21,00 |  | Intracom. | 100 | 21,00 | 100 | Corriente | 100,00 |  | 0,00 | 121,00 | y.pdf |'

echo "Roturas (cada una debe hacer saltar el control):"
caso "total de una fila mal sumado"            "CUADRE"            "sedi 's/\| 1\.060,00 \| F-0001/| 1.070,00 | F-0001/' $E"
caso "suma de columna distinta del total"      "suma Base columna" "sedi 's/Base: 1\.650,00/Base: 1.660,00/' $R"
caso "retención mal sumada en recibidas"       "Retencion"         "sedi 's/Retención: 95,00/Retención: 90,00/' $R"
caso "rótulo de totales renombrado"            "ilegible"          "sedi 's/Cobrado:/Neto:/' $E"
caso "rectificativa en otra serie, sin ajustar el total" "suma"     "awk -v f='$FILA_R' '{print} /^\| F-0003-2026/{print f}' $E > t && mv t $E"
caso "rectificativa con signo menos tipográfico" "suma"            "awk -v f='$(printf '%s' "$FILA_R" | sed 's/-100,00/−100,00/; s/-21,00/−21,00/; s/-15,00/−15,00/; s/-106,00/−106,00/')' '{print} /^\| F-0003-2026/{print f}' $E > t && mv t $E"
caso "intracomunitaria con total como si fuera nacional" "CUADRE"  "awk -v f='$FILA_I' '{print} /^\| G-2026-003/{print f}' $R > t && mv t $R"
caso "resumen que no coincide con el libro"    "TRANSPORTE"        "sedi 's/294,00/293,00/' $Q"
caso "signo cambiado en el resumen"            "TRANSPORTE"        "sedi 's/\*\*294,00/**-294,00/' $Q"
caso "etiqueta que no existe en el libro"      "no existe"         "sedi 's/@liq\.303\.2026-1T/@liq.303.2031-1T/' $Q"
caso "etiqueta fuera de un expediente"         "NO se verificaron" "printf 'Total: **5,00 €** <!--@emitidas.iva.2026-->\n' > contexto/suelto.md"
caso "enlace interno roto"                     "ENLACE ROTO"       "printf '[x](no-existe.md)\n' >> README.md"
caso "ticket abierto sin fila en el índice"    "INDICE TICKET"     "printf -- '---\nid: T-001\n---\n' > tickets/abiertos/T-001-prueba.md"
caso "ticket abierto con fila en cerrados"     "INDICE TICKET"     "printf -- '---\nid: T-001\n---\n' > tickets/abiertos/T-001-prueba.md; printf '| T-001 | x | 2026-01-01 | x |\n' >> tickets/README.md; printf '\n| T-001 | x |\n' >> contexto/INDICE.md"
caso "fila de índice sin archivo"              "no esta en"        "awk '{print} /^## Índice de tickets abiertos/{a=1} a && /^\|--/{print \"| T-009 | x | media | abierto | 2026-01-01 |\"; a=0}' tickets/README.md > t && mv t tickets/README.md"
caso "término prohibido en una carpeta"        "TERMINO PROHIBIDO" "printf '$L\tsaas inc\n' >> scripts/terminos-prohibidos.conf"
caso "término prohibido en un nombre de archivo" "nombre de archivo" "touch $L/saas-inc.pdf; printf '$L\tsaas-inc\n' >> scripts/terminos-prohibidos.conf"
caso "patrón obsoleto en la capa viva"         "PATRON OBSOLETO"   "printf 'Proveedor Software\tnombre viejo\n' >> scripts/patrones-obsoletos.conf"
caso "configuración sin TAB"                   "CONFIG"            "printf 'Proveedor Software nombre viejo\n' >> scripts/patrones-obsoletos.conf"
caso "regex inválida en la configuración"      "CONFIG"            "printf 'Proveedor (Software\tx\n' >> scripts/patrones-obsoletos.conf"
caso "carpeta prohibida que no existe"         "CONFIG"            "printf 'documento-es\tx\n' >> scripts/terminos-prohibidos.conf"
caso "sin expedientes declarados"              "SIN LIBROS"        "sedi '/^ejemplos/d' scripts/libros.conf"
caso "formato de libro sin check"              "SIN CHECK"         "sedi 's/^(ejemplos\/documentos-es) es/\1 xx/' scripts/libros.conf"
caso "expediente sin libros"                   "SIN LIBROS"        "mkdir -p documentos-xx; printf 'documentos-xx es\n' >> scripts/libros.conf"

echo "Pre-commit (debe revisar lo preparado, no la carpeta de trabajo):"
copia
(
  cd "$BASE/r" && git init -q && git config user.email t@t && git config user.name t \
    && git config core.hooksPath .githooks && git add -A && git commit -q -m base --no-verify \
    && sedi 's/\| 1\.060,00 \| F-0001/| 1.070,00 | F-0001/' "$E" && git add "$E" \
    && git checkout -q -- . 2>/dev/null; git show :"$E" | grep -q '1.070,00' \
    && cp "$E" "$E.bak" && git show HEAD:"$E" > "$E" \
    && ! git commit -q -m roto > /dev/null 2>&1
) && echo "  ok     un error preparado bloquea aunque la carpeta esté bien" \
  || { echo "  FALLA  el pre-commit dejó pasar un error preparado"; fallos=$((fallos+1)); }

echo
if [ "$fallos" -eq 0 ]; then echo "✅ El control detectó todas las roturas."; exit 0; fi
echo "❌ $fallos rotura(s) sin detectar."; exit 1
