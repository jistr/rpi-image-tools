#!/bin/bash

function exit_error() {
    echo "$@"
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
