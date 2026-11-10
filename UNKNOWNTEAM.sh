#!/data/data/com.termux/files/usr/bin/bash

RES_ANCHO=""
RES_ALTO=""
TARGET_FILE="$HOME/.unknown_team_adb_target"
ADB_TARGET=""
BACKEND_URL="https://unknown-scanner-backend-v1-0.onrender.com"
SESSION_TOKEN=""
KEY_SESSION_EXPIRES=""
ACCESS_KEY_USED=""
AUTH_DEVICE_ID=""
KEY_AUTH_OK=0
RESET=$'\033[0m'; CYAN=$'\033[36m'; MAGENTA=$'\033[35m'; GREEN=$'\033[32m'; YELLOW=$'\033[33m'; RED=$'\033[31m'

pausa(){ printf '\nPresiona ENTER para continuar...'; read -r _; }
comprobar_adb(){
  if ! command -v adb >/dev/null 2>&1; then
    printf '%sNo se encontro ADB.%s\nInstalalo con: pkg install android-tools\n' "$RED" "$RESET"; return 1
  fi
}
validar_puerto(){ [[ "$1" =~ ^[0-9]+$ ]] && [ "$1" -ge 1 ] && [ "$1" -le 65535 ]; }


pedir_key(){
  local raw_key key resp ok err token exp http_code device_id
  asegurar_conexion || return 1
  device_id=$(obtener_android_id) || {
    printf '%sNo pude leer un Android ID válido del teléfono conectado; no autenticaré la key.%s\n' "$RED" "$RESET"
    pausa
    return 1
  }
  while true; do
    clear 2>/dev/null || true
    printf '%s╔══════════════════════════════════════════════════════╗%s\n' "$MAGENTA" "$RESET"
    printf '%s║%s              UNKNOWN SECURITY TEAM                 %s║%s\n' "$MAGENTA" "$RESET" "$MAGENTA" "$RESET"
    printf '%s║%s                — ACCESO PRIVADO —                  %s║%s\n' "$MAGENTA" "$RESET" "$MAGENTA" "$RESET"
    printf '%s╠══════════════════════════════════════════════════════╣%s\n' "$MAGENTA" "$RESET"
    printf '%s║%s          Este programa es de uso privado.           %s║%s\n' "$MAGENTA" "$RESET" "$MAGENTA" "$RESET"
    printf '%s║%s    Key permanente vinculada a este teléfono        %s║%s\n' "$MAGENTA" "$RESET" "$MAGENTA" "$RESET"
    printf '%s╚══════════════════════════════════════════════════════╝%s\n\n' "$MAGENTA" "$RESET"
    printf 'Para obtener acceso: %sdiscord.gg/lavagancia%s\n' "$YELLOW" "$RESET"
    printf 'La key queda ligada al primer teléfono que la active. No la compartas.\n\n'
    printf 'Key de acceso: '
    read -r raw_key
    key=$(printf '%s' "$raw_key" | tr '[:lower:]' '[:upper:]' | tr -d ' \t\r')

    if [ -z "$key" ]; then
      printf '\n%s[!] Ingresa una key valida.%s\n' "$RED" "$RESET"
      sleep 2
      continue
    fi
    if [[ ! "$key" =~ ^[A-Z0-9_-]+$ ]]; then
      printf '\n%s[!] La key contiene caracteres no validos.%s\n' "$RED" "$RESET"
      sleep 2
      continue
    fi
    if ! command -v curl >/dev/null 2>&1; then
      printf '\n%s[!] No se encontro curl. Instala con: pkg install curl%s\n' "$RED" "$RESET"
      pausa
      return 1
    fi

    printf '\n%s[*] Verificando acceso...%s\n' "$CYAN" "$RESET"
    resp=$(curl -sS --max-time 12 -w $'\n%{http_code}' -X POST "${BACKEND_URL}/api/key/usar" \
      -H 'Content-Type: application/json' \
      -d "{\"key\":\"${key}\",\"deviceId\":\"${device_id}\"}" 2>/dev/null)
    http_code=${resp##*$'\n'}
    resp=${resp%$'\n'*}
    if [ -z "$resp" ] || [ "$http_code" = "000" ]; then
      printf '%s[!] Sin conexion al servidor. Verifica tu internet.%s\n' "$RED" "$RESET"
      sleep 3
      continue
    fi

    ok=$(printf '%s' "$resp" | grep -o '"ok":true')
    if [ -n "$ok" ]; then
      token=$(printf '%s' "$resp" | grep -o '"sessionToken":"[^"]*"' | sed 's/"sessionToken":"//;s/"//')
      exp=$(printf '%s' "$resp" | grep -o '"expiresIn":"[^"]*"' | sed 's/"expiresIn":"//;s/"//')
      if [ -z "$token" ]; then
        printf '%s[!] El servidor no devolvió una sesión válida.%s\n' "$RED" "$RESET"
        sleep 3
        return 1
      fi
      SESSION_TOKEN="$token"
      KEY_SESSION_EXPIRES="${exp:-1h}"
      ACCESS_KEY_USED="$key"
      AUTH_DEVICE_ID="$device_id"
      KEY_AUTH_OK=1
      printf '\n%s[✓] ACCESO CONCEDIDO%s\n' "$GREEN" "$RESET"
      printf 'Key permanente vinculada a este teléfono. Sesión API: %s\n\n' "$KEY_SESSION_EXPIRES"
      sleep 2
      return 0
    fi

    err=$(printf '%s' "$resp" | grep -o '"error":"[^"]*"' | sed 's/"error":"//;s/"//')
    case "$err" in
      key_usada) printf '\n%s[!] KEY YA UTILIZADA%s\nCada key permite una sola sesion.\n' "$RED" "$RESET" ;;
      device_mismatch) printf '\n%s[!] KEY VINCULADA A OTRO TELEFONO%s\nEsta key permanente ya quedó asociada a otro Android ID y no se puede trasladar.\n' "$RED" "$RESET" ;;
      device_id_requerido) printf '\n%s[!] No se pudo verificar la identidad del teléfono. Actualiza el script y vuelve a intentar.%s\n' "$RED" "$RESET" ;;
      key_revocada) printf '\n%s[!] KEY REVOCADA%s\nSolicita una key nueva al administrador.\n' "$RED" "$RESET" ;;
      key_expirada) printf '\n%s[!] KEY EXPIRADA%s\n' "$RED" "$RESET" ;;
      key_invalida) printf '\n%s[!] KEY INVALIDA%s\nVerifica que este bien escrita.\n' "$RED" "$RESET" ;;
      account_expired) printf '\n%s[!] CUENTA SUSPENDIDA%s\nContacta a tu operador.\n' "$RED" "$RESET" ;;
      rate_limit) printf '\n%s[!] DEMASIADOS INTENTOS%s\nEspera unos segundos.\n' "$RED" "$RESET" ;;
      *) printf '\n%s[!] ACCESO DENEGADO%s\nKey invalida o error inesperado.\n' "$RED" "$RESET" ;;
    esac
    printf 'Contacto: discord.gg/lavagancia\n'
    sleep 4
    return 1
  done
}

