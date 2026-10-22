import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Pipewire
import "../theme"
import "../components"
import "../services"

// Compact system drawer behind the chevron in the bar. Keeps the bar clean
// while preserving quick access to networking, Bluetooth, and power state.
PanelWindow {
    id: root

    readonly property var sink: Pipewire.defaultAudioSink
    readonly property var audio: sink ? sink.audio : null
    readonly property real volume: audio ? audio.volume : 0

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
    WlrLayershell.namespace: "niri-shell-control-center"

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
        color: "#33070a10"

        MouseArea {
            anchors.fill: parent
            onClicked: root.close()
        }
    }

    GlassPanel {
        id: card

        width: 300
        anchors {
            top: parent.top
            right: parent.right
            topMargin: Theme.barHeight + 8
            rightMargin: 8
        }
        implicitHeight: content.implicitHeight + 20
        radius: 6
        borderWidth: 2

        MouseArea { anchors.fill: parent }

        ParallelAnimation {
            id: intro
            NumberAnimation { target: card; property: "scale"; to: 1; duration: 160; easing.type: Easing.OutCubic }
            NumberAnimation { target: card; property: "opacity"; to: 1; duration: 120 }
        }

        Column {
            id: content
            anchors.fill: parent
            anchors.margins: 10
            spacing: 6

            Item {
                width: parent.width
                height: 20

                Text {
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    text: "system"
                    color: Theme.accent
                    font.family: Theme.font
                    font.pixelSize: Theme.size
                }

                Text {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    text: "niri"
                    color: Theme.fgDim
                    font.family: Theme.font
                    font.pixelSize: Theme.sizeSmall
                }
            }

            Rectangle {
                width: parent.width
                height: 1
                color: Theme.border
            }

            Item {
                width: parent.width
                height: 34

                Text {
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    text: Network.kind === "wifi" ? Theme.gWifi : Network.kind === "ethernet" ? Theme.gLan : Theme.gOffline
                    color: Network.online ? Theme.fg : Theme.fgDim
                    font.family: Theme.font
                    font.pixelSize: Theme.iconSize
                }

                Column {
                    anchors.left: parent.left
                    anchors.leftMargin: 26
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 1

                    Text {
                        text: "network"
                        color: Theme.fgDim
                        font.family: Theme.font
                        font.pixelSize: Theme.sizeSmall
                    }

                    Text {
                        width: parent.width
                        text: Network.online ? Network.conn : "offline"
                        color: Network.online ? Theme.fg : Theme.fgDim
                        font.family: Theme.font
                        font.pixelSize: Theme.size
                        elide: Text.ElideRight
                    }
                }
            }

            Item {
                width: parent.width
                height: 34

                Text {
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    text: Theme.gBluetooth
                    color: Bluetooth.powered ? Theme.blue : Theme.fgDim
                    font.family: Theme.font
                    font.pixelSize: Theme.iconSize
                }

                Column {
                    anchors.left: parent.left
                    anchors.leftMargin: 26
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 1

                    Text {
                        text: "bluetooth"
                        color: Theme.fgDim
                        font.family: Theme.font
                        font.pixelSize: Theme.sizeSmall
                    }

                    Text {
                        width: parent.width
                        text: !Bluetooth.available ? "unavailable"
                            : Bluetooth.powered
                                ? "on" + (Bluetooth.connectedCount > 0 ? " · " + Bluetooth.connectedCount + " connected" : "")
                                : "off"
                        color: Bluetooth.powered ? Theme.fg : Theme.fgDim
                        font.family: Theme.font
                        font.pixelSize: Theme.size
                        elide: Text.ElideRight
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (Bluetooth.available)
                            Bluetooth.setPowered(!Bluetooth.powered);
                    }
                }
            }

            Item {
                width: parent.width
                height: 34

                Text {
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    text: Battery.charging ? Theme.gCharging
                        : Battery.pct > 90 ? Theme.gBattFull
                        : Battery.pct > 60 ? Theme.gBattThree
                        : Battery.pct > 35 ? Theme.gBattHalf
                        : Battery.pct > 15 ? Theme.gBattQuarter
                        : Theme.gBattEmpty
                    color: Battery.low ? Theme.red : Battery.charging ? Theme.green : Theme.fg
                    font.family: Theme.font
                    font.pixelSize: Theme.iconSize
                }

                Column {
                    anchors.left: parent.left
                    anchors.leftMargin: 26
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 1

                    Text {
                        text: "battery"
                        color: Theme.fgDim
                        font.family: Theme.font
                        font.pixelSize: Theme.sizeSmall
                    }

                    Text {
                        width: parent.width
                        text: Battery.present ? Battery.pct + "% · " + (Battery.status || "unknown") : "not present"
                        color: Battery.low ? Theme.red : Theme.fg
                        font.family: Theme.font
                        font.pixelSize: Theme.size
                        elide: Text.ElideRight
                    }
                }
            }

            Rectangle {
                width: parent.width
                height: 1
                color: Theme.border
            }

            Item {
                width: parent.width
                height: 16

                Text {
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    text: "volume"
                    color: Theme.fgDim
                    font.family: Theme.font
                    font.pixelSize: Theme.sizeSmall
                }

                Text {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.audio ? (root.audio.muted ? "off" : Math.round(root.volume * 100) + "%") : "--"
                    color: Theme.fg
                    font.family: Theme.font
                    font.pixelSize: Theme.sizeSmall
                }
            }

            Item {
                id: volumeTrack
                width: parent.width
                height: 16

                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width
                    height: 3
                    radius: 2
                    color: Theme.surface
                }

                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    width: root.audio ? Math.max(0, Math.min(1, root.volume)) * parent.width : 0
                    height: 3
                    radius: 2
                    color: Theme.yellow
                }

                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    x: root.audio ? Math.max(0, Math.min(1, root.volume)) * parent.width - 3 : 0
                    width: 6
                    height: 6
                    radius: 3
                    color: Theme.fg
                }

                MouseArea {
                    anchors.fill: parent
                    enabled: root.audio !== null
                    cursorShape: Qt.PointingHandCursor

                    function adjust(x) {
                        if (!root.audio)
                            return;
                        root.audio.muted = false;
                        root.audio.volume = Math.max(0.001, Math.min(1, x / width));
                    }

                    onPressed: (mouse) => adjust(mouse.x)
                    onPositionChanged: (mouse) => {
                        if (pressed)
                            adjust(mouse.x);
                    }
                }
            }

            Item {
                width: parent.width
                height: 16

                Text {
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    text: "brightness"
                    color: Theme.fgDim
                    font.family: Theme.font
                    font.pixelSize: Theme.sizeSmall
                }

                Text {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    text: Brightness.available ? Brightness.pct + "%" : "--"
                    color: Theme.fg
                    font.family: Theme.font
                    font.pixelSize: Theme.sizeSmall
                }
            }

            Item {
                width: parent.width
                height: 16

                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width
                    height: 3
                    radius: 2
                    color: Theme.surface
                }

                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    width: Brightness.available ? Math.max(0, Math.min(100, Brightness.pct)) / 100 * parent.width : 0
                    height: 3
                    radius: 2
                    color: Theme.accent
                }

                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    x: Brightness.available ? Math.max(0, Math.min(100, Brightness.pct)) / 100 * parent.width - 3 : 0
                    width: 6
                    height: 6
                    radius: 3
                    color: Theme.fg
                }

                MouseArea {
                    anchors.fill: parent
                    enabled: Brightness.available
                    cursorShape: Qt.PointingHandCursor

                    function adjust(x) {
                        if (!Brightness.available)
                            return;
                        Brightness.setPct(x / width * 100);
                    }

                    onPressed: (mouse) => adjust(mouse.x)
                    onPositionChanged: (mouse) => {
                        if (pressed)
                            adjust(mouse.x);
                    }
                }
            }

            Rectangle {
                width: parent.width
                height: 1
                color: Theme.border
            }

            Item {
                width: parent.width
                height: 20

                Text {
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    text: "lock screen"
                    color: Theme.fgDim
                    font.family: Theme.font
                    font.pixelSize: Theme.sizeSmall
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        root.close();
                        Quickshell.execDetached(["swaylock", "-f"]);
                    }
                }
            }
        }
    }
}
