################################################################################
#
# gqmpeg
#
# gtk2 front end for mpg123. spawns the binary, doesn't link libmpg123.
# ships a working ./configure so no autoreconf
#
################################################################################

GQMPEG_VERSION = 0.91.1
GQMPEG_SITE = https://downloads.sourceforge.net/project/gqmpeg/gqmpeg/$(GQMPEG_VERSION)
GQMPEG_LICENSE = GPL-2.0+
GQMPEG_LICENSE_FILES = COPYING
GQMPEG_DEPENDENCIES = host-pkgconf libgtk2 libglib2 libpng

$(eval $(autotools-package))
