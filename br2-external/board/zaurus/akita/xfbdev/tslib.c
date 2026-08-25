/*
 * TSLIB based touchscreen driver for KDrive
 * Porting to new input API and event queueing by Daniel Stone.
 * Derived from ts.c by Keith Packard
 * Derived from ps2.c by Jim Gettys
 *
 * Copyright © 1999 Keith Packard
 * Copyright © 2000 Compaq Computer Corporation
 * Copyright © 2002 MontaVista Software Inc.
 * Copyright © 2005 OpenedHand Ltd.
 * Copyright © 2006 Nokia Corporation
 *
 * Permission to use, copy, modify, distribute, and sell this software and its
 * documentation for any purpose is hereby granted without fee, provided that
 * the above copyright notice appear in all copies and that both that
 * copyright notice and this permission notice appear in supporting
 * documentation, and that the name of the authors and/or copyright holders
 * not be used in advertising or publicity pertaining to distribution of the
 * software without specific, written prior permission.  The authors and/or
 * copyright holders make no representations about the suitability of this
 * software for any purpose.  It is provided "as is" without express or
 * implied warranty.
 *
 * THE AUTHORS AND/OR COPYRIGHT HOLDERS DISCLAIM ALL WARRANTIES WITH REGARD
 * TO THIS SOFTWARE, INCLUDING ALL IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS, IN NO EVENT SHALL THE AUTHORS AND/OR COPYRIGHT HOLDERS BE
 * LIABLE FOR ANY SPECIAL, INDIRECT OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
 * WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
 * ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
 * OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
 */

#ifdef HAVE_DIX_CONFIG_H
#include <dix-config.h>
#endif

#include <stdio.h>
#include <string.h>
#include <X11/X.h>
#include <X11/Xproto.h>
#include <X11/Xpoll.h>
#include "inputstr.h"
#include "scrnintstr.h"
#include "kdrive.h"
#include "kdlinux.h"
/* 21.1 removed KdCurScreen; this server has a single screen (0). */
#define KdCurScreen 0
#include <sys/ioctl.h>
#include <tslib.h>
#include <dirent.h>
#include <linux/input.h>

/* Native panel geometry (fb is fixed portrait; ts_calibrate/pointercal map raw
 * ADC -> these fb-native pixel coords). */
#define TS_NATIVE_W 480
#define TS_NATIVE_H 640

struct TslibPrivate {
    int fd;
    int lastx, lasty;
    struct tsdev *tsDev;
    void (*raw_event_hook) (int x, int y, int pressure, void *closure);
    void *raw_event_closure;
    int phys_screen;
    /* Orientation transform (fb-native -> rotated X screen), from
     * /etc/ts-orient. When the display is rotated (-screen @90/@270), kdrive's
     * own pointer matrix and this backport's shadow-rotation disagree, so we
     * disable kdrive's matrix (transformCoordinates=FALSE) and rotate here,
     * tunable on-device via the `zrot` helper without recalibrating. */
    int swapxy, invx, invy;
    int maxx, maxy;
};

/* Read /etc/ts-orient (tokens: swapxy invx invy) into the private state and set
 * the output max coords. Default (missing file / empty) = identity (portrait). */
static void
TslibReadOrient(struct TslibPrivate *p)
{
    FILE *f;
    char buf[128] = { 0 };

    p->swapxy = p->invx = p->invy = 0;

    f = fopen("/etc/ts-orient", "r");
    if (f) {
        if (fgets(buf, sizeof(buf) - 1, f)) {
            if (strstr(buf, "swapxy")) p->swapxy = 1;
            if (strstr(buf, "invx"))   p->invx = 1;
            if (strstr(buf, "invy"))   p->invy = 1;
        }
        fclose(f);
    }

    if (p->swapxy) {
        p->maxx = TS_NATIVE_H - 1;   /* landscape 640x480 */
        p->maxy = TS_NATIVE_W - 1;
    }
    else {
        p->maxx = TS_NATIVE_W - 1;   /* portrait 480x640 */
        p->maxy = TS_NATIVE_H - 1;
    }
    ErrorF("[tslib] orient: swapxy=%d invx=%d invy=%d (max %d,%d)\n",
           p->swapxy, p->invx, p->invy, p->maxx, p->maxy);
}