conectar_inalambrico(){
  comprobar_adb || { pausa; return 1; }
  cargar_conexion
  if [ -n "$ADB_TARGET" ]; then
    adb connect "$ADB_TARGET" >/dev/null 2>&1 || true
    if adb -s "$ADB_TARGET" get-state 2>/dev/null | grep -q '^device$'; then
      printf '%s[✓] Ya hay un dispositivo conectado: %s%s\n' "$GREEN" "$ADB_TARGET" "$RESET"
      return 0
    fi
  fi
  clear 2>/dev/null || true
  printf '%s========================================\n       CONECTAR DEPURACION INALAMBRICA\n========================================%s\n\n' "$CYAN" "$RESET"
  printf 'En Android: Opciones de desarrollador > Depuracion inalambrica.\nToca "Vincular dispositivo mediante codigo".\n\n'
  printf 'Codigo de vinculacion (6 digitos): '; read -r pair_code
  if [[ ! "$pair_code" =~ ^[0-9]{6}$ ]]; then
    printf '\n%sEl codigo debe tener exactamente 6 digitos.%s\n' "$RED" "$RESET"; pausa; return 1
  fi
  printf 'Puerto de vinculacion: '; read -r pair_port
  if ! validar_puerto "$pair_port"; then printf '\n%sPuerto invalido.%s\n' "$RED" "$RESET"; pausa; return 1; fi

  printf '\nVinculando mediante localhost...\n'
  pair_result=$(adb pair "localhost:${pair_port}" "$pair_code" 2>&1)
  printf '%s\n' "$pair_result"
  if ! printf '%s' "$pair_result" | grep -qiE 'successfully paired|already paired'; then
    printf '\n%sNo se pudo vincular.%s\nComprueba que el codigo siga vigente y que el puerto sea el de la ventana de vinculacion.\n' "$RED" "$RESET"
    pausa; return 1
  fi
  printf '\n%sVinculacion exitosa.%s\n' "$GREEN" "$RESET"
  printf 'Cierra la ventana del codigo. En la pantalla principal de Depuracion inalambrica\n'
  printf 'busca "Direccion IP y puerto" e introduce SOLO el puerto de conexion.\n\n'
  printf 'Puerto de conexion: '; read -r connect_port
  if ! validar_puerto "$connect_port"; then printf '\n%sPuerto invalido.%s\n' "$RED" "$RESET"; pausa; return 1; fi
  ADB_TARGET="localhost:${connect_port}"
  printf '\nConectando a %s...\n' "$ADB_TARGET"
  connect_result=$(adb connect "$ADB_TARGET" 2>&1); printf '%s\n' "$connect_result"
  if ! printf '%s' "$connect_result" | grep -qiE 'connected to|already connected'; then
    printf '\n%sNo se pudo establecer la conexion.%s\n' "$RED" "$RESET"; ADB_TARGET=""; pausa; return 1
  fi
  if adb -s "$ADB_TARGET" get-state 2>/dev/null | grep -q '^device$'; then
    printf '%s\n' "$ADB_TARGET" > "$TARGET_FILE"
    printf '\n%s[✓] Dispositivo listo.%s\n' "$GREEN" "$RESET"
  else
    printf '%sADB conectó, pero no aparece en estado device.%s\n' "$YELLOW" "$RESET"; ADB_TARGET=""; pausa; return 1
  fi
  pausa
  return 0
}

