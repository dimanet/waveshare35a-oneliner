# waveshare35a-oneliner

One-liner installer for Waveshare 3.5inch RPi LCD (A) on Raspberry Pi OS Trixie/Bookworm-style systems.

## One-liner

```bash
curl -fsSL https://raw.githubusercontent.com/dimanet/waveshare35a-oneliner/main/scripts/setup-waveshare35a.sh | sudo bash && sudo reboot
```

## What it does

- installs the Waveshare `waveshare35a.dtbo` overlay
- patches `/boot/firmware/config.txt`
- adds default touchscreen calibration
- enables tty1 autologin
- starts `htop` on the LCD after boot finishes

## Notes

- tested on Raspberry Pi 5
- touch may still need calibration tweaks
