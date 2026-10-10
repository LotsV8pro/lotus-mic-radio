# 🎙️ lotus-mic-radio

Preset **`Radio Mic`** para **EasyEffects**: cadena de procesado del **micrófono interno** pensada para voz tipo *radio/streaming*, con el **volumen visible al 100 %**, sin siseo y con el retumbe recortado.

Parte del proyecto **[Lotus-Arch](https://github.com/LotsV8pro/Lotus-Arch)** — Arch Linux + Hyprland, tema morado DedSec.

> Hardware de referencia: **Realtek ALC897** (entrada jack `Rear Mic`) en Arch Linux con PipeWire.

---

## 🔗 Cadena de procesado (orden exacto)

| # | Plugin | Ajuste |
|---|--------|--------|
| 1 | **Noise Reduction** (rnnoise) | quita el siseo de fondo |
| 2 | **Filter** | **High‑pass 85 Hz** (recorta subgraves / retumbe) |
| 3 | **Expander** (*downward*) | baja el ruido cuando no hablas |
| 4 | **Deesser** | controla las "eses" |
| 5 | **Equalizer** | **curva de voz** (un único EQ) |
| 6 | **Compressor** | iguala el nivel |
| 7 | **Limiter** | techo a −1 dB, sin clipping |

Detalle: el paso‑alto **no** es un segundo "Equalizer", sino el plugin **Filter** de EasyEffects (usa el *High‑pass* de **LSP**). Así se respeta el orden `high‑pass → expander → deesser → EQ` y **solo hay un "Equalizer"** visible.

## 🎚️ High‑pass (plugin *Filter*)
- Tipo: **High‑pass**
- Frecuencia: **85 Hz**
- Modo: **RLC (BT)** · Pendiente: **x2** · Motor: **IIR**

## 📈 Curva del Equalizer (voz medida)

| Frecuencia | Ganancia | Q | Tipo |
|-----------:|---------:|:--:|:----:|
| 125 Hz | **−4.0 dB** | 1.0 | Bell |
| 350 Hz | −1.5 dB | 1.0 | Bell |
| 550 Hz | −1.0 dB | 1.2 | Bell |
| 950 Hz | **+1.5 dB** | 1.2 | Bell |
| 2000 Hz | **+2.0 dB** | 1.3 | Bell |
| 3500 Hz | +0.5 dB | 1.2 | Bell |
| 6300 Hz | −1.0 dB | 1.2 | Bell |
| 9500 Hz | **+3.5 dB** | 0.7 | Hi‑shelf |

---

## 📦 Requisitos

- **Arch Linux** con **PipeWire** + **pipewire-pulse** + **WirePlumber**
- **EasyEffects ≥ 8.x**
- **lsp-plugins** (el plugin *Filter* de EE usa `filter_stereo` de LSP)
- `alsa-utils` (para `amixer`)

```bash
sudo pacman -S easyeffects lsp-plugins pipewire pipewire-pulse wireplumber alsa-utils
```

## 🚀 Instalación

```bash
git clone https://github.com/LotsV8pro/lotus-mic-radio.git
cd lotus-mic-radio
./install.sh
```

El instalador:
1. Detecta tu micrófono (o usa `MIC_DEVICE=...`).
2. Copia el preset `Radio Mic` y crea el *autoload* (mic → preset).
3. Copia las bases de datos de plugins (`.rc`) con los valores ya afinados.
4. Instala el guard de hardware `mic-radio-hardware` en `~/.local/bin`.
5. Instala y **activa** los servicios de usuario `mic-radio-hardware.service` y `easyeffects.service`.

Si el nombre de tu dispositivo es distinto, fuérzalo:

```bash
MIC_DEVICE=alsa_input.xxxx ./install.sh
```

### Instalación manual

| Archivo del repo | Destino |
|---|---|
| `easyeffects/input/Radio Mic.json` | `~/.local/share/easyeffects/input/` |
| `easyeffects/autoload/input/<device>:.json` | `~/.local/share/easyeffects/autoload/input/` |
| `easyeffects/db/*rc` | `~/.config/easyeffects/db/` |
| `bin/mic-radio-hardware` | `~/.local/bin/` (chmod +x) |
| `systemd/*.service` | `~/.config/systemd/user/` |

```bash
systemctl --user daemon-reload
systemctl --user enable --now mic-radio-hardware.service easyeffects.service
```

---

## 🧠 Notas técnicas (por qué está hecho así)

- **El volumen que ves debe ser 100 %.** El guard fuerza `Input Source = Rear Mic`, `Capture = 100%`, `Rear Mic = 100%` y **`Rear Mic Boost = 0`** cada segundo. WirePlumber repone `Boost = 3` al cambiar de ruta/volumen, por eso el boost se fija **al final** de cada ciclo.
- **EasyEffects no recarga un preset por CLI** cuando el servicio está corriendo (`easyeffects -l ...` no aplica). La forma fiable es escribir los valores en `~/.config/easyeffects/db/*rc` y **reiniciar el servicio**: al arrancar, EE restaura el estado de los plugins desde esos `.rc`.
- Los `*.rc` **no** llevan punto: se llaman `equalizerrc`, `filterrc`, `limiterrc`, etc.

## 🛠️ Problemas frecuentes

| Síntoma | Causa / solución |
|---|---|
| Se oye el micrófono *sin* procesar | `easyeffects_source` no es la fuente por defecto, o el preset no está cargado. Abre EasyEffects y comprueba `Radio Mic`. |
| El EQ se ve plano | Estás mirando el plugin equivocado. En este preset solo hay **un** `Equalizer` (el de la curva); el paso‑alto es el plugin **`Filter`**. |
| Vuelve el siseo / el boost | `mic-radio-hardware.service` no está activo: `systemctl --user status mic-radio-hardware`. |
| El nombre `alsa_input.pci-0000_00_1f.3.analog-stereo` no existe en tu equipo | Es específico del ALC897. Reinstala con `MIC_DEVICE=<tu_fuente>` y adapta `amixer` en `bin/mic-radio-hardware`. |

---

## 📄 Licencia

Uso personal / sin garantías. Siéntete libre de copiar y adaptar.
