# UBuildZaurus

A Buildroot-based toolchain for building customized Linux images from source for
the Sharp Zaurus (SL) series. While the current implementation has been designed
for and tested on the SL-C1000 `akita`, this script should work with `borzoi`,
`terrier`, and `spitz` with only a few changes. Feel free to contribute!

Although you can obtain prebuilt images in releases, this toolchain is completely
open and made for building your own customized image in the easiest possible way.
you pick your own package set, your own kernel options, your own files on the
rootfs, and get a reproducible SD image out the other end.

Progress as of now: working X server on a panel with no DRM, real touch and
keyboard input, and suspend. Those took a lot of digging, and they're what you'd
otherwise have to rediscover.

Everything that ends up in an image is defined by files in `br2-external/`. I
made it a big point in my design to never use `menuconfig`, so a build is
reproducible and a diff shows exactly what changed.

## Quick start

Build an image:

```sh
git clone https://github.com/gelbidar/ubuildzaurus.git
cd ubuildzaurus
./build.sh
```

The first run compiles a whole toolchain. It will take the longest.

Write it to an SD card. Example with dd:

```sh
sudo dd if=buildroot/output/images/sdcard.img of=/dev/sdX bs=4M conv=fsync status=progress
```

Put the card in the Zaurus and boot it with kexecboot. On a fresh image:

```sh
zcal     # calibrate the touchscreen
zx       # start X
```

To change what goes in the image, edit
`br2-external/configs/zaurus_akita_defconfig` and build again:

```
BR2_PACKAGE_NANO=y                # add a package
# BR2_PACKAGE_XTERM is not set    # remove one
```

To add your own files to the rootfs, drop them into
`board/zaurus/akita/rootfs-overlay/` at the path you want them to have on the
device. `rootfs-overlay/usr/bin/hello` lands at `/usr/bin/hello`.

Then `./build.sh` again and reflash.

See `INSTRUCTIONS.txt` for the long version.

## Reference configuration

The tree ships a complete and tested config for akita, but it can be tweaked for
the three sister models I listed earlier (borzoi, terrier, spitz).

| | |
|---|---|
| Build system | Buildroot 2025.02.x (pinned), gcc 13.4, glibc |
| Target | PXA270, ARMv5TE, soft float, EABI, 64 MB RAM |
| Kernel | Linux 5.4.229 from kernel.org + greguu's VoidZ config, plus fixes |
| X server | kdrive **Xfbdev**, backported from xorg-server 1.18.4 into 21.1 |
| Input | evdev keyboard + tslib touch (ads7846), custom Akita keymap |
| Desktop | matchbox WM + desktop launcher + panel (clock, battery) |
| Apps | GPE suite (edit, todo, sketchbook), gqmpeg, xterm |
| Audio | in-kernel ASoC (wm8750) + alsa-lib + mpg123 - in progress |

Nine packages under `br2-external/package/` don't exist in mainline Buildroot and
are hand-packaged here: `sqlite2`, `libgpewidget`, `libgpepimc`, `libtododb`,
`gpe-icons`, `gpe-edit`, `gpe-todo`, `gpe-sketchbook`, `gqmpeg`. Tarballs came
from the Debian archive and the Internet Archive.

Boots from SD via kexecboot (or however else), so NAND stays untouched and the
device is always recoverable.

## Building

Needs a normal Linux host with the usual build tools (`gcc`, `make`, `git`,
`rsync`, `cpio`, `bc`, `python3`, …). `build.sh` checks for them and tells you
what's missing. Nothing needs root.

```sh
./build.sh            # full build
./build.sh config     # just apply the defconfig, quick sanity check
./build.sh clean      # wipe the output, keeps downloads
```

First run clones Buildroot and compiles the whole toolchain, so expect
30–60 minutes. After that it's incremental. Downloads are cached in `dl-cache/`
and survive a clean.

The image lands at `buildroot/output/images/sdcard.img`. Write it to a card:

```sh
sudo dd if=buildroot/output/images/sdcard.img of=/dev/sdX bs=4M conv=fsync status=progress
```

It's a single ext3 partition; `zImage` and `boot.cfg` live inside it at `/boot`,
where kexecboot looks for them.

## Customizing

This is the point of the project. Everything below is a file edit followed by
`./build.sh`.

To **add or remove software**, just edit `br2-external/configs/zaurus_akita_defconfig`.
It's a plain list of `BR2_PACKAGE_*` lines; add one for anything in Buildroot's
catalogue, delete one to drop it. Dependencies pull themselves in.

To **put files on the image**, drop them anywhere under
`board/zaurus/akita/rootfs-overlay/`, matching the layout you want on the
device. The overlay is copied over the rootfs last, so it also overrides files a
package installed.

