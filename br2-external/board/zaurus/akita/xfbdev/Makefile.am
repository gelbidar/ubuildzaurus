AM_CPPFLAGS =			\
	@KDRIVE_INCS@		\
	@KDRIVE_CFLAGS@	\
	-DHAVE_DIX_CONFIG_H	\
	-I$(top_srcdir)

bin_PROGRAMS = Xfbdev

Xfbdev_SOURCES =	\
	fbdev.c		\
	fbdev.h		\
	kdmode.c	\
	kdlinux.h	\
	kdcompat.c	\
	evdev.c		\
	tslib.c		\
	fbinit.c

# tslib.c pulls in libts for the ads7846 touchscreen; the evdev + fd-shim
# sources need no extra libraries beyond KDRIVE_LIBS.
Xfbdev_LDADD = @KDRIVE_LIBS@ -lts

Xfbdev_DEPENDENCIES = @KDRIVE_LOCAL_LIBS@

Xfbdev_LDFLAGS = $(LD_EXPORT_SYMBOLS_FLAG)

relink:
	$(AM_V_at)rm -f $(bin_PROGRAMS) && $(MAKE) $(bin_PROGRAMS)
