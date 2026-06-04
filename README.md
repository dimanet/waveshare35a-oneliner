# waveshare35a-oneliner

One-liner installer for Waveshare 3.5inch RPi LCD (A) on Raspberry Pi OS Trixie/Bookworm-style systems.

## One-liner

```bash
curl -fsSL https://raw.githubusercontent.com/dimanetz/waveshare35a-oneliner/main/scripts/setup-waveshare35a.sh | sudo bash
sudo reboot
```

## What it does

- installs X11/fbdev/lightdm/LXDE bits
- installs `waveshare35a.dtbo`
- patches `/boot/firmware/config.txt`
- sets LightDM autologin
- adds default touchscreen calibration

## Notes

- tested on Raspberry Pi 5 with Debian/Raspberry Pi OS userspace
- after reboot, check touch and rotation
