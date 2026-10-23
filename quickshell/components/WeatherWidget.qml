import QtQuick
import Quickshell
import Quickshell.Wayland
import "../theme"
import "../services"

// Weather window from the supplied desktop mockup. It sits on the wallpaper
// layer, below tiled windows, and uses live wttr.in data.
PanelWindow {
    id: root

    property var modelData

    screen: modelData
    implicitWidth: 300 + card.shadow
    implicitHeight: 118 + card.shadow
    color: "transparent"
    focusable: false
    exclusiveZone: 0
    anchors {
        top: true
        left: true
    }
    margins {
        top: Theme.barHeight + 18
        left: 32
    }
    WlrLayershell.layer: WlrLayer.Background
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    WlrLayershell.namespace: "niri-shell-widgets"

    RetroWindow {
        id: card
        width: 300
        height: 118
        stripHeight: 12

        Canvas {
            anchors.left: parent.left
            anchors.leftMargin: 14
            anchors.verticalCenter: parent.verticalCenter
            width: 62
            height: 62

            onPaint: {
                const ctx = getContext("2d");
                ctx.reset();
                ctx.fillStyle = "#2e3436";
                ctx.beginPath();
                ctx.arc(31, 31, 28, 0, Math.PI * 2);
                ctx.fill();
                ctx.fillStyle = "#fdf6e3";
                ctx.beginPath();
                ctx.arc(43, 22, 26, 0, Math.PI * 2);
                ctx.fill();
            }
        }

        Column {
            anchors.left: parent.left
            anchors.leftMargin: 92
            anchors.right: parent.right
            anchors.rightMargin: 12
            anchors.verticalCenter: parent.verticalCenter
            spacing: 2

            PixelText {
                width: parent.width
                text: Weather.available
                    ? "It currently feels like " + Weather.feelsLikeC.toFixed(1) + "°C."
                    : "Waiting for weather..."
                font.pixelSize: 9
                lineHeightMode: Text.FixedHeight
                lineHeight: 11
                wrapMode: Text.Wrap
            }

            PixelText {
                width: parent.width
                visible: Weather.available
                text: "It will be " + Weather.minTempC + "°C to " + Weather.maxTempC + "°C today."
                font.pixelSize: 9
                lineHeightMode: Text.FixedHeight
                lineHeight: 11
                wrapMode: Text.Wrap
            }

            PixelText {
                width: parent.width
                visible: Weather.available
                text: Weather.advice
                font.pixelSize: 9
                lineHeightMode: Text.FixedHeight
                lineHeight: 11
                wrapMode: Text.Wrap
            }

            PixelText {
                width: parent.width
                visible: Weather.available
                text: "We've had " + Weather.rainMM.toFixed(1) + "mm rain so far. " + Weather.rainAdvice
                font.pixelSize: 9
                lineHeightMode: Text.FixedHeight
                lineHeight: 11
                wrapMode: Text.Wrap
            }

            PixelText {
                width: parent.width
                visible: Weather.available
                text: "The sun will set at " + (Weather.sunset || "--:--") + "."
                font.pixelSize: 9
                lineHeightMode: Text.FixedHeight
                lineHeight: 11
                wrapMode: Text.Wrap
            }
        }
    }
}
