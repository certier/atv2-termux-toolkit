/*
 * ATV2 Termux USB probe.
 *
 * Reads the USB device descriptor and, when available, Apple's read-only
 * DFU serial metadata. It never sends DFU/iBoot commands or uploads data.
 */

#include <errno.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <libusb.h>

static int read_hex_tag(const char *text, const char *tag, unsigned long *value) {
    const char *p = strstr(text, tag);
    if (!p) return 0;
    p += strlen(tag);
    if (p[0] == '0' && (p[1] == 'x' || p[1] == 'X')) p += 2;

    errno = 0;
    char *end = NULL;
    unsigned long parsed = strtoul(p, &end, 16);
    if (errno != 0 || end == p) return 0;
    *value = parsed;
    return 1;
}

static void identify_apple_tv_board(unsigned long cpid, unsigned long bdid) {
    if (cpid == 0x8930 && bdid == 0x10) {
        puts("Board match:     AppleTV2,1 (Apple TV 2 / A1378)");
    } else if (cpid == 0x8942 && bdid == 0x08) {
        puts("Board match:     AppleTV3,1 (Apple TV 3 / A1427)");
    } else if (cpid == 0x8947 && bdid == 0x00) {
        puts("Board match:     AppleTV3,2 (Apple TV 3 Rev A / A1469)");
    } else {
        puts("Board match:     unknown Apple TV board combination");
    }
}

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
        puts("Reading optional DFU serial metadata (read-only)...");
        if (d.iSerialNumber != 0) {
            unsigned char serial[512];
            memset(serial, 0, sizeof(serial));
            int n = libusb_get_string_descriptor_ascii(
                handle, d.iSerialNumber, serial, (int)sizeof(serial) - 1);
            if (n > 0) {
                serial[n] = '\0';
                unsigned long cpid = 0, bdid = 0;
                int have_cpid = read_hex_tag((const char *)serial, "CPID:", &cpid);
                int have_bdid = read_hex_tag((const char *)serial, "BDID:", &bdid);
                if (have_cpid) printf("Chip ID (CPID):  0x%04lx\n", cpid);
                if (have_bdid) printf("Board ID (BDID): 0x%02lx\n", bdid);
                if (have_cpid && have_bdid) {
                    identify_apple_tv_board(cpid, bdid);
                } else {
                    puts("Board match:     serial metadata did not contain both CPID and BDID");
                }
            } else {
                printf("DFU metadata:    unavailable (%s)\n", libusb_error_name(n));
            }
        } else {
            puts("DFU metadata:    device has no serial-number descriptor");
        }
        puts("Privacy: ECID and full serial string are intentionally not printed.");
        puts("Note: USB mode alone does not identify the model or installed firmware.");
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
