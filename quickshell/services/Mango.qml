pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Mango state for the shell. Mango exposes a small JSON IPC through mmsg;
// polling is deliberate here, matching the Niri backend's cadence and keeping
// the bar logic identical on both compositors. The clients snapshot carries
// geometry as well, which the floating close control uses.
Singleton {
    id: root

    property var allTags: []
    property var allClients: []
    property var focusedWindow: null
    property var focusedClient: null
    property bool available: false
    property bool canPoll: false

    // Keep floating windows below the top bar. Tiled windows receive the
    // layer-shell exclusive zone automatically; floating windows do not.
    readonly property int barInset: Widgets.barVisible ? 32 : 0
    property int lastClampClientId: -1

    function tagsFor(monitorName) {
        for (let i = 0; i < allTags.length; i++) {
            const entry = allTags[i];
            if (!monitorName || entry.monitor === monitorName)
                return entry.tags || [];
        }
        return allTags.length > 0 ? (allTags[0].tags || []) : [];
    }

    function refresh() {
        if (!tagsProc.running)
            tagsProc.running = true;
        if (!windowProc.running)
            windowProc.running = true;
    }

    function dispatch(name, params) {
        const command = params === undefined || params === ""
            ? name
            : name + "," + params;
        Quickshell.execDetached(["mmsg", "dispatch", command]);
    }

    function viewTag(idx) {
        dispatch("view", String(idx));
    }

    function viewTagOn(monitorName, idx) {
        if (monitorName && monitorName !== "")
            dispatch("viewcrossmon", String(idx) + "," + monitorName);
        else
            viewTag(idx);
    }

    function workspaceUp() {
        dispatch("viewtoleft", "0");
    }

    function workspaceDown() {
        dispatch("viewtoright", "0");
    }

    Process {
        id: probeProc
        command: ["sh", "-c", "[ -n \"$MANGO_INSTANCE_SIGNATURE\" ] && command -v mmsg >/dev/null 2>&1"]
        running: true
        onExited: (exitCode, exitStatus) => {
            if (exitCode === 0) {
                root.canPoll = true;
                root.refresh();
            }
        }
    }

    Process {
        id: tagsProc
        command: ["mmsg", "get", "all-tags"]
        running: false
        stderr: StdioCollector {}
        stdout: StdioCollector {
            onStreamFinished: {
                const raw = text.trim();
                if (raw === "")
                    return;
                try {
                    const data = JSON.parse(raw);
                    if (Array.isArray(data.all_tags)) {
                        root.allTags = data.all_tags;
                        root.available = true;
                    }
                } catch (e) {
                    root.available = false;
                }
            }
        }
        onExited: (exitCode, exitStatus) => {
            if (exitCode !== 0)
                root.available = false;
        }
    }

    Process {
        id: windowProc
        command: ["mmsg", "get", "all-clients"]
        running: false
        stderr: StdioCollector {}
        stdout: StdioCollector {
            onStreamFinished: {
                const raw = text.trim();
                if (raw === "")
                    return;
                try {
                    const data = JSON.parse(raw);
                    const clients = Array.isArray(data.clients) ? data.clients : [];
                    root.allClients = clients;

                    let focused = null;
                    for (let i = 0; i < clients.length; i++) {
                        const client = clients[i];
                        if (client.is_focused && client.is_visible && !client.is_minimized) {
                            focused = client;
                            break;
                        }
                    }

                    root.focusedClient = focused;
                    root.focusedWindow = focused
                        ? {
                            app_id: focused.appid || "",
                            title: focused.title || "",
                            id: focused.id,
                            x: focused.x,
                            y: focused.y,
                            width: focused.width,
                            height: focused.height
                        }
                        : null;

                    if (!focused || focused.y >= root.barInset || focused.is_fullscreen) {
                        if (root.lastClampClientId !== -1)
                            root.lastClampClientId = -1;
                    } else if (focused
                            && focused.is_floating
                            && !focused.is_fullscreen
                            && !focused.is_maximized
                            && root.lastClampClientId !== focused.id) {
                        root.lastClampClientId = focused.id;
                        root.dispatch("movewin", "+0,+" + (root.barInset - focused.y) + ",client," + focused.id);
                    }
                } catch (e) {
                    root.allClients = [];
                    root.focusedClient = null;
                    root.focusedWindow = null;
                }
            }
        }
    }

    Timer {
        interval: 500
        running: root.canPoll
        repeat: true
        triggeredOnStart: true
        onTriggered: root.refresh()
    }
}
