#!/bin/bash

function init() {
    if [ "${DEBUG:-0}" = "1" ]; then
        set -x
    fi
}

function exit_success() {
    echo
    echo "SUCCESS."
    exit 0
}

function exit_error() {
    echo
    echo "ERROR:" "$@"
    exit 1
}

function make_resource_and_output_dirs() {
    local dirs=(
        "$SOURCE_DIR"
        "$SOURCE_DIR/os"
        "$SOURCE_DIR/firmware"
        "$OUTPUT_DIR"
    )
    for dir in ${dirs[@]}; do
        [ -d "$dir" ] || mkdir "$dir"
    done
}
