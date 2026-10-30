pragma Singleton

import QtQuick
import Quickshell

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
