#!/bin/bash

function init() {
    if [ "${DEBUG:-0}" = "1" ]; then
        set -x
    fi
}

function exit_success() {
    print_stderr "SUCCESS."
    exit 0
}

function exit_error() {
    print_stderr "ERROR:" "$@"
    exit 1
}

function print_stderr() {
    echo "$@" > /dev/fd/2
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
