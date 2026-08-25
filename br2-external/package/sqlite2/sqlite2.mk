################################################################################
#
# sqlite2
#
# sqlite 2.8.17, only here because the gpe libs use the v2 API. sits
# alongside buildroot's sqlite v3.
#
# three things make it awkward to cross compile:
#  1. its own build/host compiler split predates --host, so without
#     config_TARGET_CC the target objects get built with the host cc
#  2. lemon.c is K&R so host gcc needs -std=gnu89. the AC_CHECK_FILE probes
#     for tcl/readline are fatal when cross compiling, faked via the cache
#  3. config.h records sizeof(char*) by compiling and running a native
#     helper, so it measures the host's 8 bytes and every sqlite_open()
#     aborts on the ptr size assert. the rule has no prereqs so just
#     pre-create config.h and it never runs
#
################################################################################

SQLITE2_VERSION = 2.8.17
SQLITE2_SOURCE = sqlite_$(SQLITE2_VERSION).orig.tar.gz
SQLITE2_SITE = http://archive.debian.org/debian/pool/main/s/sqlite
SQLITE2_LICENSE = Public Domain
SQLITE2_INSTALL_STAGING = YES
SQLITE2_DEPENDENCIES = host-pkgconf readline ncurses

# the shell always links readline+ncurses and the var won't take an empty
# value, hence the deps
SQLITE2_CONF_ENV = \
	config_BUILD_CC="$(HOSTCC)" \
	config_BUILD_CFLAGS="-O2 -std=gnu89 -w" \
	config_BUILD_LIBS="" \
	config_TARGET_CC="$(TARGET_CC)" \
	config_TARGET_CFLAGS="$(TARGET_CFLAGS) -std=gnu89 -w" \
	ac_cv_file__usr_local_include_tcl_h=no \
	ac_cv_file__usr_X11_include_tcl_h=no \
	ac_cv_file__usr_X11R6_include_tcl_h=no \
	ac_cv_file__usr_pkg_include_tcl_h=no \
	ac_cv_file__usr_contrib_include_tcl_h=no \
	ac_cv_file__usr_include_tcl_h=no \
	ac_cv_file__usr_include_readline_h=no \
	ac_cv_file__usr_include_readline_readline_h=no \
	ac_cv_file__usr_local_include_readline_h=no \
	ac_cv_file__usr_local_include_readline_readline_h=no \
	ac_cv_file__usr_local_readline_include_readline_h=no \
	ac_cv_file__usr_local_readline_include_readline_readline_h=no \
	ac_cv_file__usr_contrib_include_readline_h=no \
	ac_cv_file__usr_contrib_include_readline_readline_h=no \
	ac_cv_file__mingw_include_readline_h=no \
	ac_cv_file__mingw_include_readline_readline_h=no

SQLITE2_CONF_OPTS = \
	--disable-tcl \
	--enable-threadsafe=no

# bundled ltmain is 1.5.2 and buildroot's generic 1.5 patch doesn't apply
# to it. same as lzop.mk. config.guess/sub still get updated
SQLITE2_LIBTOOL_PATCH = NO

# point 3. 4 is right for 32-bit arm, a 64-bit target would need this
# made conditional
define SQLITE2_FIX_CONFIG_H
	echo '#define SQLITE_PTR_SZ 4' > $(@D)/config.h
endef
SQLITE2_PRE_BUILD_HOOKS += SQLITE2_FIX_CONFIG_H

$(eval $(autotools-package))
