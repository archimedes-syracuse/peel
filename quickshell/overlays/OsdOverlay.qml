import QtQuick
import Quickshell
import Quickshell.Wayland
import "../theme"
import "../components"
import "../services"

// Transient feedback for volume and backlight changes. It is a small,
// non-focusable layer surface; no input is captured outside its own bounds.
PanelWindow {
    id: root

    readonly property bool isVolume: Osd.kind === "volume"
    readonly property color accentColor: isVolume ? Theme.yellow : Theme.accent
    readonly property color endColor: isVolume ? Theme.accent : Theme.accent2

    visible: Osd.shown
    color: "transparent"
    anchors {
        bottom: true
    }
    margins {
        bottom: 56
    }
    implicitWidth: 220
    implicitHeight: 54
    exclusiveZone: 0
    focusable: false
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    WlrLayershell.namespace: "niri-shell-osd"

    onVisibleChanged: {
        if (visible) {
            card.opacity = 0;
            card.scale = 0.96;
            intro.restart();
        }
    }

    GlassPanel {
        id: card

        anchors.fill: parent
        radius: Theme.radius
        borderWidth: 1
        fill: Theme.barGlass
        borderStart: root.accentColor
        borderEnd: root.endColor
        transformOrigin: Item.Bottom

        ParallelAnimation {
            id: intro
            NumberAnimation { target: card; property: "scale"; to: 1; duration: 150; easing.type: Easing.OutCubic }
            NumberAnimation { target: card; property: "opacity"; to: 1; duration: 110 }
        }

        Column {
            anchors.fill: parent
            anchors.margins: 10
            spacing: 6

            Item {
                width: parent.width
                height: 16

                Text {
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.isVolume
                        ? (Osd.muted ? Theme.gMuted : Theme.gVolHigh)
                        : Theme.gBrightness
                    color: root.accentColor
                    font.family: Theme.font
                    font.pixelSize: Theme.iconSize
                }

                Text {
                    anchors.left: parent.left
                    anchors.leftMargin: 24
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.isVolume ? "volume" : "brightness"
                    color: Theme.fgDim
                    font.family: Theme.font
                    font.pixelSize: Theme.sizeSmall
                }

                Text {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.isVolume && Osd.muted ? "muted" : Osd.pct + "%"
                    color: root.isVolume && Osd.muted ? Theme.fgDim : Theme.fg
                    font.family: Theme.font
                    font.pixelSize: Theme.sizeSmall
                }
            }

            Item {
                width: parent.width
                height: 4

                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width
                    height: 3
                    radius: 2
                    color: Theme.surface
                }

                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    width: root.isVolume && Osd.muted
                        ? 0
                        : Math.max(0, Math.min(100, Osd.pct)) / 100 * parent.width
                    height: 3
                    radius: 2
                    color: root.accentColor
                }
            }
        }
    }
}
