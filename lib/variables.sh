#!/bin/bash

RPI_OS_IMAGE_URL=${RPI_OS_IMAGE_URL:-https://download.fedoraproject.org/pub/fedora/linux/releases/28/Spins/armhfp/images/Fedora-Minimal-armhfp-28-1.1-sda.raw.xz}
RPI_FIRMWARE_URL=${RPI_FIRMWARE_URL:-https://github.com/raspberrypi/firmware/archive/d71ef8b646a72b3f6cdde2da648be9ec27a5e875.tar.gz}
BRCM_WIFI_FIRMWARE_BASE_URL=${BRCM_WIFI_FIRMWARE_BASE_URL:-https://raw.githubusercontent.com/RPi-Distro/firmware-nonfree/master/brcm}

SOURCE_DIR=rpi-image-sources
OUTPUT_DIR=rpi-image-output

OS_IMAGE_PATH_COMPRESSED="$SOURCE_DIR/os/$(basename "$RPI_OS_IMAGE_URL")"
OS_IMAGE_PATH="$SOURCE_DIR/os/$(basename -s .xz "$OS_IMAGE_PATH_COMPRESSED")"

FIRMWARE_PATH_COMPRESSED="$SOURCE_DIR/firmware/$(basename "$RPI_FIRMWARE_URL")"
FIRMWARE_PATH="$SOURCE_DIR/firmware/firmware-$(basename -s .tar.gz "$FIRMWARE_PATH_COMPRESSED")"

BRCM_WIFI_FIRMWARE_DIR="$SOURCE_DIR/firmware-brcm-wifi"
BRCM_WIFI_FIRMWARE_BIN="brcmfmac43430-sdio.bin"
BRCM_WIFI_FIRMWARE_TXT="brcmfmac43430-sdio.txt"
BRCM_WIFI_FIRMWARE_BIN_2="brcmfmac43455-sdio.bin"
BRCM_WIFI_FIRMWARE_CLM_2="brcmfmac43455-sdio.clm_blob"
BRCM_WIFI_FIRMWARE_TXT_2="brcmfmac43455-sdio.txt"
