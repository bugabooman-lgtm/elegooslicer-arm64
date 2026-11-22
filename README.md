# ElegooSlicer for Android tablets (ARM64)

Unofficial ARM64 builds of [ElegooSlicer](https://github.com/ELEGOO-3D/ElegooSlicer), Elegoo's slicer,
made to run on an **Android tablet** through Termux. You get the full desktop slicer on the tablet,
including Centauri Carbon 2 profiles and **CANVAS** multi-color support.

## 👉 [Installation guide](INSTALL.md)

Step-by-step, copy-and-paste setup. No Linux knowledge needed. Takes about an hour.

**Download:** [latest build under Releases](https://github.com/bugabooman-lgtm/elegooslicer-arm64/releases)
(the guide downloads it for you).

## What works

- Slicing, preview and all settings, with Elegoo's printer, filament and process profiles
- CANVAS multi-color (Centauri Carbon 2)
- Printer connection over your local Wi-Fi: status, camera, filament info, commands and sending prints

## What doesn't

- Elegoo cloud features and account-bound printers (a closed-source cloud part only exists for PCs)
- The 3D view is slower than on a computer
- It's a desktop interface on a touchscreen: a mouse helps a lot

Tested on a Samsung Galaxy Tab S10 FE (8 GB RAM) with an Elegoo Centauri Carbon 2.

---

## How builds are made

GitHub Actions builds Elegoo's own source code on GitHub's free ARM64 Linux machine, using Elegoo's
`build_linux.sh` plus a few ARM64 fixes (`scripts/arm64-fixes.sh`). Finished builds appear under
**Releases** as `ElegooSlicer-<version>-aarch64.AppImage`.

To build a new version: **Actions → Build ElegooSlicer for ARM64 Linux → Run workflow**, and enter the
ElegooSlicer release tag (for example `v1.5.3.5`). The first build takes a few hours; later builds
reuse cached dependencies and are much faster. **Smoke test** launches a build on a clean Ubuntu
ARM64 system to check that it starts.

## License

ElegooSlicer is licensed under the GNU AGPL-3.0. These builds are made from Elegoo's public source; see
the upstream repository for the source code and license. Not affiliated with or supported by Elegoo.
