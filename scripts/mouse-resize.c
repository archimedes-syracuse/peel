// Turns one mouse button into Super+right-drag: clones the mouse and holds
// Super on a virtual keyboard, because Mango only reads hard keyboard mods.
// Build: gcc -O2 -Wall -Wextra -o mouse-resize mouse-resize.c $(pkg-config --cflags --libs libevdev)
#define _GNU_SOURCE
#include <errno.h>
#include <fcntl.h>
#include <libevdev/libevdev.h>
#include <libevdev/libevdev-uinput.h>
#include <linux/input.h>
#include <linux/input-event-codes.h>
#include <poll.h>
#include <signal.h>
#include <stdbool.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

#define DEFAULT_DEVICE "/dev/input/by-id/usb-Razer_Razer_Basilisk_V3-event-mouse"
#define VIRTUAL_KEYBOARD_NAME "mouse-resize Super key"

static volatile sig_atomic_t stop_requested = 0;

static void on_signal(int sig)
{
    (void)sig;
    stop_requested = 1;
}

static void log_errno(const char *what)
{
    fprintf(stderr, "mouse-resize: %s: %s\n", what, strerror(errno));
}

static int write_event(struct libevdev_uinput *uidev, unsigned int type,
                       unsigned int code, int value)
{
    int rc = libevdev_uinput_write_event(uidev, type, code, value);
    if (rc < 0)
        log_errno("libevdev_uinput_write_event");
    return rc;
}

static int sync_device(struct libevdev_uinput *uidev)
{
    return write_event(uidev, EV_SYN, SYN_REPORT, 0);
}

static int parse_button(const char *value)
{
    if (!value || !*value)
        return BTN_EXTRA;

    if (!strcmp(value, "BTN_SIDE") || !strcmp(value, "side") || !strcmp(value, "back"))
        return BTN_SIDE;
    if (!strcmp(value, "BTN_EXTRA") || !strcmp(value, "extra") || !strcmp(value, "forward"))
        return BTN_EXTRA;
    if (!strcmp(value, "BTN_MIDDLE") || !strcmp(value, "middle"))
        return BTN_MIDDLE;
    if (!strcmp(value, "BTN_LEFT") || !strcmp(value, "left"))
        return BTN_LEFT;
    if (!strcmp(value, "BTN_RIGHT") || !strcmp(value, "right"))
        return BTN_RIGHT;

    char *end = NULL;
    long parsed = strtol(value, &end, 0);
    if (end && *end == '\0' && parsed >= 0 && parsed <= KEY_MAX)
        return (int)parsed;

    fprintf(stderr, "mouse-resize: unknown button '%s' "
                    "(use BTN_EXTRA, BTN_SIDE or BTN_RIGHT)\n", value);
    return -1;
}

static struct libevdev *clone_device(struct libevdev *source, int resize_button)
{
    struct libevdev *clone = libevdev_new();
    if (!clone) {
        fprintf(stderr, "mouse-resize: libevdev_new failed\n");
        return NULL;
    }

    const char *source_name = libevdev_get_name(source);
    char name[256];
    snprintf(name, sizeof(name), "%s (resize helper)",
             source_name ? source_name : "mouse");
    libevdev_set_name(clone, name);
    libevdev_set_id_bustype(clone, libevdev_get_id_bustype(source));
    libevdev_set_id_vendor(clone, libevdev_get_id_vendor(source));
    libevdev_set_id_product(clone, libevdev_get_id_product(source));
    libevdev_set_id_version(clone, libevdev_get_id_version(source));

