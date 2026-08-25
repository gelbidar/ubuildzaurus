/*
 * Copyright © 1999 Keith Packard
 * Xfbdev kdrive server main, backported to xorg-server 21.1.
 */
#ifdef HAVE_DIX_CONFIG_H
#include <dix-config.h>
#endif
#include "fbdev.h"
#include "kdlinux.h"

extern int dix_main(int argc, char *argv[], char *envp[]);

int
main(int argc, char *argv[], char *envp[])
{
    return dix_main(argc, argv, envp);
}

void
InitCard(char *name)
{
    KdCardInfoAdd(&fbdevFuncs, 0);
}

void
InitOutput(ScreenInfo * pScreenInfo, int argc, char **argv)
{
    KdInitOutput(pScreenInfo, argc, argv);
}

void
InitInput(int argc, char **argv)
{
    /* 21.1 removed hw/kdrive/linux (KdOsAddInputDrivers). We backported the
     * evdev keyboard + tslib touchscreen drivers into this server; register
     * them and auto-probe /dev/input/event* for the Zaurus matrix keyboard
     * and ads7846 touchscreen. */
    FbdevInitInput();
    KdInitInput();
}

void
CloseInput(void)
{
    KdCloseInput();
}

#if INPUTTHREAD
/* Called from os/inputthread.c when starting the input thread. */
void
ddxInputThreadInit(void)
{
}
#endif

void
OsVendorInit(void)
{
}

void
ddxUseMsg(void)
{
    KdUseMsg();
    ErrorF("\nXfbdev Device Usage:\n");
    ErrorF("-fb path         Framebuffer device to use. Defaults to /dev/fb0\n");
    ErrorF("\n");
}

int
ddxProcessArgument(int argc, char **argv, int i)
{
    if (!strcmp(argv[i], "-fb")) {
        if (i + 1 < argc) {
            fbdevDevicePath = argv[i + 1];
            return 2;
        }
        UseMsg();
        exit(1);
    }

    return KdProcessArgument(argc, argv, i);
}

/* KdCardFuncs layout as of xorg-server 21.1. */
KdCardFuncs fbdevFuncs = {
    fbdevCardInit,              /* cardinit */
    fbdevScreenInit,            /* scrinit */
    fbdevInitScreen,            /* initScreen */
    fbdevFinishInitScreen,      /* finishInitScreen */
    fbdevCreateResources,       /* createRes */
    fbdevScreenFini,            /* scrfini */
    fbdevCardFini,              /* cardfini */

    0,                          /* initCursor */

    0,                          /* initAccel */
    0,                          /* enableAccel */
    0,                          /* disableAccel */
    0,                          /* finiAccel */

    fbdevGetColors,             /* getColors */
    fbdevPutColors,             /* putColors */

    0,                          /* closeScreen */
};
