#!/data/data/com.termux/files/usr/bin/bash
set -u

usage() {
  cat <<'HELP'
ATV2 jailbreak compatibility check

Usage:
  atv2 route MODEL FIRMWARE

Examples:
  atv2 route A1378 6.2.1
  atv2 route A1469 7.2.1
  atv2 route A1378 7.2.1

This command only checks published compatibility. It does not jailbreak,
restore, downgrade, flash, or send commands to the Apple TV.
HELP
}

model="${1:-}"
firmware="${2:-}"

if [[ -z "$model" || -z "$firmware" ]]; then
  usage
  exit 2
fi

model="${model^^}"
echo "Apple TV model: $model"
echo "Reported Apple TV Software: $firmware"
echo

case "$model:$firmware" in
  A1378:5.3)
    echo "MATCH: Apple TV 2 (A1378), Apple TV Software 5.3."
    echo "Published route: Blackb0x untethered jailbreak."
    echo "Host requirement: Intel-based Mac running macOS 10.11 or later."
    ;;
  A1378:6.2.1)
    echo "MATCH: Apple TV 2 (A1378), Apple TV Software 6.2.1."
    echo "Published route: Blackb0x tethered jailbreak."
    echo "Tethered means a computer-assisted boot is required after a reboot."
    echo "Host requirement: Intel-based Mac running macOS 10.11 or later."
    ;;
  A1378:7.2.1)
    echo "STOP: model/firmware mismatch."
    echo "A1378 is Apple TV 2; Apple TV Software 7.2.1 is in the Apple TV 3"
    echo "firmware line. Do not flash or restore based on these two claims."
    echo "Check the model printed on the case and the version in Settings >"
    echo "General > About. USB VID/PID 05ac:1227 only says Apple DFU mode."
    exit 3
    ;;
  A1427:7.2.1)
    echo "MATCH: Apple TV 3,1 (A1427), Apple TV Software 7.2.1."
    echo "Published route: Blackb0x untethered jailbreak."
    echo "Additional prerequisite: pwn DFU using an Arduino and the"
    echo "synackuk checkm8-A5 fork before running Blackb0x."
    echo "Host requirement: Intel-based Mac running macOS 10.11 or later."
    ;;
  A1469:7.2.1)
    echo "MATCH: Apple TV 3,2 (A1469), Apple TV Software 7.2.1."
    echo "Published route: Blackb0x untethered jailbreak."
    echo "Host requirement: Intel-based Mac running macOS 10.11 or later."
    ;;
  A1427:6.0|A1427:6.1|A1427:6.2|A1469:6.0|A1469:6.1|A1469:6.2)
    echo "MATCH: Apple TV 3 with Apple TV Software $firmware."
    echo "Published route: Blackb0x tethered jailbreak."
    echo "Host requirement: Intel-based Mac running macOS 10.11 or later."
    ;;
  A1427:7.0|A1427:7.1|A1427:7.2|A1469:7.0|A1469:7.1|A1469:7.2)
    echo "NO ROUTE: the current iOS Guide compatibility table lists no"
    echo "Blackb0x jailbreak for Apple TV Software 7.0 through 7.2."
    exit 4
    ;;
  *)
    echo "UNVERIFIED COMBINATION."
    echo "Do not restore, downgrade, or flash. Check the exact A-number and"
    echo "Apple TV Software version against docs/JAILBREAK-PATH.md."
    exit 5
    ;;
esac

echo
echo "Important: this Termux toolkit does not execute Blackb0x. The"
echo "documented Blackb0x workflow requires a Mac; A1427 also needs the"
echo "Arduino/checkm8-A5 DFU preparation described above."
