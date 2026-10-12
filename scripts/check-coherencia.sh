#!/usr/bin/env bash
# check-coherencia.sh: control mecánico de coherencia del repo.
# Nivel 2 de contexto/arquitectura.md, sección 7.
# Uso:  bash scripts/check-coherencia.sh
# Sale 0 si todo está bien; 1 si hay incidencias.
#
# Respeta el perímetro (arquitectura.md, sección 5): la capa histórica congelada
# (bitacora/, tickets/cerrados/) se excluye.
#
# Configuración, en scripts/:
#   libros.conf               un expediente por línea:  <carpeta> <formato>
#   patrones-obsoletos.conf   <regex> TAB <explicación>
#   terminos-prohibidos.conf  <carpeta> TAB <regex>
# Las líneas que empiezan por # se ignoran.

set -uo pipefail
cd "$(dirname "$0")/.." || exit 2
ROOT="$(pwd)"
TMP="$(mktemp)"; CANON="$(mktemp)"; trap 'rm -f "$TMP" "$CANON"' EXIT

conf() { # $1 = archivo de configuración; devuelve sus líneas útiles
  [ -f "scripts/$1" ] || return 0
  grep -vE '^[[:space:]]*(#|$)' "scripts/$1" | tr -d '\r'
}

# Capa viva: todos los .md menos la historia congelada, .git y scripts/
live_md() {
  find . -name '*.md' \
    -not -path './.git/*' \
    -not -path './bitacora/*' \
    -not -path './tickets/cerrados/*' \
    -not -path './scripts/*'
}

# Capa viva de configuración: hooks y permisos llevan rutas del repo dentro, y una
# ruta muerta en un hook no da error: deja de hacer su trabajo en silencio.
live_cfg() {
  [ -d .claude ] && find .claude -maxdepth 1 -name '*.json'
}

