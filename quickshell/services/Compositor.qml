pragma Singleton

import QtQuick
import Quickshell

// One façade so the shell works on Labwc, Mango, and Niri. Labwc is the
// primary session now; Mango and Niri remain selectable at the login screen.
// Each backend reports availability from its own environment/IPC probe, so no
// compositor-specific branch is needed in the bar components.
Singleton {
    id: root

    readonly property bool isLabwc: Labwc.available
    readonly property bool isMango: Mango.available
    readonly property bool available: Labwc.available || Mango.available || Niri.available

    function tagsFor(monitorName) {
        if (Labwc.available)
            return Labwc.tagsFor(monitorName);

        if (Mango.available)
            return Mango.tagsFor(monitorName);

        if (!monitorName || monitorName === "")
            return Niri.workspaces;

        return Niri.workspaces.filter(w => w.output === monitorName);
    }

    function focusTag(idx, monitorName) {
        if (Labwc.available) {
            Labwc.focusIndex(idx);
            return;
        }
        if (Mango.available) {
            Mango.viewTagOn(monitorName, idx);
            return;
        }
        Niri.focusWorkspace(idx);
    }

    function workspaceUp() {
        if (Labwc.available) {
            Labwc.workspaceUp();
            return;
        }
        if (Mango.available) {
            Mango.workspaceUp();
            return;
        }
        Niri.workspaceUp();
    }

    function workspaceDown() {
        if (Labwc.available) {
            Labwc.workspaceDown();
            return;
        }
        if (Mango.available) {
            Mango.workspaceDown();
            return;
        }
        Niri.workspaceDown();
    }

    readonly property var focusedWindow: Labwc.available
        ? Labwc.focusedWindow
        : Mango.available
            ? Mango.focusedWindow
            : Niri.focusedWindow
}
