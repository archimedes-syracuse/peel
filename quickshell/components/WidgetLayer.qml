import QtQuick
import Quickshell
import Quickshell.Wayland
import "../services"

// A single full-screen background surface hosts all three desktop widgets.
// Keeping them in one surface lets the title-bar drag handlers use stable
// scene coordinates while the widgets move, instead of moving the layer
// surface itself (which causes pointer feedback loops).
//
// The surface is masked to the widget rectangles only. Without the mask a
// full-screen background layer would swallow pointer events over the whole
// desktop, so clicks and right-clicks would never reach the applications.
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

    // Only the widget cards accept pointer input; the rest of the desktop
    // stays click-through. The notes region is dropped while the note is
    // hidden, otherwise its invisible rectangle would still eat clicks.
    mask: Region {
        item: weather
        Region { item: music }
        Region { item: notes.visible ? notes : null }
    }

    WeatherWidget { id: weather; z: 0 }
    MusicWidget { id: music; z: 1 }
    NotesWidget { id: notes; z: 2 }
}
