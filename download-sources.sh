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

function download_rpi3_wifi_firmware() {
    # download_rpi3_wifi_firmware_file \
    #     "$BRCM_WIFI_FIRMWARE_BASE_URL/$BRCM_WIFI_FIRMWARE_BIN" \
    #     "$BRCM_WIFI_FIRMWARE_DIR/$BRCM_WIFI_FIRMWARE_BIN"
    # download_rpi3_wifi_firmware_file \
    #     "$BRCM_WIFI_FIRMWARE_BASE_URL/$BRCM_WIFI_FIRMWARE_BIN_2" \
    #     "$BRCM_WIFI_FIRMWARE_DIR/$BRCM_WIFI_FIRMWARE_BIN_2"
    download_rpi3_wifi_firmware_file \
        "$BRCM_WIFI_FIRMWARE_BASE_URL/$BRCM_WIFI_FIRMWARE_TXT" \
        "$BRCM_WIFI_FIRMWARE_DIR/$BRCM_WIFI_FIRMWARE_TXT"
    download_rpi3_wifi_firmware_file \
        "$BRCM_WIFI_FIRMWARE_BASE_URL/$BRCM_WIFI_FIRMWARE_BIN_2" \
        "$BRCM_WIFI_FIRMWARE_DIR/$BRCM_WIFI_FIRMWARE_CLM_2"
    download_rpi3_wifi_firmware_file \
        "$BRCM_WIFI_FIRMWARE_BASE_URL/$BRCM_WIFI_FIRMWARE_TXT_2" \
        "$BRCM_WIFI_FIRMWARE_DIR/$BRCM_WIFI_FIRMWARE_TXT_2"
}

function download_rpi3_wifi_firmware_file() {
    local REMOTE_FILE="$1"
    local LOCAL_FILE="$2"

    if [ ! -e "$LOCAL_FILE" ]; then
        echo "Downloading $REMOTE_FILE..."
        curl -L -o "$LOCAL_FILE" "$REMOTE_FILE"
    else
        echo "$LOCAL_FILE is present."
    fi
}

init
make_resource_and_output_dirs
download_os_image
download_firmware
download_rpi3_wifi_firmware
exit_success
