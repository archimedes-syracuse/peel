import QtQuick
import "../theme"

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
