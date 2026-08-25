/*
 * kdcompat.c — KdRegisterFd/KdUnregisterFd compatibility shim + input
 * auto-probe for the backported kdrive Linux input drivers on xorg-server
 * 21.1. See kdlinux.h for rationale.
 */
#ifdef HAVE_DIX_CONFIG_H
#include <dix-config.h>
#endif

#include <errno.h>
#include <fcntl.h>
#include <unistd.h>
#include <string.h>
#include <stdio.h>
#include <sys/ioctl.h>
#include <linux/input.h>

#include <X11/X.h>
#include <X11/Xproto.h>
#include "inputstr.h"
#include "scrnintstr.h"
#include "kdrive.h"
#include "kdlinux.h"

/* ------------------------------------------------------------------ */
/* KdRegisterFd / KdUnregisterFd on top of InputThreadRegisterDev.     */
/* ------------------------------------------------------------------ */

#define KD_MAX_FDS 16

typedef struct _KdFdRec {
    int used;
    int fd;
    void (*read) (int fd, void *closure);
    void *closure;
} KdFdRec;

static KdFdRec kdFds[KD_MAX_FDS];

/* NotifyFdProcPtr trampoline: bridge 21.1's (fd, xevents, data) callback to
 * the historical kdrive (fd, closure) read callback. */
static void
KdNotifyFd(int fd, int xevents, void *data)
{
    KdFdRec *r = data;

    if (r && r->used && r->read)
        r->read(r->fd, r->closure);
}

Bool
KdRegisterFd(int fd, void (*read) (int fd, void *closure), void *closure)
{
    int i;

    for (i = 0; i < KD_MAX_FDS; i++)
        if (!kdFds[i].used)
            break;
    if (i == KD_MAX_FDS) {
        ErrorF("KdRegisterFd: out of slots for fd %d\n", fd);
        return FALSE;
    }

    kdFds[i].used = 1;
    kdFds[i].fd = fd;
    kdFds[i].read = read;
    kdFds[i].closure = closure;

    if (InputThreadRegisterDev(fd, KdNotifyFd, &kdFds[i]) < 0) {
        kdFds[i].used = 0;
        ErrorF("KdRegisterFd: InputThreadRegisterDev failed for fd %d\n", fd);
        return FALSE;
    }

    return TRUE;
}

void
KdUnregisterFd(void *closure, int fd, Bool do_close)
{
    int i;

    for (i = 0; i < KD_MAX_FDS; i++) {
        if (!kdFds[i].used)
            continue;
        if (kdFds[i].closure != closure)
            continue;
        if (fd != -1 && kdFds[i].fd != fd)
            continue;

        InputThreadUnregisterDev(kdFds[i].fd);
        if (do_close)
            close(kdFds[i].fd);
        kdFds[i].used = 0;
    }
}

/* ------------------------------------------------------------------ */
/* Device auto-probe.                                                  */
/* ------------------------------------------------------------------ */

#define KD_BITS_PER_LONG (sizeof(long) * 8)
#define KD_NBITS(x) ((((x) - 1) / KD_BITS_PER_LONG) + 1)
#define KD_ISBITSET(a, b) ((a)[(b) / KD_BITS_PER_LONG] & \
                           (1UL << ((b) % KD_BITS_PER_LONG)))

/* Classify an evdev node. Returns 1 = keyboard, 2 = touchscreen, 0 = other. */
static int
KdClassifyEvdev(const char *path)
{
    int fd, cls = 0;
    unsigned long evbits[KD_NBITS(EV_MAX)];
    unsigned long keybits[KD_NBITS(KEY_MAX)];
    unsigned long absbits[KD_NBITS(ABS_MAX)];

    fd = open(path, O_RDONLY);
    if (fd < 0)
        return 0;

    memset(evbits, 0, sizeof(evbits));
    memset(keybits, 0, sizeof(keybits));
    memset(absbits, 0, sizeof(absbits));

    if (ioctl(fd, EVIOCGBIT(0, sizeof(evbits)), evbits) < 0) {
        close(fd);
        return 0;
    }

    /* A touchscreen reports absolute X/Y (the ads7846). */
    if (KD_ISBITSET(evbits, EV_ABS)) {
        if (ioctl(fd, EVIOCGBIT(EV_ABS, sizeof(absbits)), absbits) >= 0 &&
            KD_ISBITSET(absbits, ABS_X) && KD_ISBITSET(absbits, ABS_Y)) {
            close(fd);
            return 2;
        }
    }

    /* A keyboard reports letter keys but no absolute axes (the matrix kbd). */
    if (KD_ISBITSET(evbits, EV_KEY)) {
        if (ioctl(fd, EVIOCGBIT(EV_KEY, sizeof(keybits)), keybits) >= 0 &&
            (KD_ISBITSET(keybits, KEY_A) || KD_ISBITSET(keybits, KEY_ENTER)))
            cls = 1;
    }

    close(fd);
    return cls;
}

void
FbdevInitInput(void)
{
    char path[64];
    char *kbdPath = NULL, *tsPath = NULL;
    int i;

    KdAddKeyboardDriver(&LinuxEvdevKeyboardDriver);
    KdAddPointerDriver(&LinuxEvdevMouseDriver);
    KdAddPointerDriver(&TsDriver);

    /* Probe event nodes; first keyboard + first touchscreen win. */
    for (i = 0; i < 32 && (!kbdPath || !tsPath); i++) {
        int cls;

        snprintf(path, sizeof(path), "/dev/input/event%d", i);
        cls = KdClassifyEvdev(path);
        if (cls == 1 && !kbdPath)
            kbdPath = strdup(path);
        else if (cls == 2 && !tsPath)
            tsPath = strdup(path);
    }

    if (kbdPath) {
        KdKeyboardInfo *ki = KdNewKeyboard();

        if (ki) {
            ki->driver = &LinuxEvdevKeyboardDriver;
            free(ki->path);
            ki->path = kbdPath;
            ErrorF("Xfbdev: keyboard on %s\n", ki->path);
            KdAddKeyboard(ki);
        }
    }
    else {
        ErrorF("Xfbdev: no evdev keyboard found\n");
    }

    if (tsPath) {
        KdPointerInfo *pi = KdNewPointer();

        if (pi) {
            pi->driver = &TsDriver;
            free(pi->path);
            pi->path = tsPath;
            ErrorF("Xfbdev: touchscreen on %s\n", pi->path);
            KdAddPointer(pi);
        }
    }
    else {
        ErrorF("Xfbdev: no touchscreen found\n");
    }
}
