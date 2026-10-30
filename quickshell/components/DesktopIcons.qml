import QtQuick
import Quickshell
import Quickshell.Wayland
import "../theme"
import "../services"

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
            iconSource: "../assets/icon-home-naturalist.png"
            label: "Home"
            onActivated: Quickshell.execDetached(["alacritty", "-e", "yazi", root.home])
        }

        DesktopIcon {
            id: trashIcon
            iconSource: "../assets/icon-trash-naturalist.png"
            label: "Trash"
            onActivated: Quickshell.execDetached(["alacritty", "-e", "yazi", root.home + "/.local/share/Trash/files"])
        }

        DesktopIcon {
            id: computerIcon
            iconSource: "../assets/icon-computer-naturalist.png"
            label: "Computer"
            onActivated: Quickshell.execDetached(["alacritty", "-e", "yazi", "/"])
        }

        DesktopIcon {
            id: docsIcon
            iconSource: "../assets/icon-books-naturalist.png"
            label: "Documents"
            onActivated: Quickshell.execDetached(["alacritty", "-e", "yazi", root.home + "/Documents"])
        }
    }
}
