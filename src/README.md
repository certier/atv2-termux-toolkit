# USB probe helper

This is compiled by `setup.sh` for the current Termux architecture. It accepts the file descriptor passed by `termux-usb -e`, wraps it with `libusb_wrap_sys_device()`, and reads only the USB device descriptor.

It does not issue control transfers, claim interfaces, upload files, or send iBoot/DFU commands.
