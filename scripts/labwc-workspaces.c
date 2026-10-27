// labwc-workspaces: read and activate labwc workspaces through the standard
// ext-workspace-v1 protocol.
//
//   labwc-workspaces list              print a JSON array for Quickshell
//   labwc-workspaces activate <index>  switch to workspace 1..N
//   labwc-workspaces step <delta>      move relative to the active workspace
//
// Build with scripts/build-labwc-workspaces.sh.

#define _POSIX_C_SOURCE 200809L

#include <stdbool.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <wayland-client.h>

#include "ext-workspace-v1-client-protocol.h"

struct workspace {
    struct ext_workspace_handle_v1 *handle;
    char *id;
    char *name;
    uint32_t *coordinates;
    size_t coordinates_len;
    uint32_t state;
    uint32_t capabilities;
    unsigned int order;
    bool removed;
    struct workspace *next;
};

static struct wl_display *display;
static struct ext_workspace_manager_v1 *manager;
static struct workspace *workspaces;
static unsigned int next_order;
static bool done;

static void
workspace_handle_id(void *data, struct ext_workspace_handle_v1 *handle,
        const char *id)
{
    struct workspace *ws = data;
    (void)handle;
    free(ws->id);
    ws->id = id ? strdup(id) : NULL;
}

static void
workspace_handle_name(void *data, struct ext_workspace_handle_v1 *handle,
        const char *name)
{
    struct workspace *ws = data;
    (void)handle;
    free(ws->name);
    ws->name = name ? strdup(name) : NULL;
}

static void
workspace_handle_coordinates(void *data,
        struct ext_workspace_handle_v1 *handle, struct wl_array *coordinates)
{
    struct workspace *ws = data;
    (void)handle;
    free(ws->coordinates);
    ws->coordinates = NULL;
    ws->coordinates_len = 0;
    if (!coordinates || coordinates->size == 0) {
        return;
    }
    ws->coordinates = malloc(coordinates->size);
    if (!ws->coordinates) {
        return;
    }
    memcpy(ws->coordinates, coordinates->data, coordinates->size);
    ws->coordinates_len = coordinates->size / sizeof(uint32_t);
}

static void
workspace_handle_state(void *data, struct ext_workspace_handle_v1 *handle,
        uint32_t state)
{
    struct workspace *ws = data;
    (void)handle;
    ws->state = state;
}

static void
workspace_handle_capabilities(void *data,
        struct ext_workspace_handle_v1 *handle, uint32_t capabilities)
{
    struct workspace *ws = data;
    (void)handle;
    ws->capabilities = capabilities;
}

static void
workspace_handle_removed(void *data, struct ext_workspace_handle_v1 *handle)
{
    struct workspace *ws = data;
    (void)handle;
    ws->removed = true;
}

static const struct ext_workspace_handle_v1_listener workspace_listener = {
    .id = workspace_handle_id,
    .name = workspace_handle_name,
    .coordinates = workspace_handle_coordinates,
    .state = workspace_handle_state,
    .capabilities = workspace_handle_capabilities,
    .removed = workspace_handle_removed,
};

static void
group_capabilities(void *data, struct ext_workspace_group_handle_v1 *group,
        uint32_t capabilities)
{
    (void)data;
    (void)group;
    (void)capabilities;
}

static void
group_output_enter(void *data, struct ext_workspace_group_handle_v1 *group,
        struct wl_output *output)
{
    (void)data;
    (void)group;
    (void)output;
}

static void
group_output_leave(void *data, struct ext_workspace_group_handle_v1 *group,
        struct wl_output *output)
{
    (void)data;
    (void)group;
    (void)output;
}

static void
group_workspace_enter(void *data, struct ext_workspace_group_handle_v1 *group,
        struct ext_workspace_handle_v1 *workspace)
{
    (void)data;
    (void)group;
    (void)workspace;
}

static void
group_workspace_leave(void *data, struct ext_workspace_group_handle_v1 *group,
        struct ext_workspace_handle_v1 *workspace)
{
    (void)data;
    (void)group;
    (void)workspace;
}

static void
group_removed(void *data, struct ext_workspace_group_handle_v1 *group)
{
    (void)data;
    (void)group;
}

static const struct ext_workspace_group_handle_v1_listener group_listener = {
    .capabilities = group_capabilities,
    .output_enter = group_output_enter,
    .output_leave = group_output_leave,
    .workspace_enter = group_workspace_enter,
    .workspace_leave = group_workspace_leave,
    .removed = group_removed,
};

