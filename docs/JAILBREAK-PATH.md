# Verified jailbreak path and hardware compatibility

Last reviewed: 2026-11-03.

## Why the exact model matters

Apple's model identification page maps:
- **A1378** to Apple TV (2nd generation), identifier AppleTV2,1.
- **A1427** to Apple TV (3rd generation), identifier AppleTV3,1.
- **A1469** to Apple TV (3rd generation, Rev A), identifier AppleTV3,2.

Apple TV Software marketing versions must not be confused with the internal iOS build version.

## Published Blackb0x compatibility

The current iOS Guide's Blackb0x instructions state:
- Apple TV 2 on Apple TV Software **5.3**: untethered.
- Apple TV 2 on Apple TV Software **6.2.1**: tethered.
- Apple TV 3 on Apple TV Software **7.2.1–7.9**: untethered.
- Apple TV 3 on Apple TV Software **6.0–6.2**: tethered.

The original Blackb0x README further specifies that Apple TV 3,1 (A1427) must first be put into pwned DFU using an Arduino and synackuk's checkm8-A5 fork. The iOS Guide separates the A1427 instructions from A1378/A1469.

A tethered jailbreak requires the host-assisted boot process again after the Apple TV loses power or reboots. An untethered jailbreak survives reboot, but a failed install can still bootloop the device.

## Host requirements

The current iOS Guide lists an Intel-based Mac running macOS 10.11 or later as the Blackb0x requirement. The Blackb0x source project is an Xcode/macOS application. This repository's Termux setup does not turn that macOS application into an Android executable.

A separate 2026 community fork, regulad/Blackb0x--, is a substantial modernized project. Its current CMake configuration explicitly rejects non-Apple hosts, and its maintainer documents that Linux support was removed because the checkm8 sequence did not work there. This is a direct blocker to treating the fork as a Linux/Termux jailbreak path.

## The reported A1378 / 7.2.1 combination

This is a mismatch in the published compatibility tables:
- A1378 is Apple TV 2.
- Apple TV Software 7.2.1 is in the Apple TV 3 jailbreak route.
- A1378's supported Blackb0x software versions are 5.3 and 6.2.1 in the current guide.

Do not attempt a restore or downgrade to force this combination. Verify the A-number printed on the enclosure and the Apple TV Software version from Settings > General > About. If there is no display, a USB DFU PID is not enough to infer the model or installed firmware.

## What USB DFU tells us

USB ID 05ac:1227 identifies an Apple device in DFU mode. It does not by itself identify A1378 vs A1427/A1469, nor tell us which firmware is installed. The Termux helper now attempts to read the same USB iSerialNumber string that upstream libirecovery parses. When present, CPID + BDID identify these Apple TV board pairs: 8930:10 = AppleTV2,1 (A1378); 8942:08 = AppleTV3,1 (A1427); 8947:00 = AppleTV3,2 (A1469). Some DFU devices expose no readable serial descriptor; in that case the result remains unknown. The helper does not print ECID or the full serial string. USB paths under /dev/bus/usb/ can change after reconnecting.

## Source references

- Apple model identification: https://support.apple.com/en-us/101605
- iOS Guide, installing Blackb0x: https://ios.cfw.guide/installing-blackb0x/
- iOS Guide, Apple TV 3 firmware selection: https://ios.cfw.guide/get-started/Apple-TV-%283rd-generation%29.html
- Original Blackb0x source and README: https://github.com/NSSpiral/Blackb0x
- Modernized community fork: https://github.com/regulad/Blackb0x--

## Scope of this repository

This project currently supports Termux dependency setup, building upstream USB libraries, and Android USB descriptor diagnostics. It does **not** yet implement a complete jailbreak, exploit, ramdisk, tethered boot, or firmware restore. Those steps are deliberately not faked by a shell wrapper.

## Legacy Apple TV 2 alternative: Seas0nPass

For A1378, Seas0nPass is another restore-based jailbreak route. The Apple Wiki records support through Apple TV Software 6.2.1, with 6.2.1 tethered. It is a legacy product (last updated in 2017). Its documented requirements include an x86 computer running Mac OS X 10.6+ or Windows XP+ with .NET Framework 4.0, iTunes, a micro-USB cable, and the aluminum Apple Remote. This is not an Android/Termux workflow.

Reference: https://theapplewiki.com/wiki/Seas0nPass