    for (unsigned int type = 0; type <= EV_MAX; type++) {
        if (!libevdev_has_event_type(source, type))
            continue;
        if (libevdev_enable_event_type(clone, type) < 0) {
            fprintf(stderr, "mouse-resize: cannot enable event type %u\n", type);
            libevdev_free(clone);
            return NULL;
        }

        int max = libevdev_event_type_get_max(type);
        if (max < 0)
            continue;

        for (unsigned int code = 0; code <= (unsigned int)max; code++) {
            if (!libevdev_has_event_code(source, type, code))
                continue;
            if (type == EV_KEY && (int)code == resize_button)
                continue;

            const struct input_absinfo *abs = NULL;
            if (type == EV_ABS)
                abs = libevdev_get_abs_info(source, code);

            if (libevdev_enable_event_code(clone, type, code, abs) < 0) {
                fprintf(stderr, "mouse-resize: cannot enable %u/%u\n", type, code);
                libevdev_free(clone);
                return NULL;
            }
        }
    }

    for (unsigned int prop = 0; prop <= INPUT_PROP_MAX; prop++) {
        if (libevdev_has_property(source, prop))
            libevdev_enable_property(clone, prop);
    }

    return clone;
}

static struct libevdev *create_keyboard(void)
{
    struct libevdev *kb = libevdev_new();
    if (!kb)
        return NULL;

    libevdev_set_name(kb, VIRTUAL_KEYBOARD_NAME);
    libevdev_set_phys(kb, "mouse-resize/input0");
    libevdev_set_id_bustype(kb, BUS_USB);
    libevdev_set_id_vendor(kb, 0x046d);
    libevdev_set_id_product(kb, 0xc31c);
    libevdev_set_id_version(kb, 0x0111);

    if (libevdev_enable_event_type(kb, EV_SYN) < 0 ||
        libevdev_enable_event_code(kb, EV_SYN, SYN_REPORT, NULL) < 0 ||
        libevdev_enable_event_type(kb, EV_KEY) < 0 ||
        libevdev_enable_event_code(kb, EV_KEY, KEY_LEFTMETA, NULL) < 0) {
        fprintf(stderr, "mouse-resize: cannot create virtual keyboard\n");
        libevdev_free(kb);
        return NULL;
    }
    return kb;
}

static void begin_resize(struct libevdev_uinput *keyboard,
                         struct libevdev_uinput *mouse, bool *resizing)
{
    if (*resizing)
        return;
    *resizing = true;
    write_event(keyboard, EV_KEY, KEY_LEFTMETA, 1);
    sync_device(keyboard);
    write_event(mouse, EV_KEY, BTN_RIGHT, 1);
    sync_device(mouse);
    fprintf(stderr, "mouse-resize: Super down + right down\n");
}

static void end_resize(struct libevdev_uinput *keyboard,
                       struct libevdev_uinput *mouse, bool *resizing)
{
    if (!*resizing)
        return;
    *resizing = false;
    write_event(mouse, EV_KEY, BTN_RIGHT, 0);
    sync_device(mouse);
    write_event(keyboard, EV_KEY, KEY_LEFTMETA, 0);
    sync_device(keyboard);
}

static void handle_event(struct libevdev_uinput *keyboard,
                         struct libevdev_uinput *mouse,
                         const struct input_event *event,
                         int resize_button, bool *resizing)
{
    if (event->type == EV_KEY && event->code == resize_button) {
        if (event->value == 1)
            begin_resize(keyboard, mouse, resizing);
        else if (event->value == 0)
            end_resize(keyboard, mouse, resizing);
        return;
    }

    write_event(mouse, event->type, event->code, event->value);
}