static void
manager_workspace_group(void *data, struct ext_workspace_manager_v1 *mgr,
        struct ext_workspace_group_handle_v1 *group)
{
    (void)data;
    (void)mgr;
    ext_workspace_group_handle_v1_add_listener(group, &group_listener, NULL);
}

static void
manager_workspace(void *data, struct ext_workspace_manager_v1 *mgr,
        struct ext_workspace_handle_v1 *handle)
{
    (void)data;
    (void)mgr;

    struct workspace *ws = calloc(1, sizeof(*ws));
    if (!ws) {
        return;
    }
    ws->handle = handle;
    ws->order = next_order++;
    ws->next = workspaces;
    workspaces = ws;
    ext_workspace_handle_v1_add_listener(handle, &workspace_listener, ws);
}

static void
manager_done(void *data, struct ext_workspace_manager_v1 *mgr)
{
    (void)data;
    (void)mgr;
    done = true;
}

static void
manager_finished(void *data, struct ext_workspace_manager_v1 *mgr)
{
    (void)data;
    (void)mgr;
    done = true;
}

static const struct ext_workspace_manager_v1_listener manager_listener = {
    .workspace_group = manager_workspace_group,
    .workspace = manager_workspace,
    .done = manager_done,
    .finished = manager_finished,
};

static void
registry_global(void *data, struct wl_registry *registry, uint32_t name,
        const char *interface, uint32_t version)
{
    (void)data;
    (void)version;

    if (!manager
            && strcmp(interface, ext_workspace_manager_v1_interface.name) == 0) {
        manager = wl_registry_bind(registry, name,
            &ext_workspace_manager_v1_interface, 1);
        if (manager) {
            ext_workspace_manager_v1_add_listener(manager,
                &manager_listener, NULL);
        }
    }
}

static void
registry_global_remove(void *data, struct wl_registry *registry, uint32_t name)
{
    (void)data;
    (void)registry;
    (void)name;
}

static const struct wl_registry_listener registry_listener = {
    .global = registry_global,
    .global_remove = registry_global_remove,
};

static int
compare_workspace(const void *a, const void *b)
{
    const struct workspace *wa = *(const struct workspace * const *)a;
    const struct workspace *wb = *(const struct workspace * const *)b;

    if (wa->coordinates_len > 0 && wb->coordinates_len > 0) {
        size_t n = wa->coordinates_len < wb->coordinates_len
            ? wa->coordinates_len : wb->coordinates_len;
        for (size_t i = 0; i < n; i++) {
            if (wa->coordinates[i] < wb->coordinates[i]) {
                return -1;
            }
            if (wa->coordinates[i] > wb->coordinates[i]) {
                return 1;
            }
        }
        if (wa->coordinates_len != wb->coordinates_len) {
            return wa->coordinates_len < wb->coordinates_len ? -1 : 1;
        }
    }

    if (wa->order < wb->order) {
        return -1;
    }
    if (wa->order > wb->order) {
        return 1;
    }
    return 0;
}

static struct workspace **
sorted_workspaces(size_t *count)
{
    size_t n = 0;
    for (struct workspace *ws = workspaces; ws; ws = ws->next) {
        if (!ws->removed) {
            n++;
        }
    }

    struct workspace **list = calloc(n ? n : 1, sizeof(*list));
    if (!list) {
        *count = 0;
        return NULL;
    }

    size_t i = 0;
    for (struct workspace *ws = workspaces; ws; ws = ws->next) {
        if (!ws->removed) {
            list[i++] = ws;
        }
    }
    qsort(list, n, sizeof(*list), compare_workspace);
    *count = n;
    return list;
}

static void
json_string(const char *value)
{
    fputc('"', stdout);
    if (value) {
        for (const unsigned char *p = (const unsigned char *)value; *p; p++) {
            switch (*p) {
            case '"':
                fputs("\\\"", stdout);
                break;
            case '\\':
                fputs("\\\\", stdout);
                break;
            case '\b':
                fputs("\\b", stdout);
                break;
            case '\f':
                fputs("\\f", stdout);
                break;
            case '\n':
                fputs("\\n", stdout);
                break;
            case '\r':
                fputs("\\r", stdout);
                break;
            case '\t':
                fputs("\\t", stdout);
                break;
            default:
                if (*p < 0x20) {
                    printf("\\u%04x", *p);
                } else {
                    fputc(*p, stdout);
                }
            }
        }
    }
    fputc('"', stdout);
}

static void
print_json(struct workspace **list, size_t count)
{
    fputc('[', stdout);
    for (size_t i = 0; i < count; i++) {
        const struct workspace *ws = list[i];
        if (i > 0) {
            fputc(',', stdout);
        }
        fputs("{\"id\":", stdout);
        json_string(ws->id ? ws->id : "");
        fputs(",\"name\":", stdout);
        json_string(ws->name ? ws->name : "");
        printf(",\"idx\":%zu,\"index\":%zu,\"is_active\":%s,"
            "\"is_urgent\":%s,\"is_hidden\":%s,\"client_count\":0}",
            i + 1, i + 1,
            (ws->state & EXT_WORKSPACE_HANDLE_V1_STATE_ACTIVE) ? "true" : "false",
            (ws->state & EXT_WORKSPACE_HANDLE_V1_STATE_URGENT) ? "true" : "false",
            (ws->state & EXT_WORKSPACE_HANDLE_V1_STATE_HIDDEN) ? "true" : "false");
    }
    fputs("]\n", stdout);
}

static int
activate_workspace(struct workspace *ws)
{
    if (!ws || ws->removed) {
        return 1;
    }
    ext_workspace_handle_v1_activate(ws->handle);
    ext_workspace_manager_v1_commit(manager);
    return wl_display_roundtrip(display) < 0 ? 1 : 0;
}

static void
cleanup(void)
{
    struct workspace *ws = workspaces;
    while (ws) {
        struct workspace *next = ws->next;
        free(ws->id);
        free(ws->name);
        free(ws->coordinates);
        free(ws);
        ws = next;
    }
    workspaces = NULL;
    if (display) {
        wl_display_disconnect(display);
        display = NULL;
    }
}

static void
usage(const char *program)
{
    fprintf(stderr,
        "usage: %s [list | activate <index> | step <delta>]\n", program);
}

int
main(int argc, char **argv)
{
    enum mode {
        MODE_LIST,
        MODE_ACTIVATE,
        MODE_STEP,
    } mode = MODE_LIST;
    long argument = 0;

    if (argc > 1) {
        if (strcmp(argv[1], "list") == 0) {
            mode = MODE_LIST;
        } else if (strcmp(argv[1], "activate") == 0 && argc > 2) {
            mode = MODE_ACTIVATE;
            argument = strtol(argv[2], NULL, 10);
        } else if (strcmp(argv[1], "step") == 0 && argc > 2) {
            mode = MODE_STEP;
            argument = strtol(argv[2], NULL, 10);
        } else if (strcmp(argv[1], "--help") == 0
                || strcmp(argv[1], "-h") == 0) {
            usage(argv[0]);
            return 0;
        } else {
            usage(argv[0]);
            return 2;
        }
    }

    display = wl_display_connect(NULL);
    if (!display) {
        fprintf(stderr, "labwc-workspaces: cannot connect to Wayland\n");
        return 1;
    }

    struct wl_registry *registry = wl_display_get_registry(display);
    if (!registry) {
        fprintf(stderr, "labwc-workspaces: cannot get registry\n");
        cleanup();
        return 1;
    }
    wl_registry_add_listener(registry, &registry_listener, NULL);

    for (int i = 0; i < 64 && !done; i++) {
        if (wl_display_roundtrip(display) < 0) {
            break;
        }
    }

    if (!manager) {
        fprintf(stderr,
            "labwc-workspaces: ext-workspace-v1 is not available\n");
        cleanup();
        return 1;
    }
    if (!done) {
        fprintf(stderr, "labwc-workspaces: no workspace update received\n");
        cleanup();
        return 1;
    }

    size_t count = 0;
    struct workspace **list = sorted_workspaces(&count);
    int rc = 1;

    if (mode == MODE_LIST) {
        print_json(list, count);
        rc = 0;
    } else if (mode == MODE_ACTIVATE) {
        if (argument >= 1 && (size_t)argument <= count) {
            rc = activate_workspace(list[argument - 1]);
        }
    } else {
        int active = -1;
        for (size_t i = 0; i < count; i++) {
            if (list[i]->state & EXT_WORKSPACE_HANDLE_V1_STATE_ACTIVE) {
                active = (int)i;
                break;
            }
        }
        if (count > 0) {
            long target;
            if (active >= 0) {
                target = ((long)active + argument) % (long)count;
                if (target < 0) {
                    target += (long)count;
                }
            } else {
                target = argument >= 0 ? 0 : (long)count - 1;
            }
            rc = activate_workspace(list[target]);
        }
    }

    free(list);
    cleanup();
    return rc;
}