To **change kernel options**, edit `board/zaurus/akita/linux.config`. To patch
kernel source, add a `.patch` to `board/zaurus/akita/linux-patches/`; they apply
in name order.

To manually **package something Buildroot doesn't have**, make
`br2-external/package/<name>/` with a `Config.in` and `<name>.mk`, then add a
`source` line to `br2-external/Config.in`. The nine packages already there are
worth reading first to save you from wasted effort.

To **target a different Zaurus**, copy `board/zaurus/akita/` to
`board/zaurus/<model>/` and add a defconfig next to the existing one. The board
directory is self-contained, so the X server, packages and overlay carry over;
what changes is the kernel config and the model-specific bits like the keymap.

### Rebuild quirk

Editing the overlay, the defconfig, or a script just needs `./build.sh`. But
editing `xfbdev/` sources, a kernel patch, or a vendored Buildroot package does
**not** trigger a rebuild. It'll just ship the old binary. Use this.

```sh
make -C buildroot BR2_EXTERNAL=$PWD/br2-external <pkg>-dirclean
./build.sh
```

Use `linux-dirclean` for kernel patches, `xserver_xorg-server-dirclean` for
Xfbdev. Patches only apply at extract time, which is why a plain rebuild misses
them.

## On the device

Fresh flash: run `zcal` to calibrate the touchscreen, then `zx` to start X.

Everything is named in letters only, because a fresh image can't type most
symbols until the keymap is loaded (learned the hard way).

| | |
|---|---|
| `zx` | start X (use this, not `startx`) |
| `zcal` | touchscreen calibration |
| `zcf` | mount a CF card at `/mnt/cf` |
| `zclock` | manually set the clock, supports both 24 and 12 hr format |
| `zsleep` (daemon) | suspend to RAM, full backlight off |
| `zpwrd` (daemon) | power button management |
| `zpkgman` | ncurses package remover, ships on the prebuilt images |

There are more of them for touch tuning, keymap capture and diagnostics. See
`INSTRUCTIONS.txt` for the full list.

## History

Started as a Buildroot userland on a prebuilt kernel, then moved to building the
kernel from source so it could be fixed. Along the way:

- I switched from musl to glibc because musl's eager symbol binding broke Xorg's module
  loading.
- Full Xorg with `xf86-video-fbdev` never allocated a screen on the 
  display, and modern xorg-server had deleted the lightweight kdrive Xfbdev
  server so I backported it into 21.1.
- Suspend would fade the screen to white. `CONFIG_GPIO_PCA953X=y` fixed that, because
  the panel power and backlight on my model Zaurus are wired through a MAX7310 I²C expander.
- The keyboard was mapped from a real `showkey` capture, for both X and the
  console, because several symbols were untypable on the Zaurus (`akita`) keyboard.
- The power button suspended in-kernel before userspace could dim the
  backlight, so that path is disabled and a small daemon handles it.
- Audio caused the 5.4 kernel to panic. The legacy PXA ASoC code registers the same PCM
  ops on two components, so every substream was opened and closed twice which
  double-frees the dmaengine runtime and corrupts the slab. Two patches in
  `board/zaurus/akita/linux-patches/` fix it.

video playback (through MPlayer), and replacing kexecboot with something much faster are on the to-do list.

## Prebuilt images

Prebuilt images will be released for people who just want to flash something and
go. They're a convenience, but I wouldn't say the focus. if you want to change anything about
one, your best option is usually to just build your own, with the exception of removing unneeded packages.

## Layout

```text
.
├── build.sh                    the only entry point
├── br2-external/
│   ├── configs/                the defconfig. edit this, never menuconfig
│   ├── package/                custom packages (not in mainline Buildroot)
│   └── board/zaurus/akita/
│       ├── linux.config        kernel config
│       ├── linux-patches/      kernel fixes
│       ├── xfbdev/             the Xfbdev backport
│       ├── rootfs-overlay/     scripts, init, keymaps, theme, icons
│       ├── post-build.sh       stages the kernel into /boot
│       └── post-image.sh       builds the SD image
├── INSTRUCTIONS.txt            the detailed guide
└── LICENSE                     GPL-2.0
```

## License

GPL-2.0. See `LICENSE`.

The kernel patches under `board/zaurus/akita/linux-patches/` are derived from
kernel source and are GPL-2.0 for that reason. Everything else here, including
the scripts and board config, is GPL-2.0 as well.

## Footnotes

Support for the older ARMv4 SL models is planned.

This project was written with the assistance of Qwen 3.5 9B as a learning
exercise for CPL. If you see C, it's probably the result of AI iterating on my buggy drafts.

Everything here has been built and tested on genuine Zaurus hardware. None of it
is theoretical or emulator-only.