cargar_conexion(){ [ -z "$ADB_TARGET" ] && [ -f "$TARGET_FILE" ] && ADB_TARGET=$(cat "$TARGET_FILE" 2>/dev/null); }
asegurar_conexion(){
  comprobar_adb || return 1; cargar_conexion
  if [ -z "$ADB_TARGET" ]; then printf '%sPrimero conecta ADB con la opcion 1.%s\n' "$YELLOW" "$RESET"; return 1; fi
  adb connect "$ADB_TARGET" >/dev/null 2>&1 || true
  if ! adb -s "$ADB_TARGET" get-state 2>/dev/null | grep -q '^device$'; then
    printf '%sNo hay conexion activa con %s.%s\nVuelve a conectar desde la opcion 1.\n' "$RED" "$ADB_TARGET" "$RESET"; return 1
  fi
}
obtener_android_id(){
  asegurar_conexion || return 1
  local android_id
  android_id=$(adb -s "$ADB_TARGET" shell settings get secure android_id 2>/dev/null | tr -d '\r[:space:]' | tr '[:upper:]' '[:lower:]')
  [[ "$android_id" =~ ^[0-9a-f]{16}$ ]] || return 1
  printf '%s' "$android_id"
}
verificar_key_en_dispositivo(){
  local current_id check_resp check_code
  [ "$KEY_AUTH_OK" -eq 1 ] || { printf '%sPrimero conecta ADB y activa una key de resolución.%s\n' "$YELLOW" "$RESET"; return 1; }
  current_id=$(obtener_android_id) || { printf '%sNo pude verificar el teléfono conectado.%s\n' "$RED" "$RESET"; return 1; }
  if [ "$current_id" != "$AUTH_DEVICE_ID" ]; then
    KEY_AUTH_OK=0; SESSION_TOKEN=""; AUTH_DEVICE_ID=""
    printf '%sCambió el teléfono conectado. La sesión anterior queda bloqueada; activa una key autorizada para este dispositivo.%s\n' "$RED" "$RESET"
    return 1
  fi
  check_resp=$(curl -sS --max-time 10 -w $'\n%{http_code}' \
    -H "x-session-token: ${SESSION_TOKEN}" -H "x-device-id: ${current_id}" \
    "${BACKEND_URL}/api/key/session/check" 2>/dev/null)
  check_code=${check_resp##*$'\n'}
  check_resp=${check_resp%$'\n'*}
  if [ "$check_code" = "200" ] && printf '%s' "$check_resp" | grep -q '"ok":true'; then
    return 0
  fi
  KEY_AUTH_OK=0; SESSION_TOKEN=""; AUTH_DEVICE_ID=""
  printf '%sLa sesión venció, fue revocada o no pudo verificarse. Vuelve a la opción 1 y autentica la key desde este mismo teléfono.%s\n' "$YELLOW" "$RESET"
  return 1
}
ejecutar_wm(){ adb -s "$ADB_TARGET" shell wm "$@"; }
validar_resolucion_segura(){
  local modelo android wm_out fisica fw fh w h diff denom
  modelo=$(adb -s "$ADB_TARGET" shell getprop ro.product.model 2>/dev/null | tr -d '\r')
  android=$(adb -s "$ADB_TARGET" shell getprop ro.build.version.release 2>/dev/null | tr -d '\r')
  wm_out=$(ejecutar_wm size 2>&1) || { printf '%sNo pude leer el tamaño físico actual; por seguridad no aplicaré cambios.%s\n' "$RED" "$RESET"; return 1; }
  fisica=$(printf '%s\n' "$wm_out" | sed -n 's/^Physical size: *//p' | tr -d '\r' | head -n 1)
  if [[ ! "$fisica" =~ ^[0-9]+x[0-9]+$ ]]; then
    printf '%sNo pude identificar el tamaño físico del teléfono (%s); no aplicaré el cambio.%s\n' "$RED" "$wm_out" "$RESET"; return 1
  fi
  fw=${fisica%%x*}; fh=${fisica#*x}
  if [[ ! "$RES_ANCHO" =~ ^[0-9]{1,5}$ || ! "$RES_ALTO" =~ ^[0-9]{1,5}$ ]]; then
    printf '%sAncho y alto deben ser números enteros positivos (1–5 dígitos).%s\n' "$RED" "$RESET"; return 1
  fi
  w=$((10#$RES_ANCHO)); h=$((10#$RES_ALTO))
  RES_ANCHO=$w; RES_ALTO=$h
  if (( w < 1 || h < 1 || w > 8192 || h > 8192 )); then
    printf '%sResolución inválida o fuera del límite seguro de 1–8192 px por lado.%s\n' "$RED" "$RESET"; return 1
  fi

  diff=$(( w * fh - h * fw )); (( diff < 0 )) && diff=$(( -diff ))
  denom=$(( h * fw )); (( denom < 1 )) && denom=1
  if (( diff * 100 > denom * 5 )); then
    diff=$(( w * fw - h * fh )); (( diff < 0 )) && diff=$(( -diff ))
    denom=$(( h * fh )); (( denom < 1 )) && denom=1
    if (( diff * 100 > denom * 5 )); then
      printf '%sBloqueado: la proporción %sx%s no coincide con la pantalla física %s (tolerancia 5%%).%s\n' "$RED" "$w" "$h" "$fisica" "$RESET"
      return 1
    fi
  fi
  if (( w * h > fw * fh * 4 )); then
    printf '%sBloqueado: %sx%s supera 4 veces el área física (%s).%s\n' "$RED" "$w" "$h" "$fisica" "$RESET"
    return 1
  fi
  printf '%sValidación previa OK: modelo=%s Android=%s, físico=%s, destino=%sx%s.%s\n' "$GREEN" "$modelo" "$android" "$fisica" "$w" "$h" "$RESET"
  return 0
}
mostrar_estado(){ asegurar_conexion || return 1; printf 'Dispositivo ADB: %s\n' "$ADB_TARGET"; ejecutar_wm size; }
aplicar_resolucion(){
  local entrada_ancho entrada_alto
  printf '\nIntroduce la resolución deseada en píxeles.\nAncho: '; read -r entrada_ancho
  printf 'Alto: '; read -r entrada_alto
  if [[ ! "$entrada_ancho" =~ ^[0-9]{1,5}$ || ! "$entrada_alto" =~ ^[0-9]{1,5}$ ]]; then
    printf '%sEntrada inválida: usa solo números enteros de 1 a 5 dígitos.%s\n' "$RED" "$RESET"; pausa; return 1
  fi
  RES_ANCHO=$entrada_ancho; RES_ALTO=$entrada_alto
  printf '\nResolución solicitada: %s x %s\n' "$RES_ANCHO" "$RES_ALTO"
  if ! verificar_key_en_dispositivo || ! validar_resolucion_segura; then pausa; return 1; fi
  printf '%sAviso:%s no te excedas con los valores: una resolución demasiado alta o incompatible puede provocar crasheos, pérdida temporal de imagen o reinicio. Si Android responde mal, el script intentará restaurar el tamaño físico; si el sistema deja de responder, no puede garantizar la recuperación. El script no se autodestruye: borrarlo no repara Android.%s\n' "$YELLOW" "$RESET"
  printf 'Aplicar? [s/N]: '; read -r respuesta
  case "$respuesta" in s|S|si|SI|Si|sI)
    printf '\nAplicando una sola vez...\n'
    if ejecutar_wm size "${RES_ANCHO}x${RES_ALTO}"; then
      local estado
      if estado=$(ejecutar_wm size 2>&1); then
        printf '\n%sEstado reportado por Android:%s\n%s\n' "$GREEN" "$RESET" "$estado"
        printf 'Presiona s y ENTER en 20 segundos para mantenerlo; cualquier otra tecla o tiempo agotado restaura el tamaño físico: '
        local mantener
        if IFS= read -r -t 20 mantener && [[ "$mantener" =~ ^([sS]|si|SI|Si|sI)$ ]]; then
          printf '\nCambio mantenido.\n'
        else
          printf '\nSin confirmacion; restaurando tamaño físico...\n'
          if ejecutar_wm size reset; then printf '%sTamaño físico restaurado.%s\n' "$GREEN" "$RESET"
          else printf '%sNo pude restaurarlo desde ADB. Tras reiniciar, comprueba wm size y ejecuta Restaurar si hiciera falta.%s\n' "$RED" "$RESET"; fi
        fi
      else
        printf '\n%sFalló la verificación. Intentando volver al tamaño físico...%s\n%s\n' "$RED" "$RESET" "$estado"
        if ejecutar_wm size reset; then printf '%sRestauración solicitada.%s\n' "$GREEN" "$RESET"
        else printf '%sADB/Android no responde; no repitas el cambio. Tras arrancar, ejecuta wm size reset.%s\n' "$RED" "$RESET"; fi
      fi
    else
      printf '\n%sAndroid/ADB rechazó el cambio o dejó de responder. Intentando restaurar el tamaño físico una vez...%s\n' "$RED" "$RESET"
      if ejecutar_wm size reset; then printf '%sRestauración solicitada.%s\n' "$GREEN" "$RESET"
      else printf '%sNo se pudo restaurar porque Android/ADB no responde. Tras arrancar, ejecuta wm size reset. No reintentes la resolución.%s\n' "$RED" "$RESET"; fi
    fi;;
    *) printf '\nOperacion cancelada.\n';;
  esac; pausa
}
restaurar_resolucion(){
  printf '\nEsto quitara el override y devolvera el tamano fisico predeterminado.\nContinuar? [s/N]: '; read -r respuesta
  case "$respuesta" in s|S|si|SI|Si|sI)
    if asegurar_conexion; then
      printf '\nRestaurando resolucion...\n'
      if ejecutar_wm size reset; then printf '\n%sEstado despues de restaurar:%s\n' "$GREEN" "$RESET"; ejecutar_wm size
      else printf '\n%sNo se pudo restaurar la resolucion.%s\n' "$RED" "$RESET"; fi
    fi;;
    *) printf '\nOperacion cancelada.\n';;
  esac; pausa
}
while true; do
  clear 2>/dev/null || true
  printf '%s========================================\n              UNKNOWN TEAM\n========================================%s\n\n' "$MAGENTA" "$RESET"
  printf '%s[1]%s Conectar Depuracion inalambrica (metodo del scanner)\n' "$CYAN" "$RESET"
  printf '%s[2]%s Elegir y aplicar resolución\n' "$CYAN" "$RESET"
  printf '%s[3]%s Restaurar resolucion original\n' "$CYAN" "$RESET"
  printf '%s[4]%s Consultar resolucion actual\n' "$CYAN" "$RESET"
  printf '%s[0]%s Salir\n\nSelecciona una opcion: ' "$CYAN" "$RESET"
  read -r opcion
  case "$opcion" in
    1) if conectar_inalambrico; then pedir_key; fi;;
    2) aplicar_resolucion;;
    3) restaurar_resolucion;;
    4) if verificar_key_en_dispositivo; then printf '\n%sResolucion reportada por Android:%s\n' "$GREEN" "$RESET"; mostrar_estado; pausa; fi;;
    0) printf '\nUNKNOWN TEAM - Saliendo.\n'; exit 0;;
    *) printf '\n%sOpcion no valida.%s\n' "$RED" "$RESET"; pausa;;
  esac
done
