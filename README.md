# ATV2 Termux Toolkit

A Termux-first build and diagnostic toolkit for an Apple TV 2 (A1378) connected to an Android phone over USB-OTG.

**Scope:** build the upstream `libimobiledevice-glue` and `libirecovery` tools for ARM64 Termux, and provide a Termux USB file-descriptor probe. The toolkit is diagnostic only: it does not jailbreak, restore, downgrade, flash, or send commands to the Apple TV.

## One-time setup

Install Termux from a current trusted Termux distribution and open it. The `termux-usb` command also requires the Termux:API package and the matching Termux:API Android add-on app.

Paste this single command:

```bash
git clone https://github.com/certier/atv2-termux-toolkit.git && cd atv2-termux-toolkit && bash setup.sh
```

The installer:
1. Installs the required Termux build packages.
2. Clones the upstream libimobiledevice projects into a temporary build folder.
3. Works around the upstream Autoconf version-expansion issue by replacing the generated version expression with the exact version reported by Git in the local build copy.
4. Builds and installs `libimobiledevice-glue` and `libirecovery` under Termux's `$PREFIX`.
5. Builds `atv2-usb-probe`, a small helper that uses the file descriptor granted by `termux-usb`.
6. Installs the `atv2` command.

When setup finishes, use:

```bash
atv2 doctor
atv2 probe
```

Or run both safe checks together:

```bash
atv2 all
```

## Commands

| Command | Purpose |
|---|---|
| `atv2 help` | Show help |
| `atv2 doctor` | Check Termux, architecture, build tools, libraries, and USB visibility |
| `atv2 probe` | Ask Android for permission and read the connected USB descriptor |
| `atv2 probe /dev/bus/usb/001/002` | Probe a specific path shown by `termux-usb -l` |
| `atv2 all` | Run doctor and then the safe USB probe |

USB device paths can change whenever the device reconnects. Always use a path from the latest `termux-usb -l` output.

## Android USB behavior

On Android, Termux does not automatically receive unrestricted access to `/dev/bus/usb`. The Termux:API `termux-usb -r -e COMMAND DEVICE` flow requests permission and invokes the command with a file descriptor as its argument. The included C helper wraps that already-authorized descriptor with `libusb_wrap_sys_device()` and reads the USB device descriptor.

The helper reports the USB vendor ID, product ID, device revision, and USB class fields. For Apple devices, product ID `0x1227` indicates Apple's DFU USB mode; product IDs `0x1280` through `0x1283` are recovery-mode IDs used by libirecovery. These IDs identify the current USB mode, not the Apple TV model or installed firmware.

The upstream `irecovery` executable is built and installed as a toolchain component. Its normal USB discovery path may not work under Android's permission model because it does not consume the file descriptor supplied by `termux-usb`. The toolkit therefore does not claim that building `irecovery` makes it able to control the Apple TV from Android.

## Important model / firmware note

Apple identifies **A1378 as Apple TV (2nd generation)** and identifies **A1427/A1469 as Apple TV (3rd generation)**: [Apple's model identification guide](https://support.apple.com/en-us/101605).

Third-party firmware catalogs list Apple TV 2 (A1378 / AppleTV2,1) with a maximum software version of **6.2.1**, while software **7.2.1** is associated with Apple TV 3 (AppleTV3,1 / AppleTV3,2). See [EveryMac's model/specification index](https://everymac.com/systems/apple/apple-tv/index-appletv.html) and [The Apple Wiki's 7.x firmware table](https://theapplewiki.com/wiki/Firmware_Keys/7.x).

If a device is labelled A1378 but someone reports software 7.2.1, treat that as an unresolved mismatch. This toolkit deliberately does not infer the firmware version from a USB PID.

## Safety

- No restore, downgrade, exploit, DFU upload, boot command, iBoot command, or firmware-writing command is included in `setup.sh` or `atv2`.
- Do not run random `irecovery -c`, `irecovery -f`, or restore commands copied from the internet.
- A USB DFU identifier is not proof that a jailbreak is installed or that a firmware restore is safe.
- Keep a known-good power supply connected to the Apple TV while diagnosing USB.
- HDMI is not needed for the USB descriptor probe, but without a display the toolkit cannot verify what the Apple TV shows after boot.

## Troubleshooting

**`termux-usb -l` returns `[]`**
- Reconnect the OTG adapter and Micro-USB cable.
- Confirm the Apple TV is powered.
- Check whether Android displays a USB permission/connection notification.
- Run `termux-usb -l` again; do not reuse an old device path.

**`termux-usb` is not found**
- Install the Termux package: `pkg install termux-api`.
- Install/open the matching Termux:API Android add-on from the same distribution source as Termux.
- Reopen Termux and retry.

**The installer reports a missing package**
- Run `pkg update` and `termux-change-repo`, select a current mirror, then rerun `bash setup.sh`.

**A source build fails**
- The installer keeps a log under `$HOME/.cache/atv2-termux-toolkit/`.
- Share the final error and the log path; do not try arbitrary configure flags or edit upstream files by hand.

## Upstream projects

- [libimobiledevice-glue](https://github.com/libimobiledevice/libimobiledevice-glue)
- [libirecovery](https://github.com/libimobiledevice/libirecovery)
- [Termux:API](https://github.com/termux/termux-api)

The upstream projects retain their own licenses. This repository contains original glue scripts and a small USB descriptor helper.
