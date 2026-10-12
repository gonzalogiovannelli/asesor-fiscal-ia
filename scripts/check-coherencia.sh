#!/usr/bin/env bash
# check-coherencia.sh: control mecánico de coherencia del repo.
# Nivel 2 de contexto/arquitectura.md, sección 7.
# Uso:  bash scripts/check-coherencia.sh
# Sale 0 si todo está bien; 1 si hay incidencias.
#
# Respeta el perímetro (arquitectura.md, sección 5): la capa histórica congelada
# (bitacora/, tickets/cerrados/) se excluye de los checks de contenido.
#
# Configuración, en scripts/:
#   libros.conf               un expediente por línea:  <carpeta> <formato>
#   patrones-obsoletos.conf   <regex> TAB <explicación>
#   terminos-prohibidos.conf  <carpeta> TAB <regex>
# Las líneas que empiezan por # se ignoran. Una línea mal escrita NO se salta en
# silencio: se informa como incidencia CONFIG.
#
# Requisitos: bash, find, grep, sed y un awk que entienda UTF-8 (gawk recomendado).

set -uo pipefail
cd "$(dirname "$0")/.." || exit 2
ROOT="$(pwd)"
TMP="$(mktemp)"; CANON="$(mktemp)"; trap 'rm -f "$TMP" "$CANON"' EXIT

inc() { echo "$*" >> "$TMP"; }

conf() { # $1 = archivo de configuración; devuelve sus líneas útiles
  [ -f "scripts/$1" ] || return 0
  tr -d '\r' < "scripts/$1" | grep -vE '^[[:space:]]*(#|$)'
}

regex_valida() { # $1 = regex extendida; 0 si grep la acepta
  grep -qE -- "$1" /dev/null 2>/dev/null; [ $? -ne 2 ]
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
  if [ -d .claude ]; then find .claude -maxdepth 1 -name '*.json'; fi
}

