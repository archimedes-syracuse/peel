import QtQuick
import Quickshell
import Quickshell.Wayland
import "../services"

// A single full-screen background surface hosts all three desktop widgets.
// Keeping them in one surface lets the title-bar drag handlers use stable
// scene coordinates while the widgets move, instead of moving the layer
// surface itself (which causes pointer feedback loops).
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
    // Only ask for keyboard focus while the notes editor is on screen; when it
    // is hidden, keyboard input should go back to the focused application.
    WlrLayershell.keyboardFocus: Widgets.notesVisible
        ? WlrKeyboardFocus.OnDemand
        : WlrKeyboardFocus.None
    WlrLayershell.namespace: "niri-shell-widgets"

    // Clicking bare wallpaper clears the note editor's focus. Cards are
    // declared after this item and therefore keep their own input handling.
    MouseArea {
        z: -1
        anchors.fill: parent
        onClicked: notes.clearEditorFocus()
    }

    WeatherWidget { z: 0 }
    MusicWidget { z: 1 }
    NotesWidget { id: notes; z: 2 }
}
