#!/usr/bin/env bash
# Instalador de 'Radio Mic' — procesado de micrófono para EasyEffects
# Parte del proyecto Lotus-Arch (https://github.com/LotsV8pro/Lotus-Arch)
set -euo pipefail

SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CFG="${XDG_CONFIG_HOME:-$HOME/.config}"
DATA="${XDG_DATA_HOME:-$HOME/.local/share}"
EECFG="$CFG/easyeffects"
EEDATA="$DATA/easyeffects"
UNITDIR="$CFG/systemd/user"
BINDIR="$HOME/.local/bin"

say()  { printf '\033[1;35m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m[!]\033[0m %s\n' "$*"; }

# --- 0. Dependencias ---
missing=0
for c in easyeffects pactl pw-cli amixer; do
    if ! command -v "$c" >/dev/null 2>&1; then
        warn "Falta el comando '$c'."
        missing=1
    fi
done
if [ "$missing" = 1 ]; then
    echo "Instala: sudo pacman -S easyeffects lsp-plugins pipewire pipewire-pulse wireplumber alsa-utils"
    exit 1
fi

# --- 1. Detectar el micrófono ---
detect_source() {
    pactl list short sources 2>/dev/null | awk '{print $2}' \
        | grep -vE '\.monitor$|^easyeffects' | head -n1
}
DEV="${MIC_DEVICE:-$(detect_source)}"
if [ -z "$DEV" ]; then
    echo "No he podido detectar el micrófono. Pásalo a mano:  MIC_DEVICE=alsa_input.xxx ./install.sh"
    exit 1
fi
say "Micrófono: $DEV"

# --- 2. Preset + autoload de EasyEffects ---
mkdir -p "$EEDATA/input" "$EEDATA/autoload/input"
[ -f "$EEDATA/input/Radio Mic.json" ] && cp "$EEDATA/input/Radio Mic.json" "$EEDATA/input/Radio Mic.json.bak"
cp "$SRC/easyeffects/input/Radio Mic.json" "$EEDATA/input/Radio Mic.json"

cat > "$EEDATA/autoload/input/${DEV}:.json" <<EOF
{
    "device": "$DEV",
    "device-description": "",
    "device-profile": "",
    "preset-name": "Radio Mic"
}
EOF
say "Preset y autoload instalados."

# --- 3. Bases de datos de plugins (valores ya afinados) ---
mkdir -p "$EECFG/db"
for f in easyeffectsrc equalizerrc filterrc expanderrc deesserrc compressorrc limiterrc rnnoiserc; do
    [ -f "$EECFG/db/$f" ] && cp "$EECFG/db/$f" "$EECFG/db/$f.bak"
    cp "$SRC/easyeffects/db/$f" "$EECFG/db/$f"
done
say "Plugins (.rc) copiados a $EECFG/db"

# --- 4. Guard de hardware ---
mkdir -p "$BINDIR"
sed "s|^HW=.*|HW=$DEV|" "$SRC/bin/mic-radio-hardware" > "$BINDIR/mic-radio-hardware"
chmod +x "$BINDIR/mic-radio-hardware"
say "Guard instalado en $BINDIR/mic-radio-hardware"

# --- 5. Servicios de usuario ---
mkdir -p "$UNITDIR"
cp "$SRC/systemd/mic-radio-hardware.service" "$UNITDIR/"
cp "$SRC/systemd/easyeffects.service"        "$UNITDIR/"
systemctl --user daemon-reload
systemctl --user enable --now mic-radio-hardware.service
systemctl --user enable --now easyeffects.service
say "Servicios activados."

cat <<'EOF'

✔ Instalación completada.

  1) Abre EasyEffects: verás el preset "Radio Mic" con UN Equalizer (la curva)
     y un plugin Filter (el paso-alto).
  2) Habla: el volumen del micrófono que se muestra debe ser 100%.
  3) Si el nombre del micrófono cambia, vuelve a ejecutar ./install.sh

Nota: bin/mic-radio-hardware usa los controles ALSA del códec Realtek ALC897
      ('Input Source'/'Capture'/'Rear Mic'/'Rear Mic Boost'). En otro hardware
      hay que adaptar esos nombres de control.
EOF
