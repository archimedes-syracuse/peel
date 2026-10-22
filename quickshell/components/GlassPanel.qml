import QtQuick
import "../theme"

// Dark translucent surface with the reference's primary -> tertiary edge.
// The gradient is a thin frame behind an inset fill; content goes in the
// default property and is stacked above the fill.
Item {
    id: root

    default property alias content: surface.data

    property int radius: Theme.radius
    property int borderWidth: 2
    property color fill: Theme.bgPanel
    property color borderStart: Theme.accent
    property color borderEnd: Theme.accent2

    Rectangle {
        anchors.fill: parent
        radius: root.radius
        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop { position: 0.0; color: root.borderStart }
            GradientStop { position: 0.55; color: root.borderStart }
            GradientStop { position: 1.0; color: root.borderEnd }
        }
    }

    Rectangle {
        id: surface
        anchors.fill: parent
        anchors.margins: root.borderWidth
        radius: Math.max(0, root.radius - root.borderWidth)
        color: root.fill
    }
}
