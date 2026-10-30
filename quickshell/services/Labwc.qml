pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

Singleton {
    id: root

    readonly property bool available: (Quickshell.env("LABWC_PID") || "") !== ""

    property var workspaces: []

    readonly property var focusedWindow: ToplevelManager.activeToplevel
        ? {
            app_id: ToplevelManager.activeToplevel.appId || "",
            title: ToplevelManager.activeToplevel.title || ""
        }
        : null

    function tagsFor(monitorName) {
        return workspaces;
    }

    function focusIndex(idx) {
        Quickshell.execDetached(["labwc-workspaces", "activate", String(idx)]);
    }

    function workspaceUp() {
        Quickshell.execDetached(["labwc-workspaces", "step", "-1"]);
    }

    function workspaceDown() {
        Quickshell.execDetached(["labwc-workspaces", "step", "1"]);
    }

    function refresh() {
        if (!listProc.running)
            listProc.running = true;
    }

    Process {
        id: listProc
        command: ["labwc-workspaces", "list"]
        running: false
        stderr: StdioCollector {}
        stdout: StdioCollector {
            onStreamFinished: {
                const raw = text.trim();
                if (raw === "")
                    return;
                try {
                    const list = JSON.parse(raw);
                    if (Array.isArray(list))
                        root.workspaces = list;
                } catch (e) {
                }
            }
        }
    }

    Timer {
        interval: 800
        running: root.available
        repeat: true
        triggeredOnStart: true
        onTriggered: root.refresh()
    }
}
