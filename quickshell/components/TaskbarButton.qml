import QtQuick
import "../theme"

// Small square button used by the bottom taskbar.
Item {
    id: root

    property string glyph: ""
    property color tint: Theme.deskText
    property bool active: false
    property bool accent: false
    signal clicked()

    implicitWidth: 28
    implicitHeight: 24

    Rectangle {
        anchors.fill: parent
        radius: 2
        color: root.active
            ? Theme.accentSoft
            : hover.hovered
                ? Theme.bgHover
                : "transparent"
        border.width: root.active ? 1 : 0
        border.color: Theme.accent

        Behavior on color { ColorAnimation { duration: Theme.duration } }
    }

    Text {
        anchors.centerIn: parent
        text: root.glyph
        color: hover.hovered ? Theme.accent : root.accent ? Theme.accent : root.tint
        font.family: Theme.font
        font.pixelSize: 15

        Behavior on color { ColorAnimation { duration: Theme.duration } }
    }

    HoverHandler {
        id: hover
        cursorShape: Qt.PointingHandCursor
    }

    TapHandler {
        onTapped: root.clicked()
    }
}
