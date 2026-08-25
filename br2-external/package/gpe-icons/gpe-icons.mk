################################################################################
#
# gpe-icons
#
# data only. every gpe app calls gpe_load_icons() and aborts if one is
# missing. upstream's Makefile needs gpe-build so the install is open-coded
#
################################################################################

GPE_ICONS_VERSION = 0.25
GPE_ICONS_SOURCE = gpe-icons_$(GPE_ICONS_VERSION).orig.tar.gz
GPE_ICONS_SITE = http://archive.debian.org/debian/pool/main/g/gpe-icons
GPE_ICONS_LICENSE = GPL-2.0+

define GPE_ICONS_BUILD_CMDS
endef

define GPE_ICONS_INSTALL_TARGET_CMDS
	$(INSTALL) -d -m 0755 $(TARGET_DIR)/usr/share/gpe/pixmaps/default
	$(INSTALL) -m 0644 $(@D)/default/*.png \
		$(TARGET_DIR)/usr/share/gpe/pixmaps/default/
	$(INSTALL) -D -m 0644 $(@D)/gpe-logo.png \
		$(TARGET_DIR)/usr/share/gpe/pixmaps/gpe-logo.png
endef

$(eval $(generic-package))
