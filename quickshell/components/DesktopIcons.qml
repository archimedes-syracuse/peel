import QtQuick
import Quickshell
import Quickshell.Wayland
import "../theme"
import "../services"

// Desktop icon layer. It is on the background layer, below application
// windows, and is masked to the icon rectangles so empty desktop clicks stay
// click-through.
PanelWindow {
    id: root

    property var modelData

    screen: modelData
    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }
    color: "transparent"
    exclusiveZone: 0
    focusable: false
    WlrLayershell.layer: WlrLayer.Background
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    WlrLayershell.namespace: "niri-shell-desktop-icons"

    readonly property string home: Quickshell.env("HOME")

    mask: Region {
        item: homeIcon
        Region { item: trashIcon }
        Region { item: computerIcon }
        Region { item: docsIcon }
    }

    Column {
        x: 26
        y: 24
        spacing: 4

        DesktopIcon {
            id: homeIcon
            iconSource: "../assets/icon-home.png"
            label: "Home"
            onActivated: Quickshell.execDetached(["nautilus", root.home])
        }

        DesktopIcon {
            id: trashIcon
            iconSource: "../assets/icon-trash.png"
            label: "Trash"
            onActivated: Quickshell.execDetached(["nautilus", "trash://"])
        }

        DesktopIcon {
            id: computerIcon
            iconSource: "../assets/icon-computer.png"
            label: "Computer"
            onActivated: Quickshell.execDetached(["nautilus", "/"])
        }

        DesktopIcon {
            id: docsIcon
            iconSource: "../assets/icon-books.png"
            label: "Documents"
            onActivated: Quickshell.execDetached(["nautilus", root.home + "/Documents"])
        }
    }
}
