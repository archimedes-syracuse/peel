import QtQuick
import "../theme"

// Small hoverable glyph/label button used across the bar.
Rectangle {
    id: root

    property string glyph: ""
    property string label: ""
    property color textColor: Theme.fg
    signal clicked()

    implicitWidth: content.implicitWidth + 14
    implicitHeight: 24
    radius: 7
    color: hover.hovered ? Theme.bgHover : "transparent"

    Behavior on color { ColorAnimation { duration: Theme.duration } }

    Row {
        id: content
        anchors.centerIn: parent
        spacing: 6

        Text {
            anchors.verticalCenter: parent.verticalCenter
            visible: root.glyph !== ""
            text: root.glyph
            color: root.textColor
            font.family: Theme.font
            font.pixelSize: Theme.iconSize
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            visible: root.label !== ""
            text: root.label
            color: root.textColor
            font.family: Theme.font
            font.pixelSize: Theme.size
        }
    }

    HoverHandler {
        id: hover
        cursorShape: Qt.PointingHandCursor
    }

    TapHandler {
        onTapped: root.clicked()
    }
}
