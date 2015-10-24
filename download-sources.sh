#!/bin/bash

set -x
set -euo pipefail

BIN_DIR=$(cd $(dirname "${BASH_SOURCE[0]}") && pwd)
source "$BIN_DIR/lib/common.sh"

make_resource_and_output_dirs
