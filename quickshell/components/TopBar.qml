import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Pipewire
import "../theme"
import "../components"
import "../services"

// A single line of square, hairline-bordered text readouts along the top edge.
// Time and now-playing sit left, bare tag numbers center, and package, link,
// Bluetooth, battery, volume, and backlight status sit right.
PanelWindow {
    id: root

    property var modelData

    screen: modelData
    anchors {
        top: true
        left: true
        right: true
    }
    implicitHeight: 32
    exclusiveZone: 32
    color: "transparent"
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.namespace: "niri-shell-topbar"

    readonly property var sink: Pipewire.defaultAudioSink
    readonly property var audio: sink ? sink.audio : null
    readonly property real volume: audio ? audio.volume : 0
    readonly property bool muted: audio ? audio.muted : false

    readonly property string wifiText: {
        if (Network.kind === "wifi")
            return Network.conn !== "" ? Network.conn : "on";
        if (Network.kind === "ethernet")
            return "wired";
        return "off";
    }
    readonly property string btText: {
        if (!Bluetooth.available)
            return "--";
        if (!Bluetooth.powered)
            return "off";
        return Bluetooth.connectedCount > 0 ? String(Bluetooth.connectedCount) : "on";
    }
    readonly property string batteryText: Battery.present
        ? Battery.pct + "%" + (Battery.charging ? "+" : "")
        : "--"
    readonly property string volumeText: !audio
        ? "--"
        : muted ? "off" : Math.round(volume * 100) + "%"
    readonly property string brightnessText: Brightness.available
        ? Brightness.pct + "%"
        : "--"

    function clockText(value) {
        if (!isFinite(value) || value <= 0)
            return "";
        const total = Math.floor(value);
        const minutes = Math.floor(total / 60);
        const seconds = total % 60;
        return minutes + ":" + (seconds < 10 ? "0" : "") + seconds;
    }

    SystemClock {
        id: clock
        precision: SystemClock.Seconds
    }

    Rectangle {
        anchors.fill: parent
        color: Theme.bg
    }

    Row {
        id: left

        anchors {
            left: parent.left
            leftMargin: 3
            verticalCenter: parent.verticalCenter
        }
        spacing: 2

        // [ TIME  Aug 08, 02:46:50 ]
        Rectangle {
            width: timeRow.implicitWidth + 16
            height: 28
            color: Theme.deskPanelSolid
            border.width: 1
            border.color: Theme.deskBorder

            Row {
                id: timeRow

                anchors.centerIn: parent
                spacing: 4

                Text {
                    text: "TIME"
                    color: Theme.deskTextDim
                    font.family: Theme.font
                    font.pixelSize: 14
                }

                Text {
                    text: Qt.formatDateTime(clock.date, "MMM dd, HH:mm:ss")
                    color: Theme.deskText
                    font.family: Theme.font
                    font.pixelSize: 14
                }
            }

            HoverHandler { cursorShape: Qt.PointingHandCursor }
            TapHandler {
                onTapped: Quickshell.execDetached(["qs", "-c", "niri", "ipc", "call", "shell", "toggleCalendar"])
            }
        }

        // [ FLAC/WEB  Artist - Title  mm:ss/mm:ss  art ]
        Rectangle {
            visible: Media.available
            width: visible ? musicRow.implicitWidth + 16 : 0
            height: 28
            color: Theme.deskPanelSolid
            border.width: 1
            border.color: Theme.deskBorder

            Row {
                id: musicRow

                anchors.centerIn: parent
                spacing: 4

                Text {
                    text: Media.format
                    visible: text !== ""
                    color: Theme.deskTextDim
                    font.family: Theme.font
                    font.pixelSize: 14
                }

                Text {
                    width: Math.min(340, implicitWidth)
                    text: Media.title
                    color: Theme.deskText
                    font.family: Theme.font
                    font.pixelSize: 14
                    font.bold: true
                    elide: Text.ElideRight
                }

                Text {
                    visible: Media.player && Media.player.length > 0
                    text: root.clockText(Media.player ? Media.player.position : 0)
                        + "/" + root.clockText(Media.player ? Media.player.length : 0)
                    color: Theme.deskTextDim
                    font.family: Theme.font
                    font.pixelSize: 14
                }

                Image {
                    width: 18
                    height: 18
                    anchors.verticalCenter: parent.verticalCenter
                    source: Media.player && Media.player.trackArtUrl ? Media.player.trackArtUrl : ""
                    sourceSize.width: 36
                    sourceSize.height: 36
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    visible: source !== ""
                }
            }

            HoverHandler { cursorShape: Qt.PointingHandCursor }
            TapHandler {
                onTapped: {
                    if (Media.player)
                        Media.player.togglePlaying();
                }
            }
        }
    }

    // [ 1 2 3 4 5 ]
    Rectangle {
        width: center.implicitWidth + 18
        height: 28
        anchors.centerIn: parent
        color: Theme.deskPanelSolid
        border.width: 1
        border.color: Theme.deskBorder

        WorkspaceStrip {
            id: center

            monitorName: root.modelData ? root.modelData.name : ""
            anchors.centerIn: parent
        }
    }

    Row {
        id: right

        anchors {
            right: parent.right
            rightMargin: 3
            verticalCenter: parent.verticalCenter
        }
        spacing: 2

        AppIcons {
            anchors.verticalCenter: parent.verticalCenter
        }

        BarReadout {
            label: "PKG"
            value: Updates.count < 0 ? "--" : String(Updates.count)
        }

        BarReadout {
            label: "BT"
            value: root.btText
            valueMaxWidth: 60
        }

        BarReadout {
            label: "WIFI"
            value: root.wifiText
            valueMaxWidth: 180
        }

        BarReadout {
            label: "BAT"
            value: root.batteryText
            valueMaxWidth: 80
        }

        BarReadout {
            label: "VOL"
            value: root.volumeText
            valueMaxWidth: 70

            WheelHandler {
                onWheel: (event) => {
                    if (!root.audio)
                        return;
                    const next = root.audio.volume + (event.angleDelta.y > 0 ? 0.05 : -0.05);
                    root.audio.muted = false;
                    root.audio.volume = Math.max(0, Math.min(1.5, next));
                }
            }
        }

        BarReadout {
            label: "BRT"
            value: root.brightnessText
            valueMaxWidth: 70
        }
    }
}