# ---------------------------------------------------------------------------
# Check 1: enlaces markdown internos rotos  [texto](ruta)
# ---------------------------------------------------------------------------
while IFS= read -r f; do
  dir="$(dirname "$f")"
  grep -oE '\]\([^)]+\)' "$f" 2>/dev/null | sed -E 's/^\]\(//; s/\)$//' | while IFS= read -r target; do
    target="${target%% *}"          # descarta títulos: ](ruta "título")
    case "$target" in
      http*|\#*|mailto:*|"") continue;;
    esac
    path="${target%%#*}"            # descarta el ancla
    [ -z "$path" ] && continue
    case "$path" in
      */*|*.*) : ;;                 # parece ruta de archivo
      *) continue;;                 # sin / ni . es un marcador de ejemplo
    esac
    case "$path" in
      /*) full="$ROOT$path";;
      *)  full="$dir/$path";;
    esac
    [ -e "$full" ] || echo "ENLACE ROTO     | $f -> $target" >> "$TMP"
  done
done < <(live_md)

# ---------------------------------------------------------------------------
# Check 2: patrones obsoletos (rutas o convenciones muertas) en la capa viva
#          y en .claude/*.json
# ---------------------------------------------------------------------------
while IFS=$'\t' read -r regex why; do
  [ -z "$regex" ] && continue
  while IFS= read -r f; do
    grep -nE "$regex" "$f" 2>/dev/null | while IFS= read -r hit; do
      echo "PATRON OBSOLETO | $f: ${why:-$regex} -> $hit" >> "$TMP"
    done
  done < <(live_md; live_cfg)
done < <(conf patrones-obsoletos.conf)

# ---------------------------------------------------------------------------
# Check 3: índices de tickets sincronizados con los archivos reales
# ---------------------------------------------------------------------------
for f in tickets/abiertos/T-*.md; do
  [ -e "$f" ] || continue
  id="$(basename "$f" | grep -oE '^T-[0-9]+')"
  grep -q "$id" tickets/README.md  || echo "INDICE TICKET   | $id sin fila en tickets/README.md" >> "$TMP"
  grep -q "$id" contexto/INDICE.md || echo "INDICE TICKET   | $id sin fila en contexto/INDICE.md" >> "$TMP"
done
for f in tickets/cerrados/T-*.md; do
  [ -e "$f" ] || continue
  id="$(basename "$f" | grep -oE '^T-[0-9]+')"
  grep -q "$id" tickets/README.md  || echo "INDICE TICKET   | $id (cerrado) sin fila en tickets/README.md" >> "$TMP"
done

# ---------------------------------------------------------------------------
# Check 4: cuadre aritmético de los libros registro, por formato
#
# Formato "es" (libro registro español; esquema en la skill procesar-facturas):
#   por fila: Total = Base + IVA - Retención (emitidas) / = Base + IVA (recibidas;
#             en ISP = Base)
#   totales:  la suma de las columnas coincide con la línea "Totales ..."
#
# Un formato nuevo se añade como otra función recon_<formato> y otro bloque
# canon_<formato> en el check 6, y se valida en scripts/probar-check.sh.
# ---------------------------------------------------------------------------
recon_es() { # $1=archivo  $2=modo (emitidas|recibidas)
  awk -F'|' -v modo="$2" '
    function num(x){ gsub(/[ €\r*]/,"",x); gsub(/−/,"-",x); gsub(/\./,"",x); gsub(/,/,".",x); return x+0 }
    function abs(x){ return x<0?-x:x }
    function trim(x){ gsub(/^[ \t]+|[ \t\r]+$/,"",x); return x }
    function xn(line,label,  s){ if(match(line,label": [0-9.,]+")){ s=substr(line,RSTART,RLENGTH); sub(label": ","",s); return num(s) } return "NA" }
    # Una fila de libro, además del prefijo de ID, tiene un trimestre real en su
    # columna. Sin esta guarda, otra tabla cuyas filas empiecen igual (un cuadro de
    # amortizaciones) entraría en las sumas sin avisar.
    function es_fila(campo){ return trim(campo) ~ /^[0-9][0-9][0-9][0-9]-[0-9]T$/ }
    modo=="emitidas" && $2 ~ /^ *F-/ && es_fila($4) {
      b=num($7); i=num($9); r=num($11); t=num($12);
      sb+=b; st+=t; si+=i;
      e=b+i-r; if(abs(e-t)>0.01) printf "FILA %s: Base %.2f + IVA %.2f - Ret %.2f = %.2f != Total %.2f\n", trim($2), b,i,r,e,t
    }
    modo=="recibidas" && $2 ~ /^ *G-/ && es_fila($4) {
      b=num($8); i=num($10); t=num($18); reg=$12;
      sb+=b; st+=t;
      if(index(tolower(reg),"isp")>0) e=b; else e=b+i;
      if(abs(e-t)>0.01) printf "FILA %s: esperado %.2f != Total %.2f (regimen: %s)\n", trim($2), e, t, trim(reg)
    }
    # Los rótulos de la línea de totales son contrato con este check. Si se renombran,
    # xn() devuelve NA y el END lo grita en vez de saltárselo en silencio.
    /Totales emitidas/  { vist=1; tb=xn($0,"Base"); tt=xn($0,"Cobrado"); tf=xn($0,"Facturado"); ti=xn($0,"IVA repercutido") }
    /Totales recibidas/ { vist=1; tb=xn($0,"Base"); tt=xn($0,"Total facturas") }
    END{
      if(!vist){ print "TOTALES: no hay linea de totales, la comprobacion de sumas NO se ejecuto"; exit }
      if(tb=="NA") print "TOTALES: rotulo Base ilegible en la linea de totales, comprobacion saltada"
      if(tt=="NA") print "TOTALES: rotulo del total ilegible en la linea de totales, comprobacion saltada"
      if(modo=="emitidas"){
        if(tf=="NA") print "TOTALES: rotulo Facturado ilegible en la linea de totales, comprobacion saltada"
        else if(ti!="NA" && abs((sb+si)-tf)>0.01) printf "TOTALES: Base %.2f + IVA %.2f = %.2f != Facturado %.2f\n", sb, si, sb+si, tf
      }
      if(tb!="NA" && abs(sb-tb)>0.01) printf "TOTALES: suma Base columna %.2f != linea %.2f\n", sb, tb
      if(tt!="NA" && abs(st-tt)>0.01) printf "TOTALES: suma Total columna %.2f != linea %.2f\n", st, tt
    }
  ' "$1"
}

# Vocabulario de claves del formato "es"  ·  <libro>.<magnitud>.<periodo>
#   periodo   AAAA (año) | AAAA-NT (trimestre)
#   emitidas.base | .iva | .ret | .facturado (base+IVA) | .cobrado (base+IVA-ret)
#   recibidas.base | .total | .ivafact (IVA que factura el proveedor, sin ISP)
#             | .ivaded (IVA deducible, sin ISP) | .ivaisp (ISP, neutro)
#             | .irpfded (gasto corriente deducible; excluye amortizaciones)
#   liq.303   IVA a ingresar del periodo = emitidas.iva - recibidas.ivaded
#   ejemplo.* se ignora: sirve para documentar la sintaxis sin disparar el check.
canon_es() { # $1=carpeta del expediente
  awk -F'|' '
    function num(x){ gsub(/[ €\r*]/,"",x); gsub(/−/,"-",x); gsub(/\./,"",x); gsub(/,/,".",x); return x+0 }
    function trim(x){ gsub(/^[ \t]+|[ \t\r]+$/,"",x); return x }
    function es_fila(campo){ return trim(campo) ~ /^[0-9][0-9][0-9][0-9]-[0-9]T$/ }
    FILENAME ~ /emitidas/ && $2 ~ /^ *F-/ && es_fila($4) {
      t=trim($4); y=substr(t,1,4); k[t]=1; k[y]=1
      eb[t]+=num($7); ei[t]+=num($9); er[t]+=num($11); ec[t]+=num($12)
      eb[y]+=num($7); ei[y]+=num($9); er[y]+=num($11); ec[y]+=num($12)
    }
    FILENAME ~ /recibidas/ && $2 ~ /^ *G-/ && es_fila($4) {
      t=trim($4); y=substr(t,1,4); k[t]=1; k[y]=1
      rb[t]+=num($8); rb[y]+=num($8); rt[t]+=num($18); rt[y]+=num($18)
      if(index(tolower($12),"isp")>0){ ri[t]+=num($14); ri[y]+=num($14) }
      else { rd[t]+=num($14); rd[y]+=num($14); rv[t]+=num($10); rv[y]+=num($10) }
      if($17 ~ /[0-9]/){ rf[t]+=num($17); rf[y]+=num($17) }   # "ver cuadro" = amortización
    }
    END{
      for(p in k){
        printf "emitidas.base.%s=%.2f\n",      p, eb[p]
        printf "emitidas.iva.%s=%.2f\n",       p, ei[p]
        printf "emitidas.ret.%s=%.2f\n",       p, er[p]
        printf "emitidas.cobrado.%s=%.2f\n",   p, ec[p]
        printf "emitidas.facturado.%s=%.2f\n", p, eb[p]+ei[p]
        printf "recibidas.base.%s=%.2f\n",     p, rb[p]
        printf "recibidas.total.%s=%.2f\n",    p, rt[p]
        printf "recibidas.ivafact.%s=%.2f\n",  p, rv[p]
        printf "recibidas.ivaded.%s=%.2f\n",   p, rd[p]
        printf "recibidas.ivaisp.%s=%.2f\n",   p, ri[p]
        printf "recibidas.irpfded.%s=%.2f\n",  p, rf[p]
        printf "liq.303.%s=%.2f\n",            p, ei[p]-rd[p]
      }
    }
  ' "$1/registro-emitidas.md" "$1/registro-recibidas.md"
}

EXPEDIENTES="$(conf libros.conf)"
[ -z "$EXPEDIENTES" ] && echo "SIN LIBROS      | scripts/libros.conf no declara ningun expediente: checks 4 y 6 NO se ejecutaron" >> "$TMP"

while read -r carpeta formato; do
  [ -z "$carpeta" ] && continue
  if [ ! -d "$carpeta" ]; then
    echo "SIN LIBROS      | $carpeta declarada en libros.conf pero no existe" >> "$TMP"; continue
  fi
  case "$formato" in
    es)
      for modo in emitidas recibidas; do
        libro="$carpeta/registro-$modo.md"
        if [ ! -f "$libro" ]; then echo "SIN LIBROS      | falta $libro" >> "$TMP"; continue; fi
        while IFS= read -r line; do echo "CUADRE         | $libro: $line" >> "$TMP"; done < <(recon_es "$libro" "$modo")
      done
      ;;
    *)
      echo "SIN CHECK       | $carpeta: formato '$formato' sin funcion de cuadre, checks 4 y 6 NO se ejecutaron" >> "$TMP"
      ;;
  esac
done <<< "$EXPEDIENTES"

# ---------------------------------------------------------------------------
# Check 5: términos prohibidos por carpeta (criterio C7, compartimentación)
# ---------------------------------------------------------------------------
while IFS=$'\t' read -r carpeta regex; do
  [ -z "$carpeta" ] && continue
  [ -d "$carpeta" ] || continue
  while IFS= read -r f; do
    grep -niE "$regex" "$f" 2>/dev/null | while IFS= read -r hit; do
      echo "TERMINO PROHIBIDO | $f: $hit" >> "$TMP"
    done
  done < <(find "$carpeta" -name '*.md')
done < <(conf terminos-prohibidos.conf)

# ---------------------------------------------------------------------------
# Check 6: TRANSPORTE. Los documentos derivados transportan, no recalculan (C8)
#
# Toda cifra transportada declara su origen con una etiqueta pegada al número:
#
#     **525,00 €** <!--@emitidas.iva.2026-3T-->
#
# El check recalcula el valor desde los libros del MISMO expediente, lo compara con
# el último número que precede a la etiqueta y falla si difieren más de 0,01. La
# etiqueta no se ve al leer el markdown y sobrevive a que se reescriba la prosa.
# Una cifra SIN etiqueta no se comprueba.
# ---------------------------------------------------------------------------
transporte() { # $1 = archivo con etiquetas; lee el canon de $CANON
  awk -v arch="$1" '
    function num(x){ gsub(/[ €\r*]/,"",x); gsub(/−/,"-",x); gsub(/\./,"",x); gsub(/,/,".",x); return x+0 }
    function abs(x){ return x<0?-x:x }
    NR==FNR { split($0,kv,"="); canon[kv[1]]=kv[2]+0; next }
    /<!--@/ {
      linea=$0
      while(match(linea, /<!--@[A-Za-z0-9._-]+-->/)){
        clave=substr(linea, RSTART+5, RLENGTH-8)
        antes=substr(linea, 1, RSTART-1)
        linea=substr(linea, RSTART+RLENGTH)
        if(clave ~ /^ejemplo\./) continue
        cifra=""; resto=antes
        while(match(resto, /[0-9][0-9.]*(,[0-9]+)?/)){
          cifra=substr(resto, RSTART, RLENGTH); resto=substr(resto, RSTART+RLENGTH)
        }
        if(!(clave in canon)){ printf "%s:%d etiqueta @%s no existe en el libro\n", arch, FNR, clave; continue }
        if(cifra==""){ printf "%s:%d etiqueta @%s sin cifra delante\n", arch, FNR, clave; continue }
        if(abs(abs(num(cifra)) - abs(canon[clave])) > 0.01)
          printf "%s:%d @%s dice %s pero el libro calcula %.2f\n", arch, FNR, clave, cifra, canon[clave]
      }
    }
  ' "$CANON" "$1"
}

cubiertas=""
while read -r carpeta formato; do
  [ -z "$carpeta" ] || [ ! -d "$carpeta" ] && continue
  [ "$formato" = "es" ] || continue
  [ -f "$carpeta/registro-emitidas.md" ] && [ -f "$carpeta/registro-recibidas.md" ] || continue
  canon_es "$carpeta" > "$CANON"
  cubiertas="$cubiertas ./$carpeta/"
  while IFS= read -r f; do
    grep -q '<!--@' "$f" 2>/dev/null || continue
    while IFS= read -r line; do echo "TRANSPORTE     | $line" >> "$TMP"; done < <(transporte "$f")
  done < <(find "$carpeta" -name '*.md')
done <<< "$EXPEDIENTES"

# Una etiqueta fuera de un expediente comprobable no la vigila nadie: se grita.
while IFS= read -r f; do
  grep -oE '<!--@[A-Za-z0-9._-]+-->' "$f" 2>/dev/null | grep -vq '^<!--@ejemplo\.' || continue
  dentro=0
  for c in $cubiertas; do case "$f" in "$c"*) dentro=1;; esac; done
  [ "$dentro" -eq 1 ] || echo "TRANSPORTE     | $f: tiene etiquetas pero no esta en un expediente comprobable, NO se verificaron" >> "$TMP"
done < <(live_md)

# ---------------------------------------------------------------------------
# Informe
# ---------------------------------------------------------------------------
N="$(wc -l < "$TMP" | tr -d ' ')"
if [ "$N" -eq 0 ]; then
  echo "✅ Coherencia OK: 0 incidencias."
  exit 0
fi
echo "⚠️  $N incidencia(s) de coherencia:"
echo
sort "$TMP" | sed 's/^/  /'
echo
echo "(Perímetro: bitacora/ y tickets/cerrados/ están excluidos, son historia congelada.)"
exit 1
