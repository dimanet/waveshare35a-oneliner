#!/usr/bin/env bash
set -euo pipefail

if [[ ${EUID:-$(id -u)} -ne 0 ]]; then
  echo "Run as root: sudo bash $0" >&2
  exit 1
fi

USER_NAME="${SUDO_USER:-ansible}"
USER_HOME="$(getent passwd "$USER_NAME" | cut -d: -f6)"
BOOT_CFG="/boot/firmware/config.txt"
OVERLAY_DIR="/boot/firmware/overlays"
WORKDIR="/tmp/waveshare35a-setup"

mkdir -p "$WORKDIR"
apt-get update
DEBIAN_FRONTEND=noninteractive apt-get install -y \
  unzip \
  curl \
  xserver-xorg-video-fbdev \
  xserver-xorg-input-evdev \
  xinput-calibrator \
  htop

curl -L https://files.waveshare.com/wiki/common/Waveshare35a.zip -o "$WORKDIR/Waveshare35a.zip"
python3 - <<'PY'
import zipfile
z = zipfile.ZipFile('/tmp/waveshare35a-setup/Waveshare35a.zip')
z.extract('waveshare35a.dtbo', '/tmp/waveshare35a-setup')
PY
install -m 0644 "$WORKDIR/waveshare35a.dtbo" "$OVERLAY_DIR/waveshare35a.dtbo"

cp -a "$BOOT_CFG" "$BOOT_CFG.bak.$(date +%Y%m%d%H%M%S)"
python3 - <<'PY'
from pathlib import Path
cfg = Path('/boot/firmware/config.txt')
text = cfg.read_text()
lines = text.splitlines()
out = []
for line in lines:
    stripped = line.strip()
    if stripped in {'display_auto_detect=1', 'dtoverlay=vc4-kms-v3d', 'max_framebuffers=2'}:
        if not line.lstrip().startswith('#'):
            out.append('# ' + line)
        else:
            out.append(line)
    else:
        out.append(line)
block = [
    '',
    '# Waveshare 3.5inch RPi LCD (A)',
    'dtparam=spi=on',
    'dtoverlay=waveshare35a',
    'hdmi_force_hotplug=1',
    'hdmi_group=2',
    'hdmi_mode=87',
    'hdmi_cvt 480 320 60 6 0 0 0',
    'hdmi_drive=2',
    'display_rotate=0',
]
joined = '\n'.join(out)
if 'dtoverlay=waveshare35a' not in joined:
    joined += '\n' + '\n'.join(block) + '\n'
cfg.write_text(joined)
PY

mkdir -p /etc/X11/xorg.conf.d
cat >/etc/X11/xorg.conf.d/99-fbdev.conf <<'EOF'
Section "Device"
    Identifier "SPI Display"
    Driver "fbdev"
    Option "fbdev" "/dev/fb0"
    Option "SwapbuffersWait" "true"
EndSection
EOF

cat >/etc/X11/xorg.conf.d/99-calibration.conf <<'EOF'
Section "InputClass"
    Identifier "calibration"
    MatchProduct "ADS7846 Touchscreen"
    Option "Calibration" "3932 300 294 3801"
    Option "SwapAxes" "1"
    Option "EmulateThirdButton" "1"
    Option "EmulateThirdButtonTimeout" "1000"
    Option "EmulateThirdButtonMoveThreshold" "300"
EndSection
EOF

mkdir -p /etc/systemd/system/getty@tty1.service.d
cat >/etc/systemd/system/getty@tty1.service.d/autologin.conf <<EOF
[Service]
ExecStart=
ExecStart=-/sbin/agetty --autologin $USER_NAME --noclear %I \$TERM
EOF

cat >"$USER_HOME/.bash_profile" <<'EOF'
if [ "$(tty)" = "/dev/tty1" ]; then
  while :; do
    state="$(systemctl is-system-running 2>/dev/null || true)"
    case "$state" in
      starting|initializing) sleep 1 ;;
      *) break ;;
    esac
  done
  exec htop
fi
EOF
chown "$USER_NAME:$USER_NAME" "$USER_HOME/.bash_profile"
chmod 0644 "$USER_HOME/.bash_profile"

systemctl disable lightdm >/dev/null 2>&1 || true
systemctl set-default multi-user.target
systemctl daemon-reload

echo "Setup complete. Reboot required. tty1 will autologin and run htop."