// Button-triggered resize for the Razer Basilisk: holds Meta on a synthetic
// keyboard while cloning the mouse, since Mango only reads hard keyboard mods.
// Build: see scripts/install-razer-resize.sh.
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

static volatile sig_atomic_t stop_requested = 0;

static void on_signal(int sig)
{
    (void)sig;
    stop_requested = 1;
}

static void log_errno(const char *what)
{
    fprintf(stderr, "razer-resize: %s: %s\n", what, strerror(errno));
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

    fprintf(stderr, "razer-resize: unknown button '%s' (use BTN_SIDE or BTN_EXTRA)\n", value);
    return -1;
}

static struct libevdev *clone_device(struct libevdev *source)
{
    struct libevdev *clone = libevdev_new();
    if (!clone) {
        fprintf(stderr, "razer-resize: libevdev_new failed\n");
        return NULL;
    }

    const char *source_name = libevdev_get_name(source);
    char name[256];
    snprintf(name, sizeof(name), "%s resize helper",
             source_name ? source_name : "Razer Basilisk V3");
    libevdev_set_name(clone, name);
    libevdev_set_id_bustype(clone, libevdev_get_id_bustype(source));
    libevdev_set_id_vendor(clone, libevdev_get_id_vendor(source));
    libevdev_set_id_product(clone, libevdev_get_id_product(source));
    libevdev_set_id_version(clone, libevdev_get_id_version(source));

    for (unsigned int type = 0; type <= EV_MAX; type++) {
        if (!libevdev_has_event_type(source, type))
            continue;
        if (libevdev_enable_event_type(clone, type) < 0) {
            fprintf(stderr, "razer-resize: cannot enable event type %u\n", type);
            libevdev_free(clone);
            return NULL;
        }

        int max = libevdev_event_type_get_max(type);
        if (max < 0)
            continue;

        for (unsigned int code = 0; code <= (unsigned int)max; code++) {
            if (!libevdev_has_event_code(source, type, code))
                continue;

            const struct input_absinfo *abs = NULL;
            if (type == EV_ABS)
                abs = libevdev_get_abs_info(source, code);

            if (libevdev_enable_event_code(clone, type, code, abs) < 0) {
                fprintf(stderr, "razer-resize: cannot enable %u/%u\n", type, code);
                libevdev_free(clone);
                return NULL;
            }
        }
    }

    for (unsigned int prop = 0; prop <= INPUT_PROP_MAX; prop++) {
        if (libevdev_has_property(source, prop))
            libevdev_enable_property(clone, prop);
    }

    if (libevdev_enable_event_type(clone, EV_KEY) < 0 ||
        libevdev_enable_event_code(clone, EV_KEY, KEY_LEFTMETA, NULL) < 0) {
        fprintf(stderr, "razer-resize: cannot add KEY_LEFTMETA\n");
        libevdev_free(clone);
        return NULL;
    }

    return clone;
}

static void handle_event(struct libevdev_uinput *uidev,
                         const struct input_event *event,
                         int resize_button, bool *resizing)
{
    if (event->type == EV_KEY && event->code == resize_button) {
        if (event->value == 1) {
            if (!*resizing) {
                *resizing = true;
                write_event(uidev, EV_KEY, KEY_LEFTMETA, 1);
                sync_device(uidev);
                write_event(uidev, EV_KEY, BTN_RIGHT, 1);
                sync_device(uidev);
            }
            return;
        }

        if (event->value == 0) {
            if (*resizing) {
                *resizing = false;
                write_event(uidev, EV_KEY, BTN_RIGHT, 0);
                sync_device(uidev);
                write_event(uidev, EV_KEY, KEY_LEFTMETA, 0);
                sync_device(uidev);
            }
            return;
        }

        return;
    }

    write_event(uidev, event->type, event->code, event->value);
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
        fprintf(stderr, "razer-resize: libevdev_new_from_fd: %s\n", strerror(-rc));
        close(fd);
        return 1;
    }

    if (!libevdev_has_event_code(source, EV_KEY, resize_button)) {
        fprintf(stderr, "razer-resize: %s does not expose button code %d\n",
                device_path, resize_button);
        libevdev_free(source);
        close(fd);
        return 1;
    }

    struct libevdev *clone = clone_device(source);
    if (!clone) {
        libevdev_free(source);
        close(fd);
        return 1;
    }

    struct libevdev_uinput *uidev = NULL;
    rc = libevdev_uinput_create_from_device(clone, LIBEVDEV_UINPUT_OPEN_MANAGED, &uidev);
    if (rc < 0) {
        fprintf(stderr, "razer-resize: cannot create virtual mouse: %s\n", strerror(-rc));
        libevdev_free(clone);
        libevdev_free(source);
        close(fd);
        return 1;
    }

    rc = libevdev_grab(source, LIBEVDEV_GRAB);
    if (rc < 0) {
        fprintf(stderr, "razer-resize: cannot grab %s: %s\n", device_path, strerror(-rc));
        libevdev_uinput_destroy(uidev);
        libevdev_free(clone);
        libevdev_free(source);
        close(fd);
        return 1;
    }

    fprintf(stderr, "razer-resize: %s -> button %d -> Meta+right-drag\n",
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
                do {
                    handle_event(uidev, &event, resize_button, &resizing);
                    rc = libevdev_next_event(source, LIBEVDEV_READ_FLAG_SYNC, &event);
                } while (rc == LIBEVDEV_READ_STATUS_SYNC);

                if (rc == -EAGAIN)
                    break;
                if (rc != LIBEVDEV_READ_STATUS_SUCCESS) {
                    fprintf(stderr, "razer-resize: sync read: %s\n", strerror(-rc));
                    stop_requested = 1;
                    break;
                }
                handle_event(uidev, &event, resize_button, &resizing);
            } else if (rc == LIBEVDEV_READ_STATUS_SUCCESS) {
                handle_event(uidev, &event, resize_button, &resizing);
            } else {
                fprintf(stderr, "razer-resize: read: %s\n", strerror(-rc));
                stop_requested = 1;
                break;
            }
        }
    }

    libevdev_uinput_destroy(uidev);
    libevdev_free(clone);
    libevdev_free(source);
    close(fd);

    fprintf(stderr, "razer-resize: stopped\n");
    return 0;
}
