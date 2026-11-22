# Installing ElegooSlicer on an Android tablet

This guide sets up the full desktop **ElegooSlicer** on an Android tablet, including Centauri Carbon 2
profiles and **CANVAS** multi-color support. It runs a small Ubuntu Linux inside the **Termux** app
and shows its windows in the **Termux:X11** app.

It's unofficial and it's not a native Android app, so expect a desktop-style interface on a touchscreen and
a slower 3D view than on a computer. Slicing and printing over Wi-Fi work well.

**Time:** about 45–60 minutes, mostly waiting for downloads. You don't need to know Linux: you'll
copy and paste commands.

---

## What you need

- An Android tablet (or phone) with a **64-bit (arm64) processor** — nearly all devices from the last
  several years — running **Android 9 or newer**
- **6 GB of RAM or more** (8 GB recommended)
- **About 6 GB of free storage**
- A Wi-Fi connection on the same network as your printer
- Optional but recommended: a Bluetooth **mouse** (and keyboard). Samsung DeX also works well.

Tested on a Samsung Galaxy Tab S10 FE (8 GB) with an Elegoo Centauri Carbon 2.

### How to paste commands

In Termux, **long-press** the screen and tap **Paste**. Paste **one block at a time**, press **Enter** if
it doesn't run by itself, and **wait until the prompt (`$` or `#`) comes back** before pasting the next
block. Some steps take several minutes. If Termux asks `Do you want to continue? [Y/n]`, type `y` and
press Enter.

---

## Step 1 — Install the apps

Don't use the Play Store version of Termux: it's outdated and doesn't work. Install all of these from
the **same source** (all from F-Droid, or all from GitHub), or they won't work together.

