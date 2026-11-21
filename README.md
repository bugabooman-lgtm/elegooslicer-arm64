# ElegooSlicer ARM64

Unofficial ARM64 (aarch64) Linux builds of [ElegooSlicer](https://github.com/ELEGOO-3D/ElegooSlicer),
made to run on an Android tablet (Galaxy Tab S10 FE) through Termux and a Linux proot,
so the full slicer — including CANVAS multi-color support for the Centauri Carbon 2 — works on the tablet.

**Tablet setup:** see [TABLET_SETUP.md](TABLET_SETUP.md).

## How builds are made

GitHub Actions builds Elegoo's own source code, unchanged, on GitHub's free ARM64 Linux machine
using Elegoo's `build_linux.sh`. Finished builds appear under **Releases** as
`ElegooSlicer-<version>-aarch64.AppImage`.

To build a new version: **Actions → Build ElegooSlicer for ARM64 Linux → Run workflow**, and enter the
ElegooSlicer release tag (for example `v1.5.3.5`).

The first build takes a few hours because it compiles all of ElegooSlicer's dependencies.
Later builds reuse those and are much faster.

## License

ElegooSlicer is licensed under the GNU AGPL-3.0. These builds are made from Elegoo's unmodified
public source; see the upstream repository for the source code and license.
