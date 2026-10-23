import QtQuick
import Quickshell
import Quickshell.Wayland
import "../theme"

// Palette card from the third reference window. Kept as a desktop note rather
// than folded into the shell theme: it is the supplied reference palette.
PanelWindow {
    id: root

    property var modelData

    screen: modelData
    implicitWidth: 282 + card.shadow
    implicitHeight: 260 + card.shadow
    color: "transparent"
    focusable: false
    exclusiveZone: 0
    anchors {
        top: true
        left: true
    }
    margins {
        top: Theme.barHeight + 18 + 118 + 18
        left: 32
    }
    WlrLayershell.layer: WlrLayer.Background
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    WlrLayershell.namespace: "niri-shell-widgets"

    RetroWindow {
        id: card
        width: 282
        height: 260
        stripHeight: 30
        paper: "#f7eb96"
        strip: "#69633f"
        ink: "#69633f"
        shadowColor: "#4d4830"
        titleTextColor: "#e3ddb0"
        title: "Notes - Notes"
        showTitle: true
        showSquares: false
        showHatch: true
        showNav: true

        PixelText {
            x: 10
            y: 9
            width: parent.width - 20
            text: "greys:\n"
                + "#edeceb\n"
                + "#dcdad\n"
                + "#d4cfc7\n"
                + "#d3d7cf\n"
                + "#d3d3dd\n"
                + "\n"
                + "---motif colours / xfce stellar ---\n"
                + "#aeb2c3, #9ba0b0, #b24d7a,\n"
                + "#7b7691\n"
                + "--------------------------------"
            color: "#5b5537"
            font.pixelSize: 12
            lineHeightMode: Text.FixedHeight
            lineHeight: 18
            wrapMode: Text.Wrap
        }
    }
}
