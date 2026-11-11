# lotus-mic-radio

Preset `Radio Mic` para EasyEffects: procesa el micrófono interno del portátil
para que la voz suene a radio o a directo, con el volumen visible al 100 %, sin
siseo y sin retumbe.

Está pensado para el Realtek ALC897 (entrada `Rear Mic`) en Arch Linux con
PipeWire, aunque funciona en cualquier equipo si ajustas el nombre del
dispositivo.

También forma parte de [Lotus-Arch](https://github.com/LotsV8pro/Lotus-Arch).

## Cadena

| Orden | Plugin | Ajuste |
|---|---|---|
| 1 | Noise Reduction (rnnoise) | quita el siseo de fondo |
| 2 | Filter | paso alto a 85 Hz, recorta subgraves y retumbe |
| 3 | Expander (downward) | baja el nivel cuando no hablas |
| 4 | Deesser | controla las eses |
| 5 | Equalizer | curva de voz |
| 6 | Compressor | iguala el nivel |
| 7 | Limiter | techo a −1 dB, sin clipping |

El paso alto es el plugin Filter de EasyEffects, no un segundo Equalizer. Así el
orden es alto → expander → deesser → EQ y en el preset solo aparece un
Equalizer.

### Paso alto

| Ajuste | Valor |
|---|---|
| Tipo | High-pass |
| Frecuencia | 85 Hz |
| Modo | RLC (BT) |
| Pendiente | x2 |
| Motor | IIR |

### Curva del Equalizer

| Frecuencia | Ganancia | Q | Tipo |
|---:|---:|:--:|:--:|
| 125 Hz | −4.0 dB | 1.0 | Bell |
| 350 Hz | −1.5 dB | 1.0 | Bell |
| 550 Hz | −1.0 dB | 1.2 | Bell |
| 950 Hz | +1.5 dB | 1.2 | Bell |
| 2000 Hz | +2.0 dB | 1.3 | Bell |
| 3500 Hz | +0.5 dB | 1.2 | Bell |
| 6300 Hz | −1.0 dB | 1.2 | Bell |
| 9500 Hz | +3.5 dB | 0.7 | Hi-shelf |

## Requisitos

- Arch Linux con PipeWire, pipewire-pulse y WirePlumber
- EasyEffects 8 o superior
- lsp-plugins: el plugin Filter de EasyEffects usa el filtro de LSP
- alsa-utils, para `amixer`

```bash
sudo pacman -S easyeffects lsp-plugins pipewire pipewire-pulse wireplumber alsa-utils
```

## Instalación

```bash
git clone https://github.com/LotsV8pro/lotus-mic-radio.git
cd lotus-mic-radio
./install.sh
```

El instalador detecta el micrófono, copia el preset y los valores de los
plugins, crea el autoload del dispositivo, instala el guard
`mic-radio-hardware` y activa los servicios de usuario `mic-radio-hardware` y
`easyeffects`.

Si la detección falla o el nombre no es el tuyo:

```bash
MIC_DEVICE=alsa_input.tu_dispositivo ./install.sh
```

### Instalación a mano

| Archivo del repo | Destino |
|---|---|
| `easyeffects/input/Radio Mic.json` | `~/.local/share/easyeffects/input/` |
| `easyeffects/autoload/input/` | `~/.local/share/easyeffects/autoload/input/` |
| `easyeffects/db/*rc` | `~/.config/easyeffects/db/` |
| `bin/mic-radio-hardware` | `~/.local/bin/` (con permiso de ejecución) |
| `systemd/*.service` | `~/.config/systemd/user/` |

```bash
systemctl --user daemon-reload
systemctl --user enable --now mic-radio-hardware.service easyeffects.service
```

## Notas

El volumen que ves tiene que ser 100 %. El guard fija `Input Source = Rear Mic`,
`Capture = 100%`, `Rear Mic = 100%` y `Rear Mic Boost = 0` cada segundo, y deja
el boost para el final del ciclo porque WirePlumber lo vuelve a poner en 3 al
cambiar de ruta o de volumen.

EasyEffects no recarga un preset por línea de órdenes mientras el servicio está
en marcha: `easyeffects -l` no aplica nada. La forma que funciona es escribir los
valores en `~/.config/easyeffects/db/*.rc` y reiniciar el servicio, que al
arrancar restaura los plugins desde esos ficheros.

Los ficheros `.rc` no llevan punto: se llaman `equalizerrc`, `filterrc`,
`limiterrc`.

## Problemas

| Síntoma | Qué mirar |
|---|---|
| Se oye el micrófono sin procesar | `easyeffects_source` no es la fuente por defecto, o el preset no está cargado |
| El EQ se ve plano | estás mirando el plugin equivocado: el paso alto está en Filter |
| Vuelve el siseo o el boost | `systemctl --user status mic-radio-hardware` |
| El dispositivo `alsa_input.pci-0000_00_1f.3.analog-stereo` no existe | es el del ALC897; reinstala con `MIC_DEVICE` y adapta `amixer` en `bin/mic-radio-hardware` |

## Licencia

Uso personal, sin garantía. Cópialo y adáptalo.
