#!/bin/bash

set -euo pipefail

BIN_DIR=$(cd $(dirname "${BASH_SOURCE[0]}") && pwd)
source "$BIN_DIR/lib/common.sh"
source "$BIN_DIR/lib/variables.sh"

function assert_build_preconditions() {
    if [ -e "$OUT_IMAGE_PATH" ]; then
        exit_error "Output file $OUT_IMAGE_PATH already exists, aborting."
    fi

    if [ -e "$OUT_IMAGE_TMP_PATH" ]; then
        echo "Found an unfinished image $OUT_IMAGE_TMP_PATH, removing it..."
        rm "$OUT_IMAGE_TMP_PATH"
    fi
}

function print_filesystems_and_partitions() {
    local image_path="$1"
    virt-filesystems --long -h --all -a "$image_path"
}

function print_partition_assumptions() {
    echo -e "\nThis tool assumes sda1 = boot, sda2 = swap, sda3 = root fs\n"
}

function query_sizes() {
    if [ "${RPI_BOOT_SIZE:-}" = "" ]; then
        echo -n "Enter size of the boot partition (MB): "
        read RPI_BOOT_SIZE
    fi

    if [ "${RPI_SWAP_SIZE:-}" = "" ]; then
        echo -n "Enter size of the swap partition (MB), or 'n' build an image without swap: "
        read RPI_SWAP_SIZE
    fi

    if [ "${RPI_ROOT_SIZE:-}" = "" ]; then
        echo "Note: Root partition should be big enough for the contents of the original root fs."
        echo -n "Enter size of the root partition (MB): "
        read RPI_ROOT_SIZE
    fi

    if [ "${RPI_IMAGE_SIZE:-}" = "" ]; then
        echo "Note: Image size should be at least slightly larger than the sum of all partitions."
        echo -n "Enter size of the whole image (MB): "
        read RPI_IMAGE_SIZE
    fi
}

function build_resized_image() {
    local boot_part=( --resize "/dev/sda1=${RPI_BOOT_SIZE}M" )
    local swap_part=( --resize "/dev/sda2=${RPI_SWAP_SIZE}M" )
    if [ "$RPI_SWAP_SIZE" = "n" ]; then
        swap_part=( --delete /dev/sda2 )
    fi
    local root_part=( --resize "/dev/sda3=${RPI_ROOT_SIZE}M" )

    echo "Creating space for the new image..."
    truncate -s "${RPI_IMAGE_SIZE}M" "$OUT_IMAGE_TMP_PATH"
    echo "Copying the partitions into place..."
    virt-resize "${boot_part[@]}" "${swap_part[@]}" "${root_part[@]}" "$OS_IMAGE_PATH" "$OUT_IMAGE_TMP_PATH"
}

function amend_fstab() {
    if [ "$RPI_SWAP_SIZE" = "n" ]; then
        echo "Removing swap from fstab..."
        virt-edit -a "$OUT_IMAGE_TMP_PATH" /etc/fstab -e 's/^.*swap.*swap.*$//'
    fi
}

function install_firmware() {
    echo "Installing kernel and boot files..."
    local boot_files=( $(ls "$FIRMWARE_PATH/boot") )
    boot_files=( "${boot_files[@]/#/$FIRMWARE_PATH\/boot\/}" )
    virt-copy-in -a "$OUT_IMAGE_TMP_PATH" "${boot_files[@]}" /boot

    echo "Installing kernel modules..."
    local modules_files=( $(ls "$FIRMWARE_PATH/modules") )
    modules_files=( "${modules_files[@]/#/$FIRMWARE_PATH\/modules\/}" )
    virt-copy-in -a "$OUT_IMAGE_TMP_PATH" "${modules_files[@]}" /lib/modules
}

function make_bootable() {
    echo "Making /dev/sda1 bootable..."
    guestfish -a "$OUT_IMAGE_TMP_PATH" run : part-set-bootable /dev/sda 1 true
}

function finalize() {
    echo "Finalizing..."
    mv "$OUT_IMAGE_TMP_PATH" "$OUT_IMAGE_PATH"
}

init

assert_build_preconditions

echo
echo "Filesystems and partitions in the original OS image:"
print_filesystems_and_partitions "$OS_IMAGE_PATH"
print_partition_assumptions

query_sizes
build_resized_image
amend_fstab
install_firmware
make_bootable

finalize

echo
echo "Filesystems and partitions in the built image:"
print_filesystems_and_partitions "$OUT_IMAGE_PATH"

exit_success
