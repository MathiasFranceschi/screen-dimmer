# screen-dimmer

One brightness control for all my screens — laptop + external monitors — that
stays **eye-matched** as it dims, and rides GNOME **Night Light**'s curve so the
screens dim warm *and* dark together at bedtime.

GNOME natively dims only the laptop panel and only shifts *color* (Night Light),
never the brightness of external monitors. This fills that gap.

## How it works

```
final_brightness[screen] = base[screen]  ×  master%  ×  nightlight%
```

- **base[screen]** — per-screen calibration you set by eye (a panel at 60% can
  look as bright as another at 85%). Lives in `~/.config/screen-bright.conf`.
- **master%** — one slider (`screen-slider`) scaling all screens together.
  Because it's a multiplier, the screens stay matched while you dim.
- **nightlight%** — read live from GNOME's `gsd-color` D-Bus `Temperature`
  property, so brightness follows the *exact* same schedule/ramp as Night Light
  (your fixed hours, or sunset if you switch Night Light to automatic + location).

Brightness is applied with **no root at runtime**:
- laptop panel → `systemd-logind` `SetBrightness` (active session)
- external monitors → **DDC/CI** via `ddcutil` (the active user gets i2c access
  from ddcutil's `uaccess` udev rule)

A `systemd --user` timer (`screen-auto.timer`, every 1 min, change-detected)
keeps brightness tracking the Night Light ramp.

## Install

```sh
./install.sh
```

Then calibrate and try the slider:

```sh
$EDITOR ~/.config/screen-bright.conf   # tune BASE_* until screens look equal
screen-slider                          # master dimmer for all screens
```

## Dependencies

- `ddcutil` — DDC/CI brightness for external monitors (ships the i2c uaccess udev rule)
- `zenity` — the slider dialog (GNOME default; already present on most systems)
- GNOME (uses `gsd-color` + `logind` D-Bus), Wayland or X11

## Adapting to other hardware

This is built for one machine (1 laptop + Lenovo G32qc + ARZOPA). Three spots in
`bin/screen-apply` are hardware-specific — edit them for your setup:

| What | Where | Find it with |
|------|-------|--------------|
| laptop backlight device | `/sys/class/backlight/amdgpu_bl1` | `ls /sys/class/backlight/` |
| external monitor models | the two `ddcutil --model "..."` lines | `ddcutil detect` |
| per-screen base values | `~/.config/screen-bright.conf` | calibrate by eye |

## Commands

| Command | Does |
|---------|------|
| `screen-slider` | master slider (0–100) for all calibrated screens |
| `screen-apply` | recompute & apply base × master × nightlight (used by the timer) |
| `screen-dim <0-100>` | low-level: same absolute % on all screens, ignores calibration |

## Notes / limitations

- `zenity --scale` is one-shot (drag → OK → applies), not live-drag. External
  monitors dim slowly over DDC/CI anyway, so live drag would lag/flicker.
  Swap in `yad --scale --print-partial` if you want continuous drag.
- Laptop displays don't support DDC/CI — that's why the laptop uses logind, the
  externals use ddcutil.
- If externals report `Permission denied` right after install, log out/in once.

## Uninstall

```sh
systemctl --user disable --now screen-auto.timer
rm ~/.local/bin/{screen-apply,screen-slider,screen-dim}
rm ~/.config/systemd/user/screen-auto.{service,timer}
rm ~/.config/screen-bright.conf
systemctl --user daemon-reload
```