| App | Where to get it |
|---|---|
| **Termux** | [F-Droid](https://f-droid.org/packages/com.termux/) or [GitHub releases](https://github.com/termux/termux-app/releases) — file ending in `arm64-v8a.apk` |
| **Termux:X11** | [GitHub nightly release](https://github.com/termux/termux-x11/releases) — file ending in `arm64-v8a-debug.apk` |
| **Termux:Widget** (optional, for a one-tap icon) | [F-Droid](https://f-droid.org/packages/com.termux.widget/) or [GitHub releases](https://github.com/termux/termux-widget/releases) |

Android will ask you to allow installing apps from your browser. Allow it.

## Step 2 — Stop Android from closing Termux

Android aggressively closes background apps, which shuts down the slicer mid-use. Do all of these:

1. **Battery:** Settings → Apps → **Termux** → Battery → **Unrestricted**. Do the same for **Termux:X11**.
2. **Samsung only:** Settings → Battery → Background usage limits → add Termux and Termux:X11 to
   **Never sleeping apps**.
3. **Developer option (Android 14 and newer):** Settings → About tablet → Software information → tap
   **Build number** 7 times. Then Settings → **Developer options** → turn on
   **Disable child process restrictions**.

   *Android 12 or 13:* this option doesn't exist. If the slicer keeps getting closed, search for
   "Termux phantom process killer" for the fix (it needs a one-time command from a computer).

## Step 3 — Set up Termux

Open **Termux** and paste:

```bash
termux-setup-storage
```

Tap **Allow**. This lets the slicer see your **Downloads** folder.

Then paste this block. It takes a few minutes:

```bash
pkg update -y && pkg upgrade -y
pkg install -y x11-repo
pkg install -y termux-x11-nightly proot-distro wget
proot-distro install ubuntu
```

## Step 4 — Set up Ubuntu and ElegooSlicer

Go into Ubuntu:

```bash
proot-distro login ubuntu --shared-tmp
```

The prompt changes to `root@localhost`. Install the desktop and the libraries ElegooSlicer needs
(this is the longest step, around 10–20 minutes):

```bash
apt update && apt upgrade -y
apt install -y xfce4 xfce4-terminal dbus-x11 wget ca-certificates \
  libgtk-3-0t64 libwebkit2gtk-4.1-0 libgl1 libegl1 libopengl0 libglu1-mesa libwayland-egl1 \
  libgstreamer1.0-0 libgstreamer-plugins-base1.0-0 gstreamer1.0-plugins-good \
  libsecret-1-0 libsm6 libice6 libxkbcommon0 libdbus-1-3 libmspack0t64 fonts-noto-core locales
locale-gen en_US.UTF-8
```

> If it says `Unable to locate package libgtk-3-0t64` or `libmspack0t64`, delete `t64` from the end
> of that name and run the `apt install` block again.

Download ElegooSlicer and unpack it:

```bash
mkdir -p ~/elegoo && cd ~/elegoo
wget -O ElegooSlicer.AppImage https://github.com/bugabooman-lgtm/elegooslicer-arm64/releases/download/v1.5.3.5-arm64/ElegooSlicer-v1.5.3.5-aarch64.AppImage
chmod +x ElegooSlicer.AppImage
./ElegooSlicer.AppImage --appimage-extract > /dev/null
```

Create the launcher, and make ElegooSlicer open automatically when the desktop starts:

```bash
cat > /usr/local/bin/elegoo <<'EOF'
#!/bin/bash
export LANG=en_US.UTF-8
export GDK_SCALE=1
export LIBGL_ALWAYS_SOFTWARE=1
export SSL_CERT_FILE=/etc/ssl/certs/ca-certificates.crt
export WEBKIT_DISABLE_COMPOSITING_MODE=1
export WEBKIT_DISABLE_DMABUF_RENDERER=1
mkdir -p ~/.config
cd ~/elegoo && ./squashfs-root/AppRun "$@"
EOF
chmod +x /usr/local/bin/elegoo

mkdir -p ~/.config/autostart
cat > ~/.config/autostart/elegoo.desktop <<'EOF'
[Desktop Entry]
Type=Application
Name=ElegooSlicer
Exec=/usr/local/bin/elegoo
X-GNOME-Autostart-enabled=true
EOF
exit
```

`exit` takes you back to plain Termux (the prompt changes back to `$`).

## Step 5 — Create the start and stop shortcuts

Still in Termux, paste:

```bash
mkdir -p ~/.shortcuts

cat > ~/.shortcuts/ElegooSlicer <<'EOF'
#!/data/data/com.termux/files/usr/bin/bash
termux-wake-lock
pkill -f termux.x11 2>/dev/null
termux-x11 :0 >/dev/null 2>&1 &
sleep 2
am start -n com.termux.x11/com.termux.x11.MainActivity >/dev/null 2>&1
proot-distro login ubuntu --shared-tmp -- bash -c \
  "export DISPLAY=:0; dbus-launch --exit-with-session startxfce4"
EOF

cat > ~/.shortcuts/Stop-Elegoo <<'EOF'
#!/data/data/com.termux/files/usr/bin/bash
pkill -f xfce4-session
sleep 2
pkill -f termux.x11
termux-wake-unlock
echo "Stopped. You can close Termux."
EOF

chmod +x ~/.shortcuts/*
ln -sf ~/.shortcuts/ElegooSlicer ~/start-elegoo.sh
```

**If you installed Termux:Widget:** long-press your home screen → **Widgets** → **Termux:Widget** →
drag the **1×1 shortcut** to the home screen → pick **ElegooSlicer**. Add a second one and pick
**Stop-Elegoo**.

## Step 6 — Start it

- **With the widget:** tap the **ElegooSlicer** icon.
- **Without it:** open Termux and type `./start-elegoo.sh`

Termux:X11 opens with a desktop, and ElegooSlicer appears after a few seconds. The first launch takes
longer and shows the setup wizard: pick your printer and filaments there.

Your tablet's **Downloads** folder is at `/sdcard/Download` in the slicer's Open dialog.

---

## Connecting your printer (Centauri Carbon 2)

Use the local network connection. It doesn't need an Elegoo account.

1. On the printer's screen, find its **IP address** and **access code** (network settings).
2. In ElegooSlicer: **Device** tab → **Add Printer** → **Add Manually** → enter the IP address and
   access code.
3. The printer appears under **Local Printers**. Status, camera, filament (CANVAS) info, commands and
   sending prints all work.

**Don't use Bind or log in to an Elegoo account on the tablet:**

- An account-bound printer always shows **offline** in this build (see *Limitations* below).
- Elegoo allows only **one signed-in device at a time**, so logging in on the tablet signs out your computer.
- **"Sign in with Google" doesn't work** inside the slicer.

### Avoid "Printer error (409)" when sending prints

With a local connection, the printer refuses a file whose name already exists on it. Give every upload
a unique name:

1. **Prepare** → Process settings → **Others** tab → **Filename format** (turn on *Advanced* if you
   don't see it).
2. Add `_{timestamp}` before `.gcode`. For the Centauri Carbon 2 default, that's:
   ```
   ECC2_{nozzle_diameter[0]}_{input_filename_base}_{filament_name}_{layer_height}_{print_time}_{timestamp}.gcode
   ```
3. Click the **save** icon next to the process preset and save it as your own preset.

Clear old files off the printer's storage now and then. Also, the printer rejects uploads **while
it's printing**, so send files when it's idle.

---

## Shutting down

1. Close **ElegooSlicer** with its **X** button, so it saves your settings.
2. Tap the **Stop-Elegoo** widget, or use Applications menu → **Log Out** on the desktop.
3. Pull down the notification shade and tap **Exit** on the **Termux** notification.

Step 3 matters: until you exit, Termux keeps the tablet awake, which drains the battery.

---

## Tips

- **Touch controls:** open the Termux:X11 notification → **Preferences** → touch mode.
  *Trackpad* works like a laptop touchpad; *Direct touch* taps where your finger is.
  A Bluetooth mouse is easiest.
- **Everything too small or too large:** Termux:X11 Preferences → **Display resolution mode**, for example
  *scaled* at 150–200%.
- **Extra keys:** the bar under the screen (ESC, CTRL, ALT, arrows) comes from Termux:X11 and can be
  hidden in its Preferences.

## Troubleshooting

| Problem | Fix |
|---|---|
| Termux:X11 shows **"Not connected"** after switching apps | Android closed Termux. Recheck all of Step 2, then start again. |
| `Unable to locate package ...t64` | Remove `t64` from that package name and rerun the install command. |
| The desktop opens but ElegooSlicer doesn't | Open the desktop's terminal (Applications → Terminal Emulator), type `elegoo`, and read the last lines it prints. |
| **"Unauthorized access, please check your account login status"** when adding a printer | You used **Bind**. Use **Add Manually** with the IP address and access code instead. |
| **"Printer error (409)"** when sending | A file with that name is already on the printer: see *Avoid "Printer error (409)"* above. |
| Home page or other web panels look blank or black | Known rough edge of the Linux build. Slicing, Device tab and printing are unaffected. |

## Limitations

- **Cloud features don't work.** Part of Elegoo's cloud connection is a closed-source library that only
  exists for PCs, so it's replaced with a stand-in in this build. Local network (LAN) printing works.
- **The 3D view is slower** than on a computer, because it's drawn by the processor, not the graphics chip.
- **Unofficial.** This is Elegoo's own source code, built unchanged for ARM64 apart from a few fixes. It's
  not supported by Elegoo.

---

## Updating to a newer version

When a newer build appears under [Releases](https://github.com/bugabooman-lgtm/elegooslicer-arm64/releases),
open Termux and run (changing the version number in the link):

```bash
proot-distro login ubuntu -- bash -c '
cd ~/elegoo && rm -rf squashfs-root ElegooSlicer.AppImage &&
wget -O ElegooSlicer.AppImage https://github.com/bugabooman-lgtm/elegooslicer-arm64/releases/download/vX.Y.Z.W-arm64/ElegooSlicer-vX.Y.Z.W-aarch64.AppImage &&
chmod +x ElegooSlicer.AppImage && ./ElegooSlicer.AppImage --appimage-extract > /dev/null && echo Updated'
```

Your settings, presets and printers are kept.

## Removing everything

In Termux, run `proot-distro remove ubuntu`, then uninstall the Termux apps from Android settings.
