################################################################################
#
# gpe-todo
#
# GPE's to-do list. Sits on top of the whole PIM chain:
#   sqlite2 -> libgpewidget -> libgpepimc -> libtododb -> gpe-todo
#
# Real release tarball with a working shipped ./configure, so no autoreconf.
# Unlike gpe-edit it does NOT ship the generated intltool-* scripts, so
# AC_PROG_INTLTOOL needs intltool-update on PATH -> host-intltool is a real
# build dependency here, not just a nicety.
#
################################################################################

GPE_TODO_VERSION = 0.58
GPE_TODO_SOURCE = gpe-todo_$(GPE_TODO_VERSION).orig.tar.gz
GPE_TODO_SITE = http://archive.debian.org/debian/pool/main/g/gpe-todo
GPE_TODO_LICENSE = GPL-2.0+
GPE_TODO_DEPENDENCIES = \
	host-pkgconf host-intltool libgpewidget libtododb libgpepimc \
	libgtk2 libglib2

# No --disable-hildon here either - see the note in libgpepimc.mk: the flag
# enables Hildon whichever way you spell it.

$(eval $(autotools-package))
