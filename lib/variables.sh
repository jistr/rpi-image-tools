#!/bin/bash

RPI_OS_IMAGE_URL=${RPI_OS_IMAGE_URL:-https://download.fedoraproject.org/pub/fedora/linux/releases/24/Spins/armhfp/images/Fedora-Minimal-armhfp-24-1.2-sda.raw.xz}
RPI_FIRMWARE_URL=${RPI_FIRMWARE_URL:-https://github.com/raspberrypi/firmware/archive/b8ef00fa489792d9c29071669c775947bcc29e0c.tar.gz}

SOURCE_DIR=rpi-image-sources
OUTPUT_DIR=rpi-image-output

OS_IMAGE_PATH_COMPRESSED="$SOURCE_DIR/os/$(basename "$RPI_OS_IMAGE_URL")"
OS_IMAGE_PATH="$SOURCE_DIR/os/$(basename -s .xz "$OS_IMAGE_PATH_COMPRESSED")"

FIRMWARE_PATH_COMPRESSED="$SOURCE_DIR/firmware/$(basename "$RPI_FIRMWARE_URL")"
FIRMWARE_PATH="$SOURCE_DIR/firmware/firmware-$(basename -s .tar.gz "$FIRMWARE_PATH_COMPRESSED")"

OUT_IMAGE_PATH="$OUTPUT_DIR/rpi-$(basename "$OS_IMAGE_PATH")"
OUT_IMAGE_TMP_PATH="$OUT_IMAGE_PATH.unfinished"
