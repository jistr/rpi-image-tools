#!/bin/bash

function make_resource_and_output_dirs() {
    local dirs=(
        rpi-image-sources
        rpi-image-sources/os
        rpi-image-sources/firmware
        rpi-image-output
    )
    for dir in ${dirs[@]}; do
        [ -d "$dir" ] || mkdir "$dir"
    done
}
