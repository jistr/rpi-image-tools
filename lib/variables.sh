#!/bin/bash

RPI_OS_IMAGE_URL=${RPI_OS_IMAGE_URL:-https://download.fedoraproject.org/pub/fedora/linux/releases/22/Images/armhfp/Fedora-Minimal-armhfp-22-3-sda.raw.xz}
RPI_FIRMWARE_URL=${RPI_FIRMWARE_URL:-https://github.com/raspberrypi/firmware/archive/4047fe26797884cedf53bc8671d19e7f6f9f59d5.tar.gz}

SOURCE_DIR=rpi-image-sources
OUTPUT_DIR=rpi-image-output

OS_IMAGE_PATH_COMPRESSED="$SOURCE_DIR/os/$(basename "$RPI_OS_IMAGE_URL")"
OS_IMAGE_PATH="$SOURCE_DIR/os/$(basename -s .xz "$OS_IMAGE_PATH_COMPRESSED")"

FIRMWARE_PATH_COMPRESSED="$SOURCE_DIR/firmware/$(basename "$RPI_FIRMWARE_URL")"
FIRMWARE_PATH="$SOURCE_DIR/firmware/firmware-$(basename -s .tar.gz "$FIRMWARE_PATH_COMPRESSED")"
