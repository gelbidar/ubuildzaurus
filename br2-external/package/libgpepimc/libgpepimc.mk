################################################################################
#
# libgpepimc
#
# GPE PIM category library. Ships a working pre-generated ./configure
# (real release tarball), so no autoreconf.
#
# Its configure asks pkg-config for "sqlite" - that is the SQLite *2*
# module name (SQLite 3 ships "sqlite3.pc"), hence the sqlite2 dependency.
#
################################################################################

LIBGPEPIMC_VERSION = 0.9
LIBGPEPIMC_SOURCE = libgpepimc_$(LIBGPEPIMC_VERSION).orig.tar.gz
LIBGPEPIMC_SITE = http://archive.debian.org/debian/pool/main/libg/libgpepimc
LIBGPEPIMC_LICENSE = LGPL-2.0+
LIBGPEPIMC_INSTALL_STAGING = YES
LIBGPEPIMC_DEPENDENCIES = \
	host-pkgconf host-intltool libgpewidget libgtk2 libglib2 sqlite2

# No --disable-hildon: in this configure.ac the AC_ARG_ENABLE "given" branch
# (which turns Hildon ON) fires for --disable-hildon too, and the build then
# dies on the missing hildon-lgpl/hildon-libs pkg-config modules. Leaving the
# flag off is what disables Hildon.

$(eval $(autotools-package))
