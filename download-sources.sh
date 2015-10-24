#!/bin/bash

set -euo pipefail

BIN_DIR=$(cd $(dirname "${BASH_SOURCE[0]}") && pwd)
source "$BIN_DIR/lib/common.sh"
source "$BIN_DIR/lib/variables.sh"

function download_firmware() {
    if [ ! -e "$FIRMWARE_PATH_COMPRESSED" -a ! -e "$FIRMWARE_PATH" ]; then
        echo "Downloading firmware..."
        curl -L -o "$FIRMWARE_PATH_COMPRESSED" "$RPI_FIRMWARE_URL"
    fi

    if [ ! -e "$FIRMWARE_PATH" ]; then
        echo "Extracting firmware..."
        tar -C "$SOURCE_DIR/firmware" -xzf "$FIRMWARE_PATH_COMPRESSED"
        [ -e "$FIRMWARE_PATH" ] || exit_error "Firmware extracted but not found"
        rm "$FIRMWARE_PATH_COMPRESSED"
    else
        echo "Firmware is downloaded and extracted."
    fi
}

function download_os_image() {
    if [ ! -e "$OS_IMAGE_PATH_COMPRESSED" -a ! -e "$OS_IMAGE_PATH" ]; then
        echo "Downloading OS image..."
        curl -L -o "$OS_IMAGE_PATH_COMPRESSED" "$RPI_OS_IMAGE_URL"
    fi

    if [ ! -e "$OS_IMAGE_PATH" ]; then
        echo "Extracting OS image..."
        unxz "$OS_IMAGE_PATH_COMPRESSED"
    else
        echo "OS image is downloaded and extracted."
    fi
}

init
make_resource_and_output_dirs
download_os_image
download_firmware
exit_success
