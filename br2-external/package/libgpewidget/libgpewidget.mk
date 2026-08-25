################################################################################
#
# libgpewidget
#
# gpe's widget lib, everything else links it
#
# 0.117 is the last release. ships a working ./configure and its automake
# 1.9 build system won't survive autoreconf, so don't. the patch touches
# Makefile.am and Makefile.in together to keep the shipped one working
#
################################################################################

LIBGPEWIDGET_VERSION = 0.117
LIBGPEWIDGET_SOURCE = libgpewidget_$(LIBGPEWIDGET_VERSION).orig.tar.bz2
LIBGPEWIDGET_SITE = http://archive.debian.org/debian/pool/main/libg/libgpewidget
LIBGPEWIDGET_LICENSE = LGPL-2.1+
LIBGPEWIDGET_LICENSE_FILES = COPYING.LIB
LIBGPEWIDGET_INSTALL_STAGING = YES
LIBGPEWIDGET_DEPENDENCIES = \
	host-pkgconf host-intltool libgtk2 libglib2 cairo xlib_libX11

# cairo is autodetected but ask anyway so it can't flip. gtk-doc needs a
# host gtk-doc we don't have
#
# don't add --disable-hildon. gpe's configure runs the same branch for
# disable as enable and turns hildon on. leaving it off is what disables it
LIBGPEWIDGET_CONF_OPTS = \
	--enable-cairo \
	--disable-gtk-doc \
	--disable-gtk-doc-html

$(eval $(autotools-package))
