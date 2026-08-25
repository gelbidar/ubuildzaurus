################################################################################
#
# gpe-edit
#
# GPE's PDA text editor. The lightest of the GPE apps: gtk+-2.0, glib-2.0
# and libgpewidget, nothing else. Real release tarball, working shipped
# ./configure (and shipped generated intltool-* scripts), so neither
# autoreconf nor a patch is needed.
#
################################################################################

GPE_EDIT_VERSION = 0.41
GPE_EDIT_SOURCE = gpe-edit_$(GPE_EDIT_VERSION).orig.tar.gz
GPE_EDIT_SITE = http://archive.debian.org/debian/pool/main/g/gpe-edit
GPE_EDIT_LICENSE = GPL-2.0+
GPE_EDIT_DEPENDENCIES = \
	host-pkgconf host-intltool libgpewidget libgtk2 libglib2

$(eval $(autotools-package))
