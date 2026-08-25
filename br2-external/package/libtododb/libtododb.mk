################################################################################
#
# libtododb
#
# GPE to-do database library. Real release tarball with a working
# pre-generated ./configure, so no autoreconf. Pulls sqlite (v2) and
# libgpepimc in via pkg-config.
#
################################################################################

LIBTODODB_VERSION = 0.11
LIBTODODB_SOURCE = libtododb_$(LIBTODODB_VERSION).orig.tar.gz
LIBTODODB_SITE = http://archive.debian.org/debian/pool/main/libt/libtododb
LIBTODODB_LICENSE = GPL-2.0+
LIBTODODB_INSTALL_STAGING = YES
LIBTODODB_DEPENDENCIES = host-pkgconf libgpepimc sqlite2

$(eval $(autotools-package))
