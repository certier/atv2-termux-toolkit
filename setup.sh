#!/data/data/com.termux/files/usr/bin/bash
set -Eeuo pipefail

REPO_URL="https://github.com/certier/atv2-termux-toolkit.git"
WORK="$HOME/.cache/atv2-termux-toolkit"
LOGDIR="$WORK/logs"
mkdir -p "$WORK" "$LOGDIR"
LOG="$LOGDIR/setup-$(date +%Y%m%d-%H%M%S).log"
exec > >(tee -a "$LOG") 2>&1

trap 'code=$?; echo; echo "[ERROR] Setup failed at line $LINENO (exit $code). Log: $LOG"; exit "$code"' ERR

say() { printf '\n\033[1;36m==> %s\033[0m\n' "$*"; }
need_cmd() { command -v "$1" >/dev/null 2>&1 || { echo "Missing command: $1"; return 1; }; }

echo "ATV2 Termux Toolkit — safe build and USB diagnostics"
echo "Log: $LOG"
if [[ "$(uname -m)" != "aarch64" && "$(uname -m)" != "arm64" ]]; then
  echo "Warning: this setup is intended for 64-bit ARM Android (aarch64). Detected: $(uname -m)"
fi

say "Updating Termux package lists"
pkg update -y

say "Installing build and USB packages"
pkg install -y git clang make autoconf automake libtool pkg-config libusb readline libplist which termux-api

need_cmd git
need_cmd clang
need_cmd pkg-config
need_cmd termux-usb

export PKG_CONFIG_PATH="$PREFIX/lib/pkgconfig:$PREFIX/share/pkgconfig${PKG_CONFIG_PATH:+:$PKG_CONFIG_PATH}"
export CFLAGS="${CFLAGS:-} -O2"

build_project() {
  local name="$1"
  local url="$2"
  local dir="$WORK/$name"

  say "Fetching $name"
  if [[ -d "$dir/.git" ]]; then
    git -C "$dir" fetch --tags origin
    git -C "$dir" reset --hard origin/master
  else
    rm -rf "$dir"
    git clone --depth 1 --branch master "$url" "$dir"
    git -C "$dir" fetch --tags --depth=1 origin
  fi

  local version
  version="$(git -C "$dir" describe --tags --always 2>/dev/null || git -C "$dir" rev-parse --short HEAD)"
  if [[ -z "$version" ]]; then
    version="$(git -C "$dir" rev-parse --short HEAD)"
  fi

  say "Preparing $name (version $version)"
  # Upstream uses m4_esyscmd(./git-version-gen ...) inside AC_INIT. Some
  # Termux Autoconf/m4 combinations expand this to an empty PACKAGE_VERSION.
  # Pin the local build copy to the version obtained from its actual Git checkout.
  sed "s|m4_esyscmd(./git-version-gen \$RELEASE_VERSION)|$version|g" "$dir/configure.ac" > "$dir/configure.ac.tmp"
  mv "$dir/configure.ac.tmp" "$dir/configure.ac"

  ( cd "$dir"
    ./autogen.sh --prefix="$PREFIX" --disable-static
    make -j2
    make install
  )
}

say "Building libimobiledevice-glue"
build_project "libimobiledevice-glue" "https://github.com/libimobiledevice/libimobiledevice-glue.git"

say "Building libirecovery"
build_project "libirecovery" "https://github.com/libimobiledevice/libirecovery.git"

say "Building Android USB descriptor helper"
cat > "$WORK/atv2-usb-probe.c" <<'C_EOF'
#include <errno.h>
#include <inttypes.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <libusb-1.0/libusb.h>

