pragma Singleton

import QtQuick
import Quickshell

// One small façade so the shell works on both compositors. The Mango branch is
// primary, but the Niri session remains selectable at the login screen. Mango
// and Niri each report availability from their own IPC probes; no compositor
// environment variable is required in QML.
Singleton {
    id: root

    readonly property bool isMango: Mango.available
    readonly property bool available: Mango.available || Niri.available

    function tagsFor(monitorName) {
        if (Mango.available)
            return Mango.tagsFor(monitorName);

        if (!monitorName || monitorName === "")
            return Niri.workspaces;

        return Niri.workspaces.filter(w => w.output === monitorName);
    }

    function focusTag(idx, monitorName) {
        if (Mango.available) {
            Mango.viewTagOn(monitorName, idx);
            return;
        }
        Niri.focusWorkspace(idx);
    }

    function workspaceUp() {
        if (Mango.available) {
            Mango.workspaceUp();
            return;
        }
        Niri.workspaceUp();
    }

    function workspaceDown() {
        if (Mango.available) {
            Mango.workspaceDown();
            return;
        }
        Niri.workspaceDown();
    }

    readonly property var focusedWindow: Mango.available
        ? Mango.focusedWindow
        : Niri.focusedWindow
}
