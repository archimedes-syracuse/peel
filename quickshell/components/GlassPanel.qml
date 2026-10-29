import QtQuick
import "../theme"

// Translucent surface: a hairline frame around a glass fill. Content goes in
// the default property and is stacked above the fill.
//
// The frame is a single solid colour. A previous version filled the whole
// panel with the primary -> tertiary gradient and then drew the fill inset on
// top; that made an opaque backing underneath a translucent fill, so the panel
// was never actually see-through. `borderEnd` is kept for API compatibility.
Item {
    id: root

    default property alias content: surface.data

    property int radius: Theme.radius
    property int borderWidth: 1
    property color fill: Theme.bgPanel
    property color borderStart: Theme.accent
    property color borderEnd: Theme.accent2

    Rectangle {
        id: surface

        anchors.fill: parent
        radius: root.radius
        color: root.fill
        border.width: root.borderWidth
        border.color: root.borderStart
    }
}
