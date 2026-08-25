################################################################################
#
# gpe-sketchbook
#
# not autotools. the top level Makefile pulls in fragments from gpe-build
# which isn't in the tarball, so drive src/Makefile directly and open-code
# the install
#
# upstream is dead and it was never in debian, tarball came off the wayback
# machine. keep a copy in BR2_DL_DIR
#
################################################################################

GPE_SKETCHBOOK_VERSION = 0.2.9
GPE_SKETCHBOOK_SOURCE = gpe-sketchbook-$(GPE_SKETCHBOOK_VERSION).tar.gz
GPE_SKETCHBOOK_SITE = https://web.archive.org/web/2019id_/http://gpe.linuxtogo.org/download/source
GPE_SKETCHBOOK_LICENSE = GPL-2.0+
GPE_SKETCHBOOK_LICENSE_FILES = COPYING
GPE_SKETCHBOOK_DEPENDENCIES = \
	host-pkgconf libgpewidget libgtk2 libglib2 gdk-pixbuf sqlite2

# flags go through the environment, never make VAR=. src/Makefile appends
# with += and a command line assignment kills that, drops -lgpewidget
define GPE_SKETCHBOOK_BUILD_CMDS
	$(TARGET_MAKE_ENV) $(TARGET_CONFIGURE_OPTS) $(MAKE) -C $(@D)/src \
		PREFIX=/usr CVSBUILD=no gpe-sketchbook
endef

# upstream runs intltool-merge, we just want the untranslated entry so
# strip the _ prefixes
define GPE_SKETCHBOOK_INSTALL_TARGET_CMDS
	$(INSTALL) -D -m 0755 $(@D)/src/gpe-sketchbook \
		$(TARGET_DIR)/usr/bin/gpe-sketchbook
	$(INSTALL) -d -m 0755 \
		$(TARGET_DIR)/usr/share/gpe/pixmaps/default/gpe-sketchbook
	$(INSTALL) -m 0644 $(@D)/pixmaps/*.png \
		$(TARGET_DIR)/usr/share/gpe/pixmaps/default/gpe-sketchbook/
	$(INSTALL) -D -m 0644 $(@D)/gpe-sketchbook.png \
		$(TARGET_DIR)/usr/share/pixmaps/gpe-sketchbook.png
	$(INSTALL) -d -m 0755 $(TARGET_DIR)/usr/share/applications
	sed -e 's/^_//' $(@D)/gpe-sketchbook.desktop.in \
		> $(TARGET_DIR)/usr/share/applications/gpe-sketchbook.desktop
	chmod 0644 $(TARGET_DIR)/usr/share/applications/gpe-sketchbook.desktop
endef

$(eval $(generic-package))
