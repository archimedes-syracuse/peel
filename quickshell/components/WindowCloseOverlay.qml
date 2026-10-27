import QtQuick
import Quickshell
import Quickshell.Wayland
import "../theme"
import "../services"

// A single square × floating just above the focused Mango window's top-right
// corner. Mango exposes window geometry through `mmsg get all-clients`; the
// rest of the shell works without compositor-specific window controls.
//
// The surface is masked to the button itself, so every other click goes
// straight through to the application underneath.
PanelWindow {
    id: root

    property var modelData

    readonly property var client: Mango.available ? Mango.focusedClient : null
    readonly property int barInset: 32
    readonly property bool hasClient: client !== null
        && client.is_focused
        && !client.is_fullscreen
        && client.width > 80
        && client.height > 80
        && (client.monitor === "" || client.monitor === modelData.name)

    screen: modelData
    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }
    color: "transparent"
    exclusiveZone: 0
    focusable: false
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    WlrLayershell.namespace: "niri-shell-window-close"

    mask: Region {
        item: closeButton
    }

    function closeFocused() {
        if (ToplevelManager.activeToplevel)
            ToplevelManager.activeToplevel.close();
        else
            Mango.dispatch("killclient");
    }

    Rectangle {
        id: closeButton

        width: root.hasClient ? 22 : 0
        height: root.hasClient ? 22 : 0
        x: root.hasClient
            ? Math.max(4, Math.min(root.width - 26, root.client.x + root.client.width - 27))
            : 0
        // Sit just above the window so the button does not cover app-drawn
        // close buttons or page content. Never put it under the top bar; when
        // the window is near the top, fall back to the inside edge.
        y: root.hasClient
            ? (root.client.y >= root.barInset + 26
                ? root.client.y - 26
                : Math.max(root.barInset + 5, root.client.y + 5))
            : 0
        color: closeHover.hovered ? Theme.red : Theme.deskPanel
        border.width: 1
        border.color: closeHover.hovered ? Theme.red : Theme.deskBorder
        radius: 0
        opacity: closeHover.hovered ? 1 : 0.92

        Behavior on color { ColorAnimation { duration: Theme.duration } }
        Behavior on opacity { NumberAnimation { duration: Theme.duration } }

        Text {
            anchors.centerIn: parent
            text: "\u00D7"
            color: closeHover.hovered ? Theme.deskText : Theme.deskHighlight
            font.family: Theme.font
            font.pixelSize: 15
            font.bold: true
        }

        HoverHandler {
            id: closeHover
            cursorShape: Qt.PointingHandCursor
        }

        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.LeftButton
            cursorShape: Qt.PointingHandCursor
            onClicked: root.closeFocused()
        }
    }
}
