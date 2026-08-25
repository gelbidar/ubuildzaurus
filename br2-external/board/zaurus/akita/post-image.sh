#!/bin/sh
# sd image. runs from the buildroot main dir so the path is relative
set -e
BOARD_DIR="$(dirname "$0")"
exec support/scripts/genimage.sh -c "${BOARD_DIR}/genimage.cfg"
