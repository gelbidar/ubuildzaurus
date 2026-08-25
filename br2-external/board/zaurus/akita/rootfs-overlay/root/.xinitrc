#!/bin/sh
# Matchbox session on Xfbdev, scaled up for the small 480x640 panel:
#  - matchbox-desktop : app launcher on the root window
#  - matchbox-panel   : taskbar / clock / launcher along the edge
#  - WM uses the "zbig" theme (2x window decorations, DejaVu-rendered titles)
#  - xterm: does NOT auto-launch anymore (see .Xresources for its color/font/
#    geometry defaults - loaded once below via xrdb so they apply to every
#    xterm for the session, however it's started, not just one invocation)
export TSLIB_CALIBFILE=/etc/pointercal

# Load persistent X resources (xterm colors/font/geometry - see
# ~/.Xresources) before anything that might spawn an xterm.
xrdb -merge /root/.Xresources

# Akita (SL-C1000) keyboard overrides (Fn-as-AltGr, Shift+,=/ etc - see
# usr/share/X11/xkb/symbols/akita; named per-model since other Zaurus
# keyboards may differ). It's self-contained (pulls in the normal PC-105/US
# base itself), so load it alone - see the big comment at the top of that
# file for why NOT to do "pc+us+akita" here instead. Console gets the same
# physical facts independently via /etc/zaurus-console.kmap.
setxkbmap -symbols "akita"

# NOTE: launcher font/size options (--font/--titlefont/--icon-size) made
# matchbox-desktop fail to appear; reverted to defaults. Reintroduce larger
# launcher text carefully later.
matchbox-desktop --bg img-stretched:/usr/share/backgrounds/zaurus_wallpaper.png &
# -da/--default-apps: matchbox-panel's own compiled-in default is just
# "mb-applet-menu-launcher,mb-applet-clock" (src/session.c
# DEFAULT_SESSIONS) - add the battery meter (see matchbox-panel's
# 0007/0008 patches for why it needed real patches to work on this
# hardware at all). -ns/--no-session: don't let a saved session file
# from some earlier state silently override this list on a later boot.
matchbox-panel -da "mb-applet-menu-launcher,mb-applet-clock,mb-applet-battery" -ns &

# Use the enlarged theme; if it ever fails to load, fall back to the stock one
# so a theme problem can never leave you without a window manager.
matchbox-window-manager -theme zbig || matchbox-window-manager -theme Default
