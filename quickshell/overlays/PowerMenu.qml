import QtQuick
import Quickshell
import Quickshell.Wayland
import "../theme"
import "../components"

// Session menu: lock, suspend, logout, reboot, shutdown.
PanelWindow {
    id: root

    visible: false
    color: "transparent"
    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }
    exclusiveZone: 0
    focusable: true
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
    WlrLayershell.namespace: "niri-shell-power"

    function open() {
        visible = true;
    }

    function close() {
        visible = false;
    }

    function toggle() {
        if (visible)
            close();
        else
            open();
    }

    function run(cmd) {
        Quickshell.execDetached(cmd);
        close();
    }

    onVisibleChanged: {
        if (visible) {
            card.scale = 0.98;
            card.opacity = 0;
            intro.restart();
        }
    }

    Shortcut {
        sequence: "Escape"
        onActivated: root.close()
    }

    Rectangle {
        anchors.fill: parent
        color: "#66070a10"

        MouseArea {
            anchors.fill: parent
            onClicked: root.close()
        }
    }

    GlassPanel {
        id: card

        width: 300
        implicitHeight: column.implicitHeight + 22
        anchors.centerIn: parent
        radius: Theme.radius
        borderWidth: 1

        MouseArea { anchors.fill: parent }

        ParallelAnimation {
            id: intro
            NumberAnimation { target: card; property: "scale"; to: 1; duration: 160; easing.type: Easing.OutCubic }
            NumberAnimation { target: card; property: "opacity"; to: 1; duration: 120 }
        }

        Column {
            id: column
            anchors.fill: parent
            anchors.margins: 10
            spacing: 2

            Text {
                text: "session"
                color: Theme.accent
                font.family: Theme.font
                font.pixelSize: Theme.size
                leftPadding: 8
                bottomPadding: 6
            }

            Repeater {
                model: [
                    { glyph: Theme.gLock,     label: "lock",     cmd: ["swaylock", "-f"] },
                    { glyph: Theme.gSuspend,  label: "suspend",  cmd: ["systemctl", "suspend"] },
                    { glyph: Theme.gLogout,   label: "logout",   cmd: ["sh", "-c", "niri msg action quit --skip-confirmation 2>/dev/null || loginctl terminate-user \"$USER\""] },
                    { glyph: Theme.gReboot,   label: "reboot",   cmd: ["systemctl", "reboot"] },
                    { glyph: Theme.gShutdown, label: "shutdown", cmd: ["systemctl", "poweroff"] }
                ]

                Rectangle {
                    width: column.width
                    height: 34
                    radius: Theme.radius
                    color: hover.hovered ? Theme.accentSoft : "transparent"

                    Behavior on color { ColorAnimation { duration: Theme.duration } }

                    Rectangle {
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        width: 2
                        height: parent.height - 8
                        radius: 1
                        color: Theme.accent
                        visible: hover.hovered
                    }

                    Row {
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.left: parent.left
                        anchors.leftMargin: 10
                        spacing: 10

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: modelData.glyph
                            color: modelData.label === "reboot" || modelData.label === "shutdown" ? Theme.red : Theme.fg
                            font.family: Theme.font
                            font.pixelSize: Theme.iconSize
                        }

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: modelData.label
                            color: modelData.label === "reboot" || modelData.label === "shutdown" ? Theme.red : Theme.fg
                            font.family: Theme.font
                            font.pixelSize: Theme.size
                        }
                    }

                    HoverHandler {
                        id: hover
                        cursorShape: Qt.PointingHandCursor
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.run(modelData.cmd)
                    }
                }
            }
        }
    }
}
