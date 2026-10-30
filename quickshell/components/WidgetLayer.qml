import QtQuick
import Quickshell
import Quickshell.Wayland
import "../services"

PanelWindow {
    id: root

    property var modelData

    screen: modelData
    color: "transparent"
    focusable: true
    exclusiveZone: 0
    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }
    WlrLayershell.layer: WlrLayer.Background
    WlrLayershell.keyboardFocus: Widgets.notesVisible
        ? WlrKeyboardFocus.OnDemand
        : WlrKeyboardFocus.None
    WlrLayershell.namespace: "niri-shell-widgets"

    mask: Region {
        item: weather
        Region { item: music }
        Region { item: notes.visible ? notes : null }
    }

    WeatherWidget { id: weather; z: 0 }
    MusicWidget { id: music; z: 1 }
    NotesWidget { id: notes; z: 2 }
}
