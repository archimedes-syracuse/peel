import QtQuick
import Quickshell
import Quickshell.Wayland
import "../theme"

// Compact full-width top bar, one layer-shell surface per monitor.
// Reference language: numeric workspaces, date · time · weather, metrics.
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

    Rectangle {
        anchors {
            left: parent.left
            right: parent.right
            bottom: parent.bottom
        }
        height: 1
        color: "#12ffffff"
    }

    Row {
        anchors.left: parent.left
        anchors.leftMargin: 14
        anchors.verticalCenter: parent.verticalCenter
        spacing: 10

        BarButton {
            glyph: Theme.gArch
            textColor: Theme.fg
            onClicked: Quickshell.execDetached(["qs", "-c", "niri", "ipc", "call", "shell", "toggleLauncher"])
        }

        Workspaces {}
    }

    Clock {
        anchors.centerIn: parent
    }

    Row {
        anchors.right: parent.right
        anchors.rightMargin: 10
        anchors.verticalCenter: parent.verticalCenter
        spacing: 3

        BarButton {
            glyph: Theme.gChevronLeft
            textColor: Theme.fgDim
            onClicked: Quickshell.execDetached(["qs", "-c", "niri", "ipc", "call", "shell", "toggleControl"])
        }

        Volume {}
        BrightnessIndicator {}
        DiskIndicator {}
        RamIndicator {}
        CpuIndicator {}

        BarButton {
            glyph: Theme.gBell
            textColor: Theme.fgDim
            onClicked: Quickshell.execDetached(["qs", "-c", "niri", "ipc", "call", "shell", "toggleNotifications"])
        }

        BarButton {
            glyph: Theme.gPower
            textColor: Theme.fgDim
            hoverColor: Theme.red
            onClicked: Quickshell.execDetached(["qs", "-c", "niri", "ipc", "call", "shell", "togglePower"])
        }
    }
}
