#!/bin/sh
# Inject the backported kdrive Xfbdev server into an extracted xorg-server 21.1
# tree ($1 = build dir). Runs as a POST_PATCH hook, only for KDrive builds, so
# fbdev is added unconditionally (no fragile AM_CONDITIONAL).
set -e
D="$1"
HERE="$(cd "$(dirname "$0")" && pwd)"

mkdir -p "$D/hw/kdrive/fbdev"
cp "$HERE/fbdev.c" "$HERE/fbdev.h" "$HERE/kdmode.c" "$HERE/fbinit.c" \
   "$HERE/kdlinux.h" "$HERE/kdcompat.c" "$HERE/evdev.c" "$HERE/tslib.c" \
   "$HERE/Makefile.am" "$D/hw/kdrive/fbdev/"

# configure.ac: register the new Makefile so config.status generates it.
sed -i 's#hw/kdrive/ephyr/Makefile#hw/kdrive/ephyr/Makefile\nhw/kdrive/fbdev/Makefile#' "$D/configure.ac"

# hw/kdrive/Makefile.am: always build fbdev alongside ephyr.
sed -i 's#\$(XEPHYR_SUBDIRS)#$(XEPHYR_SUBDIRS) fbdev#' "$D/hw/kdrive/Makefile.am"
sed -i 's#^DIST_SUBDIRS = ephyr src#DIST_SUBDIRS = ephyr fbdev src#' "$D/hw/kdrive/Makefile.am"

echo "xfbdev: injected + wired (unconditional fbdev subdir)"