int main(void)
{
    const char *device_path = getenv("DEVICE");
    if (!device_path || !*device_path)
        device_path = DEFAULT_DEVICE;

    int resize_button = parse_button(getenv("BUTTON"));
    if (resize_button < 0)
        return 2;

    int fd = open(device_path, O_RDONLY | O_NONBLOCK);
    if (fd < 0) {
        log_errno(device_path);
        return 1;
    }

    struct libevdev *source = NULL;
    int rc = libevdev_new_from_fd(fd, &source);
    if (rc < 0) {
        fprintf(stderr, "mouse-resize: libevdev_new_from_fd: %s\n", strerror(-rc));
        close(fd);
        return 1;
    }

    if (!libevdev_has_event_code(source, EV_KEY, resize_button)) {
        fprintf(stderr, "mouse-resize: %s does not expose button code %d\n",
                device_path, resize_button);
        libevdev_free(source);
        close(fd);
        return 1;
    }

    struct libevdev *mouse_clone = clone_device(source, resize_button);
    struct libevdev *keyboard_clone = create_keyboard();
    if (!mouse_clone || !keyboard_clone) {
        libevdev_free(mouse_clone);
        libevdev_free(keyboard_clone);
        libevdev_free(source);
        close(fd);
        return 1;
    }

    struct libevdev_uinput *mouse = NULL;
    struct libevdev_uinput *keyboard = NULL;
    rc = libevdev_uinput_create_from_device(keyboard_clone,
                                            LIBEVDEV_UINPUT_OPEN_MANAGED,
                                            &keyboard);
    if (rc < 0) {
        fprintf(stderr, "mouse-resize: cannot create virtual keyboard: %s\n",
                strerror(-rc));
        goto fail;
    }
    rc = libevdev_uinput_create_from_device(mouse_clone,
                                            LIBEVDEV_UINPUT_OPEN_MANAGED,
                                            &mouse);
    if (rc < 0) {
        fprintf(stderr, "mouse-resize: cannot create virtual mouse: %s\n",
                strerror(-rc));
        goto fail;
    }

    rc = libevdev_grab(source, LIBEVDEV_GRAB);
    if (rc < 0) {
        fprintf(stderr, "mouse-resize: cannot grab %s: %s\n", device_path,
                strerror(-rc));
        goto fail;
    }

    fprintf(stderr,
            "mouse-resize: %s button %d -> Super+right-drag "
            "(virtual keyboard + mouse)\n",
            device_path, resize_button);

    struct sigaction sa;
    memset(&sa, 0, sizeof(sa));
    sa.sa_handler = on_signal;
    sigemptyset(&sa.sa_mask);
    sigaction(SIGINT, &sa, NULL);
    sigaction(SIGTERM, &sa, NULL);

    bool resizing = false;
    struct pollfd pfd = {
        .fd = fd,
        .events = POLLIN,
    };

    while (!stop_requested) {
        int ready = poll(&pfd, 1, 1000);
        if (ready < 0) {
            if (errno == EINTR)
                continue;
            log_errno("poll");
            break;
        }
        if (ready == 0)
            continue;

        for (;;) {
            struct input_event event;
            rc = libevdev_next_event(source, LIBEVDEV_READ_FLAG_NORMAL, &event);
            if (rc == -EAGAIN)
                break;

            if (rc == LIBEVDEV_READ_STATUS_SYNC) {
                while (rc == LIBEVDEV_READ_STATUS_SYNC) {
                    handle_event(keyboard, mouse, &event, resize_button,
                                 &resizing);
                    rc = libevdev_next_event(source, LIBEVDEV_READ_FLAG_SYNC,
                                             &event);
                }
                continue;
            }

            if (rc < 0) {
                fprintf(stderr, "mouse-resize: read error: %s\n", strerror(-rc));
                goto shutdown;
            }

            handle_event(keyboard, mouse, &event, resize_button, &resizing);
        }
    }

shutdown:
    end_resize(keyboard, mouse, &resizing);
    libevdev_grab(source, LIBEVDEV_UNGRAB);
    if (mouse)
        libevdev_uinput_destroy(mouse);
    if (keyboard)
        libevdev_uinput_destroy(keyboard);
    libevdev_free(mouse_clone);
    libevdev_free(keyboard_clone);
    libevdev_free(source);
    close(fd);
    fprintf(stderr, "mouse-resize: stopped\n");
    return 0;

fail:
    if (mouse)
        libevdev_uinput_destroy(mouse);
    if (keyboard)
        libevdev_uinput_destroy(keyboard);
    libevdev_free(mouse_clone);
    libevdev_free(keyboard_clone);
    libevdev_free(source);
    close(fd);
    return 1;
}