# ---------------------------------------------------------------------------
# Check 1: enlaces markdown internos rotos  [texto](ruta)
# ---------------------------------------------------------------------------
while IFS= read -r f; do
  dir="$(dirname "$f")"
  grep -oE '\]\([^)]+\)' "$f" 2>/dev/null | sed -E 's/^\]\(//; s/\)$//' | while IFS= read -r target; do
    target="${target%% \"*}"        # descarta títulos: ](ruta "título")
    case "$target" in
      http*|\#*|mailto:*|"") continue;;
    esac
    path="${target%%#*}"            # descarta el ancla
    path="${path//%20/ }"
    [ -z "$path" ] && continue
    case "$path" in
      */*|*.*) : ;;                 # parece ruta de archivo
      *) continue;;                 # sin / ni . es un marcador de ejemplo
    esac
    case "$path" in
      /*) full="$ROOT$path";;
      *)  full="$dir/$path";;
    esac
    [ -e "$full" ] || inc "ENLACE ROTO     | $f -> $target"
  done
done < <(live_md)

# ---------------------------------------------------------------------------
# Check 2: patrones obsoletos (rutas o convenciones muertas) en la capa viva
#          y en .claude/*.json
# ---------------------------------------------------------------------------
while IFS= read -r linea; do
  case "$linea" in
    *$'\t'*) : ;;
    *) inc "CONFIG          | patrones-obsoletos.conf: linea sin TAB, no se aplico: $linea"; continue;;
  esac
  regex="${linea%%$'\t'*}"; why="${linea#*$'\t'}"
  if ! regex_valida "$regex"; then inc "CONFIG          | patrones-obsoletos.conf: regex invalida, no se aplico: $regex"; continue; fi
  while IFS= read -r f; do
    grep -nE -- "$regex" "$f" 2>/dev/null | while IFS= read -r hit; do
      inc "PATRON OBSOLETO | $f: $why -> $hit"
    done
  done < <(live_md; live_cfg)
done < <(conf patrones-obsoletos.conf)

# ---------------------------------------------------------------------------
# Check 3: índices de tickets sincronizados con los archivos, en los dos sentidos
#   - cada ticket abierto tiene fila en la tabla de ABIERTOS de tickets/README.md
#     y en la de contexto/INDICE.md; cada cerrado, en la de CERRADOS del README
#   - cada fila de esas tablas tiene su archivo en la carpeta que corresponde
# ---------------------------------------------------------------------------
seccion() { # $1=archivo $2=regex del título; ids T-NNN de esa sección
  [ -f "$1" ] || return 0
  awk -v t="$2" '/^## /{ en = ($0 ~ t) ; next } en' "$1" | grep -oE 'T-[0-9]+' | sort -u
}
archivos() { # $1=carpeta; ids T-NNN de sus archivos
  for f in "$1"/T-*.md; do [ -e "$f" ] && basename "$f" | grep -oE '^T-[0-9]+'; done | sort -u
}
abiertos="$(archivos tickets/abiertos)"; cerrados="$(archivos tickets/cerrados)"
rd_ab="$(seccion tickets/README.md 'abiertos')"; rd_ce="$(seccion tickets/README.md 'cerrados')"
ix_ab="$(seccion contexto/INDICE.md 'Tickets abiertos')"
falta() { # $1=id $2=lista
  ! grep -qx -- "$1" <<< "$2"
}
for id in $abiertos; do
  falta "$id" "$rd_ab" && inc "INDICE TICKET   | $id (abierto) sin fila en la tabla de abiertos de tickets/README.md"
  falta "$id" "$ix_ab" && inc "INDICE TICKET   | $id (abierto) sin fila en Tickets abiertos de contexto/INDICE.md"
done
for id in $cerrados; do
  falta "$id" "$rd_ce" && inc "INDICE TICKET   | $id (cerrado) sin fila en la tabla de cerrados de tickets/README.md"
done
for id in $rd_ab $ix_ab; do
  falta "$id" "$abiertos" && inc "INDICE TICKET   | $id figura como abierto en un indice pero no esta en tickets/abiertos/"
done
for id in $rd_ce; do
  falta "$id" "$cerrados" && inc "INDICE TICKET   | $id figura como cerrado en tickets/README.md pero no esta en tickets/cerrados/"
done

# ---------------------------------------------------------------------------
# Check 4: cuadre aritmético de los libros registro, por formato
#
# Formato "es" (libro registro español; esquema en la skill procesar-facturas).
# Un libro por año:  registro-emitidas-AAAA.md  y  registro-recibidas-AAAA.md
#   por fila:  emitidas   Total = Base + IVA - Retención
#              recibidas  Total = Base + IVA - Retención; si el régimen es de
#                         autoliquidación (ISP o intracomunitaria), Total = Base - Retención
#   totales:   la suma de cada columna coincide con la línea "Totales ..."
# Una fila de libro es cualquier fila de tabla con ID y un trimestre válido en su
# columna, sea cual sea la serie (F-, R- de rectificativas, numeración propia).
#
# Un formato nuevo se añade como otra función recon_<formato> y canon_<formato>,
# con su caso en el bloque de expedientes, y se valida en scripts/probar-check.sh.
# ---------------------------------------------------------------------------
AWK_COMUN='
  # El signo menos tipográfico se normaliza ANTES de quitar el €: en un awk que
  # trabaja por bytes, quitar el € primero rompe el carácter y el número vale 0.
  function num(x){ gsub(/−/,"-",x); gsub(/[ \r*]/,"",x); gsub(/€/,"",x); gsub(/\./,"",x); gsub(/,/,".",x); return x+0 }
  function abs(x){ return x<0?-x:x }
  function trim(x){ gsub(/^[ \t]+|[ \t\r]+$/,"",x); return x }
  function es_trim(c){ return trim(c) ~ /^[0-9][0-9][0-9][0-9]-[1-4]T$/ }
  function es_fila(id, c){ return trim(id) != "" && es_trim(c) }
  function autoliq(reg){ reg=tolower(reg); return index(reg,"isp")>0 || index(reg,"intracom")>0 }
'

recon_es() { # $1=archivo  $2=modo (emitidas|recibidas)
  awk -F'|' -v modo="$2" "$AWK_COMUN"'
    function xn(line,label,  s){ if(match(line,label": [-−]?[0-9.,]+")){ s=substr(line,RSTART,RLENGTH); sub(label": ","",s); return num(s) } return "NA" }
    modo=="emitidas" && es_fila($2,$4) {
      b=num($7); i=num($9); r=num($11); t=num($12);
      sb+=b; si+=i; sr+=r; st+=t;
      e=b+i-r; if(abs(e-t)>0.01) printf "FILA %s: Base %.2f + IVA %.2f - Ret %.2f = %.2f != Total %.2f\n", trim($2), b,i,r,e,t
    }
    modo=="recibidas" && es_fila($2,$4) {
      b=num($8); i=num($10); r=num($19); t=num($20); reg=$12;
      sb+=b; sr+=r; st+=t;
      e = autoliq(reg) ? b-r : b+i-r
      if(abs(e-t)>0.01) printf "FILA %s: esperado %.2f != Total %.2f (regimen: %s)\n", trim($2), e, t, trim(reg)
    }
    # Los rótulos de la línea de totales son contrato con este check. Si se renombran,
    # xn() devuelve NA y el END lo grita en vez de saltárselo en silencio.
    /Totales emitidas/  { vist=1; tb=xn($0,"Base"); tr=xn($0,"Retención"); tt=xn($0,"Cobrado"); tf=xn($0,"Facturado"); ti=xn($0,"IVA repercutido") }
    /Totales recibidas/ { vist=1; tb=xn($0,"Base"); tr=xn($0,"Retención"); tt=xn($0,"Total facturas") }
    END{
      if(!vist){ print "TOTALES: no hay linea de totales, la comprobacion de sumas NO se ejecuto"; exit }
      if(tb=="NA") print "TOTALES: rotulo Base ilegible o ausente, comprobacion saltada"
      if(tr=="NA") print "TOTALES: rotulo Retención ilegible o ausente, comprobacion saltada"
      if(tt=="NA") print "TOTALES: rotulo del total ilegible o ausente, comprobacion saltada"
      if(modo=="emitidas"){
        if(ti=="NA") print "TOTALES: rotulo IVA repercutido ilegible o ausente, comprobacion saltada"
        else if(abs(si-ti)>0.01) printf "TOTALES: suma IVA columna %.2f != linea %.2f\n", si, ti
        if(tf=="NA") print "TOTALES: rotulo Facturado ilegible o ausente, comprobacion saltada"
        else if(abs((sb+si)-tf)>0.01) printf "TOTALES: Base %.2f + IVA %.2f = %.2f != Facturado %.2f\n", sb, si, sb+si, tf
      }
      if(tb!="NA" && abs(sb-tb)>0.01) printf "TOTALES: suma Base columna %.2f != linea %.2f\n", sb, tb
      if(tr!="NA" && abs(sr-tr)>0.01) printf "TOTALES: suma Retencion columna %.2f != linea %.2f\n", sr, tr
      if(tt!="NA" && abs(st-tt)>0.01) printf "TOTALES: suma Total columna %.2f != linea %.2f\n", st, tt
    }
  ' "$1"
}

# Vocabulario de claves del formato "es"  ·  <libro>.<magnitud>.<periodo>
#   periodo   AAAA (año) | AAAA-NT (trimestre) | AAAA-ACNT (acumulado del 1T al NT,
#             para el modelo 130). Todos los trimestres de cada año con libro existen,
#             aunque no tengan facturas: valen 0.
#   emitidas.base | .iva | .ret | .facturado (base+IVA) | .cobrado (base+IVA-ret)
#   recibidas.base | .total
#             | .ivafact     IVA que facturan los proveedores (régimen nacional)
#             | .ivaautodev  IVA autoliquidado devengado (ISP e intracomunitarias)
#             | .ivaded      IVA deducible total, nacional y autoliquidado
#             | .ret | .ret111 | .ret115   retenciones practicadas (total, a profesionales, a alquileres)
#             | .irpfded     gasto corriente deducible, por TRIMESTRE DE LA FECHA de la factura
#                            (no el del IVA), y sin lo que va a amortización
#   liq.303   IVA del periodo = emitidas.iva + recibidas.ivaautodev - recibidas.ivaded
#             (positivo a ingresar, negativo a compensar o devolver)
#   ejemplo.* se ignora: sirve para documentar la sintaxis sin disparar el check.
canon_es() { # $@ = libros del expediente
  awk -F'|' "$AWK_COMUN"'
    function add(m,p,v){ val[m SUBSEP p]+=v }
    function q_fecha(d,  y,mm){ y=substr(trim(d),1,4); mm=substr(trim(d),6,2)+0; if(y !~ /^[0-9][0-9][0-9][0-9]$/ || mm<1 || mm>12) return ""; return y "-" int((mm-1)/3)+1 "T" }
    FILENAME ~ /emitidas/ && es_fila($2,$4) {
      t=trim($4); anios[substr(t,1,4)]=1
      add("emitidas.base",t,num($7)); add("emitidas.iva",t,num($9)); add("emitidas.ret",t,num($11))
      add("emitidas.cobrado",t,num($12)); add("emitidas.facturado",t,num($7)+num($9))
    }
    FILENAME ~ /recibidas/ && es_fila($2,$4) {
      t=trim($4); anios[substr(t,1,4)]=1
      add("recibidas.base",t,num($8)); add("recibidas.total",t,num($20))
      add("recibidas.ivaded",t,num($14))
      if(autoliq($12)) add("recibidas.ivaautodev",t,num($10)); else add("recibidas.ivafact",t,num($10))
      add("recibidas.ret",t,num($19))
      if($18 ~ /111/) add("recibidas.ret111",t,num($19))
      if($18 ~ /115/) add("recibidas.ret115",t,num($19))
      qi=q_fecha($3)
      if(qi=="") printf "ERROR=%s: fecha ilegible, su gasto no se imputo al IRPF\n", trim($2)
      else { anios[substr(qi,1,4)]=1; if($17 ~ /[0-9]/) add("recibidas.irpfded",qi,num($17)) }  # "ver cuadro" = amortización
    }
    END{
      split("emitidas.base emitidas.iva emitidas.ret emitidas.cobrado emitidas.facturado recibidas.base recibidas.total recibidas.ivafact recibidas.ivaautodev recibidas.ivaded recibidas.ret recibidas.ret111 recibidas.ret115 recibidas.irpfded", M, " ")
      for(y in anios){
        for(k=1;k in M;k++){
          m=M[k]; acc=0
          for(n=1;n<=4;n++){ p=y "-" n "T"; v=val[m SUBSEP p]; acc+=v
            printf "%s.%s=%.2f\n", m, p, v; printf "%s.%s-AC%dT=%.2f\n", m, y, n, acc }
          printf "%s.%s=%.2f\n", m, y, acc
        }
        acc=0
        for(n=1;n<=4;n++){ p=y "-" n "T"
          v=val["emitidas.iva" SUBSEP p] + val["recibidas.ivaautodev" SUBSEP p] - val["recibidas.ivaded" SUBSEP p]; acc+=v
          printf "liq.303.%s=%.2f\n", p, v }
        printf "liq.303.%s=%.2f\n", y, acc
      }
    }
  ' "$@"
}


# ---------------------------------------------------------------------------
# Check 6: TRANSPORTE. Los documentos derivados transportan, no recalculan (C8)
#
# Toda cifra transportada declara su origen con una etiqueta pegada al número:
#
#     **525,00 €** <!--@emitidas.iva.2026-3T-->
#
# El check recalcula el valor desde los libros del MISMO expediente, lo compara,
# con su signo, con el último número que precede a la etiqueta y falla si difieren
# más de 0,01. La etiqueta no se ve al leer el markdown y sobrevive a que se
# reescriba la prosa. Una cifra SIN etiqueta no se comprueba.
# ---------------------------------------------------------------------------
transporte() { # $1 = archivo con etiquetas; lee el canon de $CANON
  awk -v arch="$1" "$AWK_COMUN"'
    NR==FNR { if($0 ~ /^ERROR=/) next; split($0,kv,"="); canon[kv[1]]=kv[2]+0; next }
    /<!--@/ {
      linea=$0
      while(match(linea, /<!--@[A-Za-z0-9._-]+-->/)){
        clave=substr(linea, RSTART+5, RLENGTH-8)
        antes=substr(linea, 1, RSTART-1)
        linea=substr(linea, RSTART+RLENGTH)
        if(clave ~ /^ejemplo\./) continue
        cifra=""; resto=antes
        while(match(resto, /(-|−)?[0-9][0-9.]*(,[0-9]+)?/)){
          cifra=substr(resto, RSTART, RLENGTH); resto=substr(resto, RSTART+RLENGTH)
        }
        if(!(clave in canon)){ printf "%s:%d etiqueta @%s no existe en el libro\n", arch, FNR, clave; continue }
        if(cifra==""){ printf "%s:%d etiqueta @%s sin cifra delante\n", arch, FNR, clave; continue }
        if(abs(num(cifra) - canon[clave]) > 0.01)
          printf "%s:%d @%s dice %s pero el libro calcula %.2f\n", arch, FNR, clave, cifra, canon[clave]
      }
    }
  ' "$CANON" "$1"
}

# ---------------------------------------------------------------------------
# Expedientes: checks 4 y 6 por cada línea de libros.conf
# ---------------------------------------------------------------------------
EXPEDIENTES=""
while IFS= read -r linea; do
  read -r -a campos <<< "$linea"
  if [ "${#campos[@]}" -ne 2 ]; then
    inc "CONFIG          | libros.conf: se esperaba <carpeta> <formato> (sin espacios en la carpeta), no se aplico: $linea"; continue
  fi
  EXPEDIENTES="$EXPEDIENTES${campos[0]%/} ${campos[1]}"$'\n'
done < <(conf libros.conf)
[ -z "$EXPEDIENTES" ] && inc "SIN LIBROS      | scripts/libros.conf no declara ningun expediente: checks 4 y 6 NO se ejecutaron"

cubiertas=""
while read -r carpeta formato; do
  [ -z "${carpeta:-}" ] && continue
  if [ ! -d "$carpeta" ]; then inc "SIN LIBROS      | $carpeta declarada en libros.conf pero no existe"; continue; fi
  case "$formato" in
    es)
      libros=()
      for f in "$carpeta"/registro-emitidas-*.md "$carpeta"/registro-recibidas-*.md; do [ -f "$f" ] && libros+=("$f"); done
      if [ "${#libros[@]}" -eq 0 ]; then
        inc "SIN LIBROS      | $carpeta: no hay registro-emitidas-AAAA.md ni registro-recibidas-AAAA.md"; continue
      fi
      for libro in "${libros[@]}"; do
        case "$libro" in *emitidas*) modo=emitidas;; *) modo=recibidas;; esac
        while IFS= read -r line; do inc "CUADRE          | $libro: $line"; done < <(recon_es "$libro" "$modo")
      done
      canon_es "${libros[@]}" > "$CANON"
      while IFS= read -r line; do inc "CUADRE          | $carpeta: ${line#ERROR=}"; done < <(grep '^ERROR=' "$CANON")
      cubiertas="$cubiertas ./$carpeta/"
      while IFS= read -r f; do
        grep -q '<!--@' "$f" 2>/dev/null || continue
        while IFS= read -r line; do inc "TRANSPORTE      | $line"; done < <(transporte "$f")
      done < <(find "$carpeta" -name '*.md')
      ;;
    *)
      inc "SIN CHECK       | $carpeta: formato '$formato' sin funcion de cuadre, checks 4 y 6 NO se ejecutaron"
      ;;
  esac
done <<< "$EXPEDIENTES"

# Una etiqueta fuera de un expediente comprobable no la vigila nadie: se grita.
while IFS= read -r f; do
  grep -oE '<!--@[A-Za-z0-9._-]+-->' "$f" 2>/dev/null | grep -vq '^<!--@ejemplo\.' || continue
  dentro=0
  for c in $cubiertas; do case "$f" in "$c"*) dentro=1;; esac; done
  [ "$dentro" -eq 1 ] || inc "TRANSPORTE      | $f: tiene etiquetas pero no esta en un expediente comprobable, NO se verificaron"
done < <(live_md)

# ---------------------------------------------------------------------------
# Check 5: términos prohibidos por carpeta (criterio C7, compartimentación),
#          en el contenido de los .md y en los nombres de todos los archivos
# ---------------------------------------------------------------------------
while IFS= read -r linea; do
  case "$linea" in
    *$'\t'*) : ;;
    *) inc "CONFIG          | terminos-prohibidos.conf: linea sin TAB, no se aplico: $linea"; continue;;
  esac
  carpeta="${linea%%$'\t'*}"; carpeta="${carpeta%/}"; regex="${linea#*$'\t'}"
  if ! regex_valida "$regex"; then inc "CONFIG          | terminos-prohibidos.conf: regex invalida, no se aplico: $regex"; continue; fi
  if [ ! -d "$carpeta" ]; then inc "CONFIG          | terminos-prohibidos.conf: la carpeta $carpeta no existe, no se aplico"; continue; fi
  while IFS= read -r f; do
    grep -niE -- "$regex" "$f" 2>/dev/null | while IFS= read -r hit; do
      inc "TERMINO PROHIBIDO | $f: $hit"
    done
  done < <(find "$carpeta" -name '*.md')
  while IFS= read -r f; do
    basename "$f" | grep -qiE -- "$regex" && inc "TERMINO PROHIBIDO | nombre de archivo: $f"
  done < <(find "$carpeta" -type f)
done < <(conf terminos-prohibidos.conf)

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
