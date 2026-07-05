# Display Setup

Reference for the current multi-monitor setup: layout, per-monitor
brightness/contrast, and the Night Light color-temperature settings.

- **Session:** GNOME on X11 (NVIDIA)
- **Layout config:** `~/.config/monitors.xml` (managed by GNOME)
- **Last updated:** 2026-07-05

## Monitors

Three displays, all 1920×1080 @ 60 Hz.

| Monitor            | Connector | Resolution  | Orientation           | Position (x,y) | Role    |
| ------------------ | --------- | ----------- | --------------------- | -------------- | ------- |
| DELL P2725H (27")  | DP-2      | 1080×1920   | Portrait (rotate right) | 398, 0       |         |
| Generic HDMI       | HDMI-1    | 1920×1080   | Landscape             | 1478, 840      |         |
| DELL P2219H (22")  | DP-4      | 1920×1080   | Landscape             | 0, 1920        | Primary |

Serials: P2725H = `CC8GL04`, P2219H = `FV8MC93`.

> Note: the older `bin/restore-monitors.sh` describes a previous cabling
> arrangement (DP-4 as the 27") and no longer matches this layout.

## Brightness & Contrast (DDC/CI via `ddcutil`)

These are **hardware** panel settings (same as the monitor's OSD menu). Tuned
low for evening eye comfort.

| Monitor           | ddcutil display | Brightness | Contrast |
| ----------------- | --------------- | ---------- | -------- |
| DELL P2725H (27") | 2               | 15         | 65       |
| DELL P2219H (22") | 3               | 15         | 65       |
| Generic HDMI      | 1               | 20         | 42       |

Apply:

```bash
ddcutil -d 2 setvcp 10 15 && ddcutil -d 2 setvcp 12 65   # P2725H  (brightness=10, contrast=12)
ddcutil -d 3 setvcp 10 15 && ddcutil -d 3 setvcp 12 65   # P2219H
ddcutil -d 1 setvcp 10 20 && ddcutil -d 1 setvcp 12 42   # generic HDMI
```

Read current values: `ddcutil -d <n> getvcp 10 12`

**Caveats:**

- DDC settings **do not persist** across monitor power-off or reboot — rerun to reapply.
- The generic HDMI panel has flaky DDC; its brightness query occasionally returns
  an I/O error. Set via its physical buttons if `ddcutil` won't take.
- `ddcutil` prints harmless `Failed to find connector name…` warnings under the
  NVIDIA driver; the commands still succeed.

## Night Light (color temperature)

Warm color temperature to cut blue light — the biggest lever for evening eye
comfort. Set **always-on** (not sunset-scheduled). Unlike DDC settings, these
**persist across reboots** (stored in GNOME gsettings).

| Setting              | Value              |
| -------------------- | ------------------ |
| Enabled              | `true`             |
| Schedule             | Always-on (`from` = `to` = 0) |
| Temperature          | 2700 K (warm)      |

Apply:

```bash
sc=org.gnome.settings-daemon.plugins.color
gsettings set $sc night-light-enabled true
gsettings set $sc night-light-schedule-automatic false
gsettings set $sc night-light-schedule-from 0.0
gsettings set $sc night-light-schedule-to 0.0
gsettings set $sc night-light-temperature 2700
```

Tuning:

- Warmer / more relief: lower the temperature (e.g. `2500`).
- Subtler: raise it (e.g. `3500`–`4000`).
- Evening-only instead of always-on: `night-light-schedule-automatic true`
  (sunset→sunrise), or set a fixed `night-light-schedule-from`/`-to` window.
- Live slider: **Settings → Displays → Night Light**.
