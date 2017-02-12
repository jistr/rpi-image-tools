#!/bin/bash

set -euo pipefail

BIN_DIR=$(cd $(dirname "${BASH_SOURCE[0]}") && pwd)
source "$BIN_DIR/lib/common.sh"
source "$BIN_DIR/lib/variables.sh"

function assert_build_preconditions() {
    which guestfish &> /dev/null || exit_error "Please install libguestfs-tools."

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

function query_parameters() {
    if [ "${RPI_MODEL:-}" = "" ]; then
        echo -n "Enter model of the target RPi (2 or 3): "
        read RPI_MODEL
    fi
    if [ "${RPI_MODEL:-}" != "2" -a "${RPI_MODEL:-}" != "3" ]; then
        exit_error "Unsupported RPi model '$RPI_MODEL'."
    fi

    if [ "${RPI_BOOT_SIZE:-}" = "" ]; then
        echo -n "Enter new size of the boot partition (MB): "
        read RPI_BOOT_SIZE
    fi

    if [ "${RPI_SWAP_SIZE:-}" = "" ]; then
        echo -n "Enter new size of the swap partition (MB), or 'n' to build an image without swap: "
        read RPI_SWAP_SIZE
    fi

    if [ "${RPI_ROOT_SIZE:-}" = "" ]; then
        echo "Note: Root partition should be big enough for the contents of the original root fs."
        echo -n "Enter new size of the root partition (MB), or 'e' to expand to fit the image: "
        read RPI_ROOT_SIZE
    fi

    if [ "${RPI_IMAGE_SIZE:-}" = "" ]; then
        echo "Note: Image size should be at least slightly larger than the sum of all partitions."
        echo -n "Enter new size of the whole image (MB): "
        read RPI_IMAGE_SIZE
    fi

    if [ "${RPI_ROOT_PASSWORD:-}" = "" ]; then
        echo -n "Enter root password (for the built image, not this machine's): "
        read -s RPI_ROOT_PASSWORD
    fi

    ROOT_PARTITION_NUM=3
    if [ "$RPI_SWAP_SIZE" = "n" ]; then
        ROOT_PARTITION_NUM=2
    fi

    OUT_IMAGE_PATH="$OUTPUT_DIR/rpi${RPI_MODEL}-$(basename "$OS_IMAGE_PATH")"
    OUT_IMAGE_TMP_PATH="$OUT_IMAGE_PATH.unfinished"
}

function build_resized_image() {
    local boot_part=( --resize "/dev/sda1=${RPI_BOOT_SIZE}M" )
    local swap_part=( --resize "/dev/sda2=${RPI_SWAP_SIZE}M" )
    if [ "$RPI_SWAP_SIZE" = "n" ]; then
        swap_part=( --delete /dev/sda2 )
    fi
    local root_part=( --resize "/dev/sda3=${RPI_ROOT_SIZE}M" )
    if [ "$RPI_ROOT_SIZE" = "e" ]; then
        root_part=( --expand /dev/sda3 )
    fi

    echo "Creating space for the new image..."
    truncate -s "${RPI_IMAGE_SIZE}M" "$OUT_IMAGE_TMP_PATH"
    echo "Copying the partitions into place..."
    virt-resize "${boot_part[@]}" "${swap_part[@]}" "${root_part[@]}" "$OS_IMAGE_PATH" "$OUT_IMAGE_TMP_PATH"
}

function make_boot_vfat() {
    echo "Formatting boot as vfat..."
    OLD_BOOT_FS_UUID=$(virt-filesystems -a "$OUT_IMAGE_TMP_PATH" -l --uuid | grep /dev/sda1 | awk '{ print $7 }')

    guestfish -a "$OUT_IMAGE_TMP_PATH" run : mkfs vfat /dev/sda1 : part-set-mbr-id /dev/sda 1 0x0b

    BOOT_FS_UUID=$(virt-filesystems -a "$OUT_IMAGE_TMP_PATH" -l --uuid | grep /dev/sda1 | awk '{ print $7 }')
}

function amend_fstab() {
    echo "Amending boot partition UUID in fstab..."
    virt-edit -a "$OUT_IMAGE_TMP_PATH" /etc/fstab -e "s/$OLD_BOOT_FS_UUID/$BOOT_FS_UUID/" 2>&1 | sed -e 's/.*libguestfs: error: findfs_uuid.*//'

    echo "Amending boot partition type in fstab..."
    virt-edit -a "$OUT_IMAGE_TMP_PATH" /etc/fstab -e 's/(\/boot\s*)ext4/\1vfat/' 2>&1 | sed -e 's/.*libguestfs: error: findfs_uuid.*//'

    if [ "$RPI_SWAP_SIZE" = "n" ]; then
        echo "Removing swap from fstab..."
        virt-edit -a "$OUT_IMAGE_TMP_PATH" /etc/fstab -e 's/^.*swap.*swap.*$//' 2>&1 | sed -e 's/.*libguestfs: error: findfs_uuid.*//'
    fi
}

function set_fs_labels() {
    echo "Setting filesystem labels..."
    guestfish -a "$OUT_IMAGE_TMP_PATH" run : set-label /dev/sda1 rpiboot : set-label /dev/sda${ROOT_PARTITION_NUM} rpiroot
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

function configure_boot() {
    echo "Writing /boot/cmdline.txt and /boot/config.txt (use virt-edit to customize later)..."

    virt-customize -a "$OUT_IMAGE_TMP_PATH" \
                   --write "/boot/cmdline.txt:dwc_otg.lpm_enable=0 console=serial0,115200 console=tty1 root=/dev/mmcblk0p${ROOT_PARTITION_NUM} rootfstype=ext4 elevator=deadline rootwait" \
                   --write '/boot/config.txt:enable_uart=1
disable_overscan=1
hdmi_force_hotplug=1
hdmi_group=1
hdmi_mode=16'
}

function make_bootable() {
    echo "Making /dev/sda1 bootable..."
    guestfish -a "$OUT_IMAGE_TMP_PATH" run : part-set-bootable /dev/sda 1 true
}

function enable_serial0_getty() {
    echo "Enabling getty on serial0..."
    guestfish -i -a "$OUT_IMAGE_TMP_PATH" ln-s /lib/systemd/system/serial-getty@.service /etc/systemd/system/getty.target.wants/getty@serial0.service
}

function disable_initial_setup() {
    echo "Disabling initial-setup service..."
    guestfish -i -a "$OUT_IMAGE_TMP_PATH" rm /etc/systemd/system/multi-user.target.wants/initial-setup.service
}

function disable_auditd() {
    echo "Disabling auditd service..."
    # audit support is disabled in RPi kernels
    guestfish -i -a "$OUT_IMAGE_TMP_PATH" rm /etc/systemd/system/multi-user.target.wants/auditd.service
}

function set_root_password() {
    echo "Setting root password..."
    virt-customize -a "$OUT_IMAGE_TMP_PATH" --root-password file:<( echo "$RPI_ROOT_PASSWORD" )
}

function install_wifi_firmware() {
    echo "Installing WiFi firmware..."
    virt-customize -a "$OUT_IMAGE_TMP_PATH" \
                   --upload "$BRCM_WIFI_FIRMWARE_DIR/$BRCM_WIFI_FIRMWARE_BIN:/lib/firmware/brcm/$BRCM_WIFI_FIRMWARE_BIN" \
                   --upload "$BRCM_WIFI_FIRMWARE_DIR/$BRCM_WIFI_FIRMWARE_TXT:/lib/firmware/brcm/$BRCM_WIFI_FIRMWARE_TXT" \
                   --chmod "0644:/lib/firmware/brcm/$BRCM_WIFI_FIRMWARE_BIN" \
                   --chmod "0644:/lib/firmware/brcm/$BRCM_WIFI_FIRMWARE_TXT"

    # virt-customize doesn't do chowns (yet?)
    guestfish -i -a "$OUT_IMAGE_TMP_PATH" chown 0 0 "/lib/firmware/brcm/$BRCM_WIFI_FIRMWARE_BIN"
    guestfish -i -a "$OUT_IMAGE_TMP_PATH" chown 0 0 "/lib/firmware/brcm/$BRCM_WIFI_FIRMWARE_TXT"
}

function finalize() {
    echo "Finalizing..."
    mv "$OUT_IMAGE_TMP_PATH" "$OUT_IMAGE_PATH"
}

init


echo
echo "Filesystems and partitions in the original OS image:"
print_filesystems_and_partitions "$OS_IMAGE_PATH"
print_partition_assumptions

query_parameters
assert_build_preconditions

build_resized_image
make_boot_vfat
amend_fstab
set_fs_labels
install_firmware
configure_boot
make_bootable
enable_serial0_getty
disable_auditd
disable_initial_setup
set_root_password
if [ "$RPI_MODEL" == "3" ]; then
    install_wifi_firmware
fi
finalize

echo
echo "Filesystems and partitions in the built image:"
print_filesystems_and_partitions "$OUT_IMAGE_PATH"

echo
echo "The built image is at $OUT_IMAGE_PATH"

exit_success
