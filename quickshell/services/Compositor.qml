pragma Singleton

import QtQuick
import Quickshell

// One façade so the shell works on Mango, Labwc, and Niri. Mango is the
// primary session; Labwc and Niri remain selectable at the login screen.
// Each backend reports availability from its own environment/IPC probe, so no
// compositor-specific branch is needed in the bar components.
Singleton {
    id: root

    readonly property bool isLabwc: Labwc.available
    readonly property bool isMango: Mango.available
    readonly property bool available: Mango.available || Labwc.available || Niri.available

    function tagsFor(monitorName) {
        if (Mango.available)
            return Mango.tagsFor(monitorName);

        if (Labwc.available)
            return Labwc.tagsFor(monitorName);

        if (!monitorName || monitorName === "")
            return Niri.workspaces;

        return Niri.workspaces.filter(w => w.output === monitorName);
    }

    function focusTag(idx, monitorName) {
        if (Mango.available) {
            Mango.viewTagOn(monitorName, idx);
            return;
        }
        if (Labwc.available) {
            Labwc.focusIndex(idx);
            return;
        }
        Niri.focusWorkspace(idx);
    }

    function workspaceUp() {
        if (Mango.available) {
            Mango.workspaceUp();
            return;
        }
        if (Labwc.available) {
            Labwc.workspaceUp();
            return;
        }
        Niri.workspaceUp();
    }

    function workspaceDown() {
        if (Mango.available) {
            Mango.workspaceDown();
            return;
        }
        if (Labwc.available) {
            Labwc.workspaceDown();
            return;
        }
        Niri.workspaceDown();
    }

    readonly property var focusedWindow: Mango.available
        ? Mango.focusedWindow
        : Labwc.available
            ? Labwc.focusedWindow
            : Niri.focusedWindow
}
