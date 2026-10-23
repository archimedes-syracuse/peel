pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Mango state for the shell. Mango exposes a small JSON IPC through mmsg;
// polling is deliberate here, matching the Niri backend's 800 ms cadence and
// keeping the bar logic identical on both compositors.
Singleton {
    id: root

    property var allTags: []
    property var focusedWindow: null
    property bool available: false
    property bool canPoll: false

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
        command: ["mmsg", "get", "focusing-client"]
        running: false
        stderr: StdioCollector {}
        stdout: StdioCollector {
            onStreamFinished: {
                const raw = text.trim();
                if (raw === "")
                    return;
                try {
                    const data = JSON.parse(raw);
                    if (data.id === null || data.id === undefined) {
                        root.focusedWindow = null;
                        return;
                    }
                    root.focusedWindow = {
                        app_id: data.appid || "",
                        title: data.title || ""
                    };
                } catch (e) {
                    root.focusedWindow = null;
                }
            }
        }
    }

    Timer {
        interval: 800
        running: root.canPoll
        repeat: true
        triggeredOnStart: true
        onTriggered: root.refresh()
    }
}
