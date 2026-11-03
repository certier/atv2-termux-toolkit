# ATV2 Termux Toolkit

A Termux-first toolkit for building Apple USB utilities and diagnosing an Apple TV connected to Android over USB-OTG. It also checks published jailbreak compatibility so the wrong firmware route is not selected.

## One-command setup

In Termux, run:

```bash
git clone https://github.com/certier/atv2-termux-toolkit.git && cd atv2-termux-toolkit && bash setup.sh
```

The installer installs the required packages, builds upstream libimobiledevice-glue and libirecovery for ARM64 Termux, builds the Android USB descriptor helper, and installs the atv2 command.

The Termux:API package is installed by pkg, but Android also requires the matching Termux:API add-on app. Install the add-on from the same trusted distribution as Termux and grant USB permission when Android prompts. The setup compiles a small C probe from `src/atv2-usb-probe.c`.

## Commands

| Command | Purpose |
|---|---|
| `atv2 help` | Show help |
| `atv2 doctor` | Check Termux, libraries, tools, and visible USB devices |
| `atv2 probe` | Read the USB descriptor through Android's granted file descriptor |
| `atv2 probe /dev/bus/usb/001/002` | Probe the path shown by the latest termux-usb -l |
| `atv2 route A1378 6.2.1` | Check the published jailbreak route for model and software |
| `atv2 route A1469 7.2.1` | Check the published jailbreak route for model and software |
| `atv2 all` | Run doctor and then the safe USB probe |

Always copy the current device path from termux-usb -l. Android can renumber USB paths after reconnecting.

## Published jailbreak routes

The current iOS Guide's Blackb0x instructions state:

| Apple TV model | Apple TV Software | Published route |
|---|---:|---|
| A1378 (Apple TV 2) | 5.3 | Blackb0x untethered |
| A1378 (Apple TV 2) | 6.2.1 | Blackb0x tethered |
| A1427 (Apple TV 3,1) | 7.2.1–7.9 | Blackb0x untethered, with Arduino/checkm8-A5 DFU preparation |
| A1469 (Apple TV 3,2) | 7.2.1–7.9 | Blackb0x untethered |
| A1427/A1469 (Apple TV 3) | 6.0–6.2 | Blackb0x tethered |

A tethered jailbreak needs a host-assisted boot after a reboot. An untethered jailbreak survives reboot, but a failed install can still bootloop the device.

**Host limitation:** The current iOS Guide lists an Intel-based Mac running macOS 10.11 or later as the Blackb0x requirement. The original Blackb0x project is an Xcode/macOS application. The 2026 community modernization regulad/Blackb0x-- supports Apple Silicon and Intel Macs, but its CMake configuration hard-fails on non-Apple hosts; its maintainer says Linux support was removed because checkm8 did not work there. This repository does not falsely claim that the Mac-only jailbreak chain runs in Termux.

### Your reported A1378 / 7.2.1 combination

This is not a supported match in the published compatibility table. A1378 is Apple TV 2; Apple TV Software 7.2.1 is in the Apple TV 3 jailbreak route. A1378's listed Blackb0x routes are 5.3 and 6.2.1.

Do not restore or downgrade to force the mismatch. Verify the model number printed on the enclosure and the software version in Settings > General > About. A USB ID of 05ac:1227 confirms Apple DFU mode only; it does not identify the Apple TV generation or firmware.

The compatibility checker is:

```bash
atv2 route A1378 7.2.1
```

It will stop on this mismatch rather than suggest a risky flash.

## Android USB behavior

Android does not give Termux unrestricted access to USB devices. Termux:API's `termux-usb -r -e COMMAND DEVICE` requests permission and invokes the helper with an already-authorized file descriptor. The C helper wraps that descriptor using `libusb_wrap_sys_device()` and reads only the USB device descriptor.

Apple VID/PID 05ac:1227 is DFU mode. Recovery-mode IDs include 05ac:1280 through 05ac:1283. These IDs say which USB mode is active, not which Apple TV model or software is installed. In DFU mode the helper also attempts the read-only USB serial descriptor. If it contains Apple's `CPID` and `BDID` fields, the helper matches the known Apple TV board pairs: `8930:10` = AppleTV2,1 (A1378); `8942:08` = AppleTV3,1 (A1427); `8947:00` = AppleTV3,2 (A1469). This metadata is optional and may be unavailable. For privacy, the helper does not print the full serial descriptor or ECID.

The upstream irecovery binary is built as a component, but its normal device-discovery path may not work with Android's per-device descriptor permissions. Building it does not itself add jailbreak capability.

## Safety and scope

- This repository currently builds USB libraries, provides read-only USB diagnostics (including optional DFU CPID/BDID board identification), and checks documented model/software compatibility.
- It does not yet implement the Blackb0x exploit chain, ramdisk, tethered boot, jailbreak installation, or firmware restore from Android.
- No restore, downgrade, DFU upload, iBoot command, or firmware-writing operation is included.
- Do not run arbitrary `irecovery -c`, `irecovery -f`, or restore commands copied from the internet.

## References

- Apple model identification: https://support.apple.com/en-us/101605
- Blackb0x installation and compatibility guide: https://ios.cfw.guide/installing-blackb0x/
- Apple TV 3 firmware selection: https://ios.cfw.guide/get-started/Apple-TV-%283rd-generation%29.html
- Original Blackb0x source: https://github.com/NSSpiral/Blackb0x
- Modernized community fork: https://github.com/regulad/Blackb0x--
- Upstream libirecovery: https://github.com/libimobiledevice/libirecovery
- Termux:API: https://github.com/termux/termux-api
