/*
 * kdlinux.h — glue for the backported kdrive Linux input drivers on
 * xorg-server 21.1.
 *
 * xorg-server 21.1 removed hw/kdrive/linux and, with it, KdRegisterFd/
 * KdUnregisterFd (the select()-based fd multiplexer the old evdev/tslib
 * drivers used). We reimplement that tiny API on top of 21.1's input-thread
 * fd registration (InputThreadRegisterDev, which itself falls back to
 * SetNotifyFd when the input thread is not running). This keeps the
 * unmodified driver logic in evdev.c / tslib.c working, and guarantees their
 * KdEnqueue*Event() calls run in the correct (input-thread) context.
 */
#ifndef _KDLINUX_H_
#define _KDLINUX_H_

/* Old kdrive fd-callback API, reimplemented in kdcompat.c. The read callback
 * keeps its historical (fd, closure) signature so the vendored driver sources
 * need no changes to their call sites. */
extern Bool KdRegisterFd(int fd, void (*read) (int fd, void *closure),
                         void *closure);
extern void KdUnregisterFd(void *closure, int fd, Bool do_close);

/* Registers the backported evdev keyboard + tslib touchscreen drivers and
 * auto-probes /dev/input/event* for the Zaurus matrix keyboard and ads7846
 * touchscreen. Called from InitInput() in fbinit.c. */
extern void FbdevInitInput(void);

/* Driver records defined by the vendored sources. */
extern KdKeyboardDriver LinuxEvdevKeyboardDriver;
extern KdPointerDriver LinuxEvdevMouseDriver;
extern KdPointerDriver TsDriver;

#endif                          /* _KDLINUX_H_ */
