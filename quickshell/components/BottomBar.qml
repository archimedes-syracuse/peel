import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import "../theme"
import "../components"
import "../services"

// Bottom taskbar: the reference desktop's anchor. Pinned launchers and
// workspaces live on the left, windows in the middle, system/clock on the
// right. The old right rail remains available in Bar.qml for comparison.
PanelWindow {
    id: root

    property var modelData

    screen: modelData
    anchors {
        left: true
        right: true
        bottom: true
    }
    implicitHeight: Theme.taskbarHeight
    exclusiveZone: Theme.taskbarHeight
    color: "transparent"
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.namespace: "niri-shell-taskbar"

    Rectangle {
        anchors.fill: parent
        anchors.margins: 4
        color: Theme.deskPanel
        border.width: 1
        border.color: Theme.deskBorder
        radius: 3

        Rectangle {
            anchors {
                left: parent.left
                right: parent.right
                top: parent.top
                leftMargin: 1
                rightMargin: 1
            }
            height: 1
            color: Theme.deskHighlight
            opacity: 0.35
        }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 6
            anchors.rightMargin: 7
            spacing: 4

            TaskbarButton {
                glyph: Theme.gArch
                tint: Theme.accent
                onClicked: Quickshell.execDetached(["qs", "-c", "niri", "ipc", "call", "shell", "toggleLauncher"])
            }

            Rectangle {
                Layout.preferredWidth: 1
                Layout.preferredHeight: 16
                Layout.alignment: Qt.AlignVCenter
                color: Theme.deskBorder
                opacity: 0.55
            }

            TaskbarButton {
                glyph: Theme.gTerminal
                tint: Theme.green
                onClicked: Quickshell.execDetached(["alacritty"])
            }

            TaskbarButton {
                glyph: Theme.gApps
                tint: Theme.deskBlue
                onClicked: Quickshell.execDetached(["librewolf"])
            }

            TaskbarButton {
                glyph: Theme.gTerminal
                tint: Theme.yellow
                onClicked: Quickshell.execDetached(["alacritty", "-e", "opencode"])
            }

            TaskbarButton {
                glyph: Theme.gDisk
                tint: Theme.deskTextDim
                onClicked: Quickshell.execDetached(["nautilus"])
            }

            Rectangle {
                Layout.preferredWidth: 1
                Layout.preferredHeight: 16
                Layout.alignment: Qt.AlignVCenter
                color: Theme.deskBorder
                opacity: 0.55
            }

            WorkspaceStrip {
                monitorName: root.modelData ? root.modelData.name : ""
                Layout.alignment: Qt.AlignVCenter
            }

            Rectangle {
                Layout.preferredWidth: 1
                Layout.preferredHeight: 16
                Layout.alignment: Qt.AlignVCenter
                color: Theme.deskBorder
                opacity: 0.55
            }

            TaskList {
                Layout.fillWidth: true
                Layout.minimumWidth: 0
                Layout.preferredHeight: 24
                Layout.alignment: Qt.AlignVCenter
            }

            Tray {
                Layout.alignment: Qt.AlignVCenter
            }

            Volume {
                Layout.alignment: Qt.AlignVCenter
            }

            TaskbarClock {
                Layout.alignment: Qt.AlignVCenter
            }

            BarButton {
                glyph: Theme.gSettings
                textColor: Theme.deskTextDim
                onClicked: Quickshell.execDetached(["qs", "-c", "niri", "ipc", "call", "shell", "toggleControl"])
            }

            BarButton {
                glyph: Theme.gBell
                textColor: Theme.deskTextDim
                onClicked: Quickshell.execDetached(["qs", "-c", "niri", "ipc", "call", "shell", "toggleNotifications"])
            }

            BarButton {
                glyph: Theme.gPower
                textColor: Theme.deskTextDim
                hoverColor: Theme.red
                onClicked: Quickshell.execDetached(["qs", "-c", "niri", "ipc", "call", "shell", "togglePower"])
            }
        }
    }
}
