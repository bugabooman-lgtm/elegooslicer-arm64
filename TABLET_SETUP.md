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
  libsecret-1-0 libsm6 libice6 libxkbcommon0 libdbus-1-3 fonts-noto-core locales
locale-gen en_US.UTF-8
```
(If `libgtk-3-0t64` isn't found, change it to `libgtk-3-0` and run the line again.)

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

## Tips

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
