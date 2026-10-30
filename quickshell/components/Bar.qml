import QtQuick
import Quickshell
import Quickshell.Wayland
import "../theme"
import "../components"
import "../services"

PanelWindow {
    id: root

    property var modelData

    screen: modelData
    anchors {
        top: true
        bottom: true
        right: true
    }
    implicitWidth: Theme.barWidth
    exclusiveZone: Theme.barWidth
    color: "transparent"
    WlrLayershell.namespace: "niri-shell-bar"

    Rectangle {
        id: rail

        anchors {
            top: parent.top
            bottom: parent.bottom
            right: parent.right
            topMargin: 6
            bottomMargin: 6
            rightMargin: 3
        }
        width: Theme.barWidth - 6
        radius: 8
        color: Theme.bgBar
        border.width: 2
        border.color: Theme.accent
        clip: true

        Column {
            id: topGroup

            anchors {
                top: parent.top
                topMargin: 4
                horizontalCenter: parent.horizontalCenter
            }
            spacing: 2

            BarButton {
                vertical: true
                bordered: true
                glyph: Theme.gArch
                textColor: Theme.fg
                onClicked: Quickshell.execDetached(["qs", "-c", "niri", "ipc", "call", "shell", "toggleLauncher"])
            }

            Rectangle {
                anchors.horizontalCenter: parent.horizontalCenter
                width: 18
                height: 1
                color: Theme.border
            }

            Workspaces {
                monitorName: root.modelData ? root.modelData.name : ""
            }

            Rectangle {
                anchors.horizontalCenter: parent.horizontalCenter
                width: 18
                height: 1
                color: Theme.border
            }

            CpuIndicator { vertical: true }
            RamIndicator { vertical: true }
            DiskIndicator { vertical: true }
        }

        Column {
            id: bottomGroup

            anchors {
                bottom: parent.bottom
                bottomMargin: 4
                horizontalCenter: parent.horizontalCenter
            }
            spacing: 2

            Volume { vertical: true }
            BrightnessIndicator { vertical: true }

            BarButton {
                vertical: true
                glyph: Theme.gBell
                textColor: Theme.fgDim
                onClicked: Quickshell.execDetached(["qs", "-c", "niri", "ipc", "call", "shell", "toggleNotifications"])
            }

            Rectangle {
                anchors.horizontalCenter: parent.horizontalCenter
                width: 18
                height: 1
                color: Theme.border
            }

            Clock {}

            Rectangle {
                anchors.horizontalCenter: parent.horizontalCenter
                width: 18
                height: 1
                color: Theme.border
            }

            BarButton {
                vertical: true
                glyph: Theme.gPower
                textColor: Theme.fgDim
                hoverColor: Theme.red
                onClicked: Quickshell.execDetached(["qs", "-c", "niri", "ipc", "call", "shell", "togglePower"])
            }
        }
    }
}
