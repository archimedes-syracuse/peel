import QtQuick
import Quickshell
import Quickshell.Wayland
import "../theme"

// Compact full-width top bar, one layer-shell surface per monitor.
// Reference language: no floating card, no pill containers, accent-as-state.
PanelWindow {
    id: root

    property var modelData

    screen: modelData
    anchors {
        top: true
        left: true
        right: true
    }
    implicitHeight: Theme.barHeight
    exclusiveZone: Theme.barHeight
    color: "transparent"
    WlrLayershell.namespace: "niri-shell-bar"

    Rectangle {
        anchors.fill: parent
        color: Theme.bgBar
    }

    // Left: only the workspace indicator. Launcher stays on Super+D.
    Row {
        anchors.left: parent.left
        anchors.leftMargin: 12
        anchors.verticalCenter: parent.verticalCenter
        spacing: 10

        Workspaces {}
    }

    // Center: date › time.
    Clock {
        anchors.centerIn: parent
    }

    // Right: quiet system glyphs, tray, session.
    Row {
        anchors.right: parent.right
        anchors.rightMargin: 8
        anchors.verticalCenter: parent.verticalCenter
        spacing: 1

        Volume {}
        NetworkIndicator {}
        BluetoothIndicator {}
        BatteryIndicator {}
        Tray {}

        BarButton {
            glyph: Theme.gPower
            textColor: Theme.fgDim
            onClicked: Quickshell.execDetached(["qs", "-c", "niri", "ipc", "call", "shell", "togglePower"])
        }
    }
}
