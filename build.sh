#!/usr/bin/env bash
# =====================================================================
# One-shot, fully-automated Buildroot image build for the Sharp Zaurus
# SL-C1000 (Akita). No menuconfig, no manual package picking.
#
#   ./build.sh            clone Buildroot, fetch kernel pkg, configure, BUILD
#   ./build.sh config     stop after `make <defconfig>` (fast sanity check)
#   ./build.sh clean      remove the Buildroot output (keeps downloads)
#
# Everything the image contains is defined in br2-external/. Re-running is
# idempotent: existing clone/downloads are reused.
# =====================================================================
set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
EXT="$HERE/br2-external"
BR_DIR="$HERE/buildroot"
DL="$HERE/dl-cache"

# Buildroot LTS maintenance branch. 2025.02.x ships host-tar 1.35 (2024.02's
# host-tar 1.34 fails to build against modern libacl) and still has 5.4 headers.
BR2_BRANCH="2025.02.x"
BR2_REPO="https://github.com/buildroot/buildroot.git"

# Persist Buildroot's downloaded source tarballs (incl. the kernel) so
# re-clones don't re-fetch.
export BR2_DL_DIR="$DL/br-sources"

info() { printf '\033[1;36m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m warn:\033[0m %s\n' "$*" >&2; }
die()  { printf '\033[1;31merror:\033[0m %s\n' "$*" >&2; exit 1; }

# --- preflight ---------------------------------------------------------
# 'bc' is a mandatory Buildroot host dependency (dependencies.mk checks it).
for t in gcc g++ make git wget rsync cpio unzip perl file python3 bzip2 bc; do
	command -v "$t" >/dev/null 2>&1 || die "missing host tool '$t' — install it, e.g.: sudo pacman -S $t"
done

MODE="${1:-build}"

if [ "$MODE" = "clean" ]; then
	info "cleaning Buildroot output (downloads/clone kept)"
	[ -d "$BR_DIR/output" ] && make -C "$BR_DIR" O="$BR_DIR/output" clean || true
	rm -rf "$BR_DIR/output"
	exit 0
fi

# --- 1. Buildroot source (shallow, pinned) -----------------------------
if [ ! -d "$BR_DIR/.git" ]; then
	info "cloning Buildroot ($BR2_BRANCH)"
	git clone --depth 1 --branch "$BR2_BRANCH" "$BR2_REPO" "$BR_DIR"
else
	info "Buildroot already present ($BR_DIR)"
fi

# Kernel is now built from source by Buildroot (5.4.229 + our linux.config,
# see the defconfig). No prebuilt kernel package to fetch/extract anymore.

# --- 2. configure (non-interactive) ------------------------------------
info "applying zaurus_akita_defconfig"
make -C "$BR_DIR" BR2_EXTERNAL="$EXT" zaurus_akita_defconfig

if [ "$MODE" = "config" ]; then
	info "config-only mode: stopping before the long build"
	info "review: $BR_DIR/.config   |   full build: ./build.sh"
	exit 0
fi

# --- 3. build (first run compiles toolchain + kernel from source) ------
info "building (first run compiles the toolchain — this takes a while)"
make -C "$BR_DIR" BR2_EXTERNAL="$EXT"

info "done. artifacts in $BR_DIR/output/images/ :"
ls -lh "$BR_DIR/output/images/" 2>/dev/null || true
cat <<EOF

Flash sdcard.img to the card (single ext3 partition; zImage and boot.cfg
are inside it at /boot):
  sudo dd if=$BR_DIR/output/images/sdcard.img of=/dev/sdX bs=4M conv=fsync status=progress
EOF
