# Running ElegooSlicer on the Galaxy Tab S10 FE

This gets the full desktop ElegooSlicer (with CANVAS / Centauri Carbon 2 support) running on the tablet.
It works by running a small Ubuntu Linux inside the Termux app and showing its windows in the Termux:X11 app.

Expect it to be slower than on a laptop, especially the 3D view (it draws on the CPU, not the GPU).
Slicing itself should be OK. A mouse, or Samsung DeX with a mouse and keyboard, makes it much easier to use.

Plan on about 30–60 minutes and a few GB of free storage. You'll copy and paste commands. Paste each
block, press Enter, and wait for it to finish before pasting the next one.

---

## 1. Install the two apps

Don't use the Play Store version of Termux; it's outdated and breaks.

1. **Termux** — from F-Droid (https://f-droid.org/packages/com.termux/) or the GitHub releases page
   (https://github.com/termux/termux-app/releases), file ending in `arm64-v8a.apk`.
2. **Termux:X11** — from https://github.com/termux/termux-x11/releases (the "nightly" release),
   file ending in `arm64-v8a-debug.apk`.

Android will ask to allow installing from your browser. Allow it for these two installs.

**Stop Android from killing Termux:** Settings → About tablet → Software information → tap
**Build number** 7 times to unlock Developer options. Then Settings → Developer options →
turn on **Disable child process restrictions**. Without this, Android may close the slicer
in the middle of a slice.

## 2. Set up Termux (run in the Termux app)

```bash
termux-setup-storage
```
Tap **Allow** when asked. This lets Linux see your Downloads folder, where your STL/3MF files are.

```bash
pkg update -y && pkg upgrade -y
pkg install -y x11-repo
pkg install -y termux-x11-nightly proot-distro wget
proot-distro install ubuntu
```

## 3. Set up Ubuntu (still in Termux)

Go into the Ubuntu system:
```bash
proot-distro login ubuntu --shared-tmp
```
The prompt changes to `root@localhost`. Now install a light desktop and the libraries ElegooSlicer needs:
```bash
apt update && apt upgrade -y
apt install -y xfce4 xfce4-terminal dbus-x11 wget ca-certificates \
  libgtk-3-0t64 libwebkit2gtk-4.1-0 libgl1 libegl1 libopengl0 libglu1-mesa libwayland-egl1 \
  libgstreamer1.0-0 libgstreamer-plugins-base1.0-0 gstreamer1.0-plugins-good \
  libsecret-1-0 libsm6 libice6 libxkbcommon0 libdbus-1-3 libmspack0t64 fonts-noto-core locales
locale-gen en_US.UTF-8
```
(If `libgtk-3-0t64` or `libmspack0t64` isn't found, remove the `t64` from the end of that name and run it again.)

Download ElegooSlicer (the build from this repo) and unpack it:
```bash
mkdir -p ~/elegoo && cd ~/elegoo
wget -O ElegooSlicer.AppImage https://github.com/bugabooman-lgtm/elegooslicer-arm64/releases/download/v1.5.3.5-arm64/ElegooSlicer-v1.5.3.5-aarch64.AppImage
chmod +x ElegooSlicer.AppImage
./ElegooSlicer.AppImage --appimage-extract > /dev/null
```
(Unpacking is needed because AppImages can't mount themselves inside Termux.)

Make a one-word launcher:
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
exit
```
`exit` takes you back out to Termux.

## 4. Make a start script (in Termux)

```bash
cat > ~/start-elegoo.sh <<'EOF'
#!/data/data/com.termux/files/usr/bin/bash
termux-wake-lock
pkill -f termux.x11 2>/dev/null
termux-x11 :0 >/dev/null 2>&1 &
sleep 2
am start -n com.termux.x11/com.termux.x11.MainActivity >/dev/null 2>&1
proot-distro login ubuntu --shared-tmp -- bash -c \
  "export DISPLAY=:0; dbus-launch --exit-with-session startxfce4"
EOF
chmod +x ~/start-elegoo.sh
```

## 5. Every time you want to slice

1. Open **Termux** and type `./start-elegoo.sh`
2. The **Termux:X11** app opens with an Ubuntu desktop.
3. Open the terminal on that desktop (bottom bar, or Applications → Terminal Emulator), type `elegoo`, press Enter.
4. Your tablet's Downloads folder is at `/sdcard/Download` in the file picker.

To quit: close ElegooSlicer, then swipe Termux away or type `exit` in it.

## 6. (Optional) One-tap home screen icon

1. Install **Termux:Widget** from the same place you got Termux (F-Droid, or
   https://github.com/termux/termux-widget/releases if Termux came from GitHub). Mixed sources won't work together.
2. In Termux:
   ```bash
   mkdir -p ~/.shortcuts
   cp ~/start-elegoo.sh ~/.shortcuts/ElegooSlicer
   chmod +x ~/.shortcuts/ElegooSlicer
   ```
3. Make ElegooSlicer open automatically when the desktop starts. Run `proot-distro login ubuntu`, then:
   ```bash
   mkdir -p ~/.config/autostart
   cat > ~/.config/autostart/elegoo.desktop <<'EOF2'
   [Desktop Entry]
   Type=Application
   Name=ElegooSlicer
   Exec=/usr/local/bin/elegoo
   X-GNOME-Autostart-enabled=true
   EOF2
   exit
   ```
4. Long-press the home screen → **Widgets** → **Termux:Widget** → 1×1 shortcut → **ElegooSlicer**.

Now one tap starts everything and ElegooSlicer opens on its own.

## Tips

- **"Not connected" in Termux:X11 after switching apps** means Android killed Termux in the
  background. Fix: set Termux and Termux:X11 to **Unrestricted** battery (Settings → Apps → each app →
  Battery), add both to **Never sleeping apps** (Settings → Battery → Background usage limits), and
  keep **Disable child process restrictions** on. The start script also runs `termux-wake-lock`.
- **Adding the Centauri Carbon 2:** use **Add Manually** in Device → Add Printer, with the printer's IP
  address and access code (it then shows under "Local Printers"). Camera, filament status, commands and
  uploads all work this way, with no Elegoo account needed. Don't use **Bind** / account login on the
  tablet. An account-bound printer always shows offline in this build (its live status uses the cloud piece
  that's replaced on ARM). Elegoo also allows only one signed-in device at a time, so logging in on the
  tablet signs your laptop out. "Sign in with Google" doesn't work in the slicer's built-in browser.
- **Upload fails with "Printer error (409)":** with an access-code connection, the printer won't overwrite
  a file that already has the same name (an account-bound laptop can). Fix: in Process → Others →
  **Filename format**, add `_{timestamp}` before `.gcode`, e.g.
  `ECC2_{nozzle_diameter[0]}_{input_filename_base}_{filament_name}_{layer_height}_{print_time}_{timestamp}.gcode`,
  then save it as your own process preset. Every upload gets a unique name. Clear old files off the
  printer now and then.

- In Termux:X11, open its notification → **Preferences** to change touch mode. "Trackpad" works
  like a laptop touchpad; "Direct touch" taps where your finger is. A Bluetooth mouse is easiest.
- If everything is tiny or huge, change **Display resolution mode** in Termux:X11 Preferences
  (for example "scaled" with a scale of 150–200%).
- **Cloud printing probably won't fully work.** Part of Elegoo's cloud connection uses a closed-source
  library that only exists for PCs, so this build swaps in a stand-in that says "not available".
  Printing to the Centauri Carbon 2 over your local Wi-Fi (LAN) uses separate code and should work
  when the tablet is on the same network.
- If sending prints straight to the Centauri Carbon 2 doesn't work from the tablet, use
  **Export G-code** and send the file with the Elegoo app instead.

## Updating to a newer ElegooSlicer later

Run the build for the new version (Actions tab → Run workflow), then repeat the "Download ElegooSlicer"
block in step 3 with the new version number in the link.
