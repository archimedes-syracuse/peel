import QtQuick
import "../theme"

// Compact glyph/label button. No chrome: hover and state are communicated
// only by text colour, like the reference bar's right-hand modules.
Item {
    id: root

    property string glyph: ""
    property string label: ""
    property color textColor: Theme.fg
    property color glyphColor: textColor
    property color hoverColor: Theme.accent
    signal clicked()

    implicitWidth: content.implicitWidth + 10
    implicitHeight: 22

    Row {
        id: content
        anchors.centerIn: parent
        spacing: 5

        Text {
            anchors.verticalCenter: parent.verticalCenter
            visible: root.glyph !== ""
            text: root.glyph
            color: hover.hovered ? root.hoverColor : root.glyphColor
            font.family: Theme.font
            font.pixelSize: Theme.iconSize

            Behavior on color { ColorAnimation { duration: Theme.duration } }
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            visible: root.label !== ""
            text: root.label
            color: hover.hovered ? root.hoverColor : root.textColor
            font.family: Theme.font
            font.pixelSize: Theme.sizeSmall

            Behavior on color { ColorAnimation { duration: Theme.duration } }
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
