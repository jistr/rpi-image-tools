#!/bin/bash

set -euo pipefail

BIN_DIR=$(cd $(dirname "${BASH_SOURCE[0]}") && pwd)
source "$BIN_DIR/lib/common.sh"
source "$BIN_DIR/lib/variables.sh"

function build_preconditions() {
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

init

echo "Filesystems and partitions in the original OS image:"
print_filesystems_and_partitions "$OS_IMAGE_PATH"

exit_success
