import QtQuick
import Quickshell
import Quickshell.Wayland
import "../theme"

// Floating top bar, one layer-shell surface per monitor.
PanelWindow {
    id: root

    property var modelData

    screen: modelData
    anchors {
        top: true
        left: true
        right: true
    }
    margins {
        top: Theme.gap
        left: Theme.gap
        right: Theme.gap
    }
    implicitHeight: Theme.barHeight
    exclusiveZone: Theme.barHeight + Theme.gap
    color: "transparent"
    WlrLayershell.namespace: "niri-shell-bar"

    Rectangle {
        id: bg

        anchors.fill: parent
        radius: Theme.radius
        color: Theme.bgBar
        border.width: 1
        border.color: Theme.border
        opacity: 0
        Component.onCompleted: opacity = 1
        Behavior on opacity { NumberAnimation { duration: 450; easing.type: Easing.OutCubic } }

        // thin gradient hairline along the bottom edge
        Rectangle {
            anchors {
                left: parent.left
                right: parent.right
                bottom: parent.bottom
                margins: 1
            }
            height: 1
            radius: 1
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0.0; color: "transparent" }
                GradientStop { position: 0.25; color: Theme.accent }
                GradientStop { position: 0.50; color: Theme.accent2 }
                GradientStop { position: 0.75; color: Theme.accent }
                GradientStop { position: 1.0; color: "transparent" }
            }
        }
    }

    // left
    Row {
        anchors.left: bg.left
        anchors.leftMargin: 8
        anchors.verticalCenter: bg.verticalCenter
        spacing: 4

        BarButton {
            glyph: Theme.gApps
            onClicked: Quickshell.execDetached(["qs", "-c", "niri", "ipc", "call", "shell", "toggleLauncher"])
        }

        Rectangle {
            width: 1
            height: 16
            color: Theme.border
            anchors.verticalCenter: parent.verticalCenter
        }

        Workspaces {}

        Rectangle {
            width: 1
            height: 16
            color: Theme.border
            anchors.verticalCenter: parent.verticalCenter
        }

        ActiveWindow {}
    }

    Clock {
        anchors.centerIn: bg
    }

    // right
    Row {
        anchors.right: bg.right
        anchors.rightMargin: 7
        anchors.verticalCenter: bg.verticalCenter
        spacing: 2

        SysMeters {}

        Rectangle {
            width: 1
            height: 16
            color: Theme.border
            anchors.verticalCenter: parent.verticalCenter
        }

        Volume {}
        NetworkIndicator {}
        BluetoothIndicator {}
        BatteryIndicator {}
        Tray {}

        Rectangle {
            width: 1
            height: 16
            color: Theme.border
            anchors.verticalCenter: parent.verticalCenter
        }

        BarButton {
            glyph: Theme.gPower
            onClicked: Quickshell.execDetached(["qs", "-c", "niri", "ipc", "call", "shell", "togglePower"])
        }
    }
}
