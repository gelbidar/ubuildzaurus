#!/usr/bin/env bash
# stage zImage + boot.cfg at /boot where kexecboot looks for them
set -euo pipefail

TARGET_DIR="${1:?post-build: TARGET_DIR not passed by Buildroot}"

# bash as root's login shell, ash stays /bin/sh
if [ -x "$TARGET_DIR/bin/bash" ]; then
	sed -i 's|^\(root:.*:\)/bin/sh$|\1/bin/bash|' "$TARGET_DIR/etc/passwd"
fi

ZIMAGE="${BINARIES_DIR:-}/zImage"
if [ ! -f "$ZIMAGE" ]; then
	echo "post-build: zImage not found at $ZIMAGE" >&2
	echo "            expected Buildroot to have built the kernel — check BR2_LINUX_KERNEL" >&2
	exit 1
fi

# kexecboot prepends its own root=/rootfstype= but set them anyway,
# kernel takes the last one
echo "post-build: staging /boot/zImage + /boot/boot.cfg into rootfs"
mkdir -p "$TARGET_DIR/boot"
cp -f "$ZIMAGE" "$TARGET_DIR/boot/zImage"
cat > "$TARGET_DIR/boot/boot.cfg" <<'EOF'
LABEL=Zaurus OS (SL-C1000)
KERNEL=/boot/zImage
APPEND=root=/dev/mmcblk0p1 rootfstype=ext3 rootwait rw console=ttyS0,115200n8 console=tty1 vt.global_cursor_default=0 consoleblank=0
PRIORITY=10
EOF