static void
TsRead(int fd, void *closure)
{
    KdPointerInfo *pi = closure;
    struct TslibPrivate *private = pi->driverPrivate;
    struct ts_sample event;
    long x = 0, y = 0;
    unsigned long flags;

    if (private->raw_event_hook) {
        while (ts_read_raw(private->tsDev, &event, 1) == 1)
            private->raw_event_hook(event.x, event.y, event.pressure,
                                    private->raw_event_closure);
        return;
    }

    while (ts_read(private->tsDev, &event, 1) == 1) {
        if (event.pressure) {
            flags = KD_BUTTON_1;
            private->lastx = event.x;
            private->lasty = event.y;
            x = event.x;
            y = event.y;
        }
        else {
            flags = 0;
            x = private->lastx;
            y = private->lasty;
        }

        /* fb-native -> rotated screen (see TslibReadOrient). */
        if (private->swapxy) {
            long t = x; x = y; y = t;
        }
        if (private->invx)
            x = private->maxx - x;
        if (private->invy)
            y = private->maxy - y;

        KdEnqueuePointerEvent(pi, flags, x, y, event.pressure);
    }
}

static Status
TslibEnable(KdPointerInfo * pi)
{
    struct TslibPrivate *private = pi->driverPrivate;

    private->raw_event_hook = NULL;
    private->raw_event_closure = NULL;
    if (!pi->path) {
        pi->path = strdup("/dev/input/touchscreen0");
        ErrorF("[tslib/TslibEnable] no device path given, trying %s\n",
               pi->path);
    }

    /* Open NON-BLOCKING (nonblock=1). TsRead() drains samples in a
     * while(ts_read()==1) loop; on 21.1 this runs on the input thread under a
     * level-triggered ospoll, so a blocking fd would wedge the whole input
     * thread the moment the buffer empties mid-touch. Non-blocking makes
     * ts_read return <=0 on EAGAIN and the loop exits back to ospoll_wait. */
    private->tsDev = ts_open(pi->path, 1);
    if (!private->tsDev) {
        ErrorF("[tslib/TslibEnable] failed to open %s\n", pi->path);
        return BadAlloc;
    }

    if (ts_config(private->tsDev)) {
        ErrorF("[tslib/TslibEnable] failed to load configuration\n");
        ts_close(private->tsDev);
        private->tsDev = NULL;
        return BadValue;
    }

    private->fd = ts_fd(private->tsDev);

    TslibReadOrient(private);

    KdRegisterFd(private->fd, TsRead, pi);

    return Success;
}

static void
TslibDisable(KdPointerInfo * pi)
{
    struct TslibPrivate *private = pi->driverPrivate;

    if (private->fd)
        KdUnregisterFd(pi, private->fd, TRUE);

    if (private->tsDev)
        ts_close(private->tsDev);

    private->fd = 0;
    private->tsDev = NULL;
}

static Status
TslibInit(KdPointerInfo * pi)
{
    struct TslibPrivate *private = NULL;

    if (!pi || !pi->dixdev)
        return !Success;

    pi->driverPrivate = (struct TslibPrivate *)
        calloc(sizeof(struct TslibPrivate), 1);
    if (!pi->driverPrivate)
        return !Success;

    private = pi->driverPrivate;
    /* hacktastic */
    private->phys_screen = 0;
    /* We apply our own orientation transform in TsRead, so keep kdrive from
     * also rotating these (already-calibrated) coordinates. */
    pi->transformCoordinates = FALSE;
    pi->nAxes = 3;
    pi->name = strdup("Touchscreen");
    pi->inputClass = KD_TOUCHSCREEN;

    return Success;
}

static void
TslibFini(KdPointerInfo * pi)
{
    free(pi->driverPrivate);
    pi->driverPrivate = NULL;
}

KdPointerDriver TsDriver = {
    "tslib",
    TslibInit,
    TslibEnable,
    TslibDisable,
    TslibFini,
    NULL,
};