int main(int argc, char **argv) {
    if (argc != 2) {
        fprintf(stderr, "Usage: atv2-usb-probe FILE_DESCRIPTOR\n");
        return 2;
    }

    char *end = NULL;
    errno = 0;
    long rawfd = strtol(argv[1], &end, 10);
    if (errno || !end || *end || rawfd < 0) {
        fprintf(stderr, "Invalid USB file descriptor: %s\n", argv[1]);
        return 2;
    }

    libusb_context *ctx = NULL;
    libusb_device_handle *handle = NULL;
    int rc = libusb_init(&ctx);
    if (rc != 0) {
        fprintf(stderr, "libusb_init: %s\n", libusb_error_name(rc));
        return 3;
    }

    rc = libusb_wrap_sys_device(ctx, (intptr_t)rawfd, &handle);
    if (rc != 0) {
        fprintf(stderr, "Could not use Android-granted USB descriptor: %s\n",
                libusb_error_name(rc));
        libusb_exit(ctx);
        return 4;
    }

    struct libusb_device_descriptor d;
    rc = libusb_get_device_descriptor(libusb_get_device(handle), &d);
    if (rc != 0) {
        fprintf(stderr, "Could not read USB descriptor: %s\n", libusb_error_name(rc));
        libusb_close(handle);
        libusb_exit(ctx);
        return 5;
    }

    printf("Vendor ID:       %04x\n", d.idVendor);
    printf("Product ID:      %04x\n", d.idProduct);
    printf("USB revision:    %04x\n", d.bcdUSB);
    printf("Device revision: %04x\n", d.bcdDevice);
    printf("Device class:    %02x\n", d.bDeviceClass);
    printf("Configurations:  %u\n", d.bNumConfigurations);

    if (d.idVendor == 0x05ac && d.idProduct == 0x1227) {
        puts("Apple USB mode:  DFU (USB PID 1227)");
        puts("Note: DFU mode does not identify the exact Apple product or firmware.");
    } else if (d.idVendor == 0x05ac &&
               d.idProduct >= 0x1280 && d.idProduct <= 0x1283) {
        puts("Apple USB mode:  Recovery (USB PID 1280-1283)");
    } else if (d.idVendor == 0x05ac) {
        puts("Apple USB mode:  Apple device; mode not classified by this probe.");
    } else {
        puts("Apple USB mode:  Not identified as an Apple VID (05ac) device.");
    }

    libusb_close(handle);
    libusb_exit(ctx);
    return 0;
}
C_EOF

clang "$WORK/atv2-usb-probe.c" -O2 -Wall -Wextra -o "$PREFIX/bin/atv2-usb-probe" -lusb-1.0

say "Installing atv2 command"
cat > "$PREFIX/bin/atv2" <<'SH_EOF'
#!/data/data/com.termux/files/usr/bin/bash
set -u
PREFIX="${PREFIX:-/data/data/com.termux/files/usr}"
probe="$PREFIX/bin/atv2-usb-probe"

usage() {
  cat <<'HELP'
ATV2 Termux Toolkit — safe diagnostics only

Usage:
  atv2 help
  atv2 doctor
  atv2 probe [USB_DEVICE_PATH]
  atv2 all

Examples:
  termux-usb -l
  atv2 probe
  atv2 probe /dev/bus/usb/001/002

This tool reads USB descriptors only. It does not jailbreak, restore,
downgrade, flash firmware, upload payloads, or send iBoot commands.
HELP
}

doctor() {
  echo "== Termux environment =="
  echo "Architecture: $(uname -m)"
  echo "PREFIX: $PREFIX"
  for cmd in clang make git pkg-config termux-usb; do
    if command -v "$cmd" >/dev/null 2>&1; then
      printf 'OK   %-12s %s\n' "$cmd" "$(command -v "$cmd")"
    else
      printf 'MISS %-12s\n' "$cmd"
    fi
  done
  echo
  echo "== pkg-config dependencies =="
  for pkg in libusb-1.0 libimobiledevice-glue-1.0 libirecovery-1.0; do
    if pkg-config --exists "$pkg" 2>/dev/null; then
      printf 'OK   %-30s %s\n' "$pkg" "$(pkg-config --modversion "$pkg")"
    else
      printf 'MISS %s\n' "$pkg"
    fi
  done
  echo
  echo "== USB devices visible to Termux:API =="
  termux-usb -l 2>&1 || true
  echo
  echo "Note: Android permission is granted per device through termux-usb."
}

probe() {
  local device="${1:-}"
  if ! command -v termux-usb >/dev/null 2>&1; then
    echo "termux-usb not found. Install package termux-api and the matching Android add-on."
    return 1
  fi
  if [[ ! -x "$probe" ]]; then
    echo "USB probe helper missing: $probe. Re-run setup.sh."
    return 1
  fi
  if [[ -z "$device" ]]; then
    echo "Currently visible USB devices:"
    termux-usb -l
    echo
    echo "Enter the exact device path from the list (or press Enter to cancel):"
    read -r device
  fi
  if [[ -z "$device" ]]; then
    echo "Cancelled."
    return 1
  fi
  echo "Requesting Android USB permission for: $device"
  termux-usb -r -e "$probe" "$device"
}

case "${1:-help}" in
  help|-h|--help) usage ;;
  doctor) doctor ;;
  probe) shift; probe "${1:-}" ;;
  all) doctor; echo; probe "${2:-}" ;;
  *) echo "Unknown command: $1"; usage; exit 2 ;;
esac
SH_EOF
chmod 755 "$PREFIX/bin/atv2"

say "Setup completed"
echo "Run: atv2 doctor"
echo "Then connect the Apple TV by USB-OTG and run: atv2 probe"
echo "Build log: $LOG"
echo "No firmware or boot commands were sent to the Apple TV."
