pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Niri state for the shell. Quickshell 0.3.2 has no native Niri service,
// so we poll the compositor's JSON IPC. 800 ms is fast enough for the bar
// and much cheaper than an event-stream parser while the shell is young.
Singleton {
    id: root

    property var workspaces: []
    property var focusedWindow: null
    property bool available: false

    readonly property int focusedIndex: {
        for (let i = 0; i < workspaces.length; i++) {
            if (workspaces[i].is_focused)
                return workspaces[i].idx;
        }
        for (let i = 0; i < workspaces.length; i++) {
            if (workspaces[i].is_active)
                return workspaces[i].idx;
        }
        return 1;
    }

    function refresh() {
        if (!workspacesProc.running)
            workspacesProc.running = true;
        if (!windowProc.running)
            windowProc.running = true;
    }

    function focusWorkspace(idx) {
        Quickshell.execDetached(["niri", "msg", "action", "focus-workspace", String(idx)]);
    }

    function workspaceUp() {
        Quickshell.execDetached(["niri", "msg", "action", "focus-workspace-up"]);
    }

    function workspaceDown() {
        Quickshell.execDetached(["niri", "msg", "action", "focus-workspace-down"]);
    }

    Process {
        id: workspacesProc
        command: ["niri", "msg", "--json", "workspaces"]
        running: false
        stderr: StdioCollector {}
        stdout: StdioCollector {
            onStreamFinished: {
                const raw = text.trim();
                if (raw === "")
                    return;
                try {
                    const list = JSON.parse(raw);
                    if (Array.isArray(list)) {
                        root.workspaces = list;
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
        command: ["niri", "msg", "--json", "focused-window"]
        running: false
        stderr: StdioCollector {}
        stdout: StdioCollector {
            onStreamFinished: {
                const raw = text.trim();
                if (raw === "" || raw === "null") {
                    root.focusedWindow = null;
                    return;
                }
                try {
                    root.focusedWindow = JSON.parse(raw);
                } catch (e) {
                    root.focusedWindow = null;
                }
            }
        }
    }

    Timer {
        interval: 800
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.refresh()
    }
}
