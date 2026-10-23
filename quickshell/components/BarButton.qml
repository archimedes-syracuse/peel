import QtQuick
import "../theme"

// Compact glyph/label button used by the vertical rail. The horizontal layout
// is kept for any small shell surface that still uses the old bar language.
Item {
    id: root

    property string glyph: ""
    property string label: ""
    property color textColor: Theme.fg
    property color glyphColor: textColor
    property color hoverColor: Theme.accent
    property bool vertical: false
    property bool bordered: false
    property bool selected: false
    property bool hoverBackground: true
    signal clicked()

    implicitWidth: vertical ? 30 : horizontalContent.implicitWidth + 10
    implicitHeight: vertical
        ? (label !== "" ? 34 : 28)
        : 22

    Rectangle {
        id: background

        anchors.fill: parent
        radius: Theme.radius
        color: root.selected
            ? Theme.accentSoft
            : root.bordered
                ? Theme.surface
                : hover.hovered && root.hoverBackground
                    ? Theme.bgHover
                    : "transparent"
        border.width: root.bordered ? 1 : 0
        border.color: root.bordered ? Theme.accent : "transparent"

        Behavior on color { ColorAnimation { duration: Theme.duration } }
    }

    Row {
        id: horizontalContent

        visible: !root.vertical
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

    Column {
        id: verticalContent

        visible: root.vertical
        anchors.centerIn: parent
        spacing: -1

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: root.glyph
            color: hover.hovered ? root.hoverColor : root.glyphColor
            font.family: Theme.font
            font.pixelSize: Theme.iconSize + 1

            Behavior on color { ColorAnimation { duration: Theme.duration } }
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            visible: root.label !== ""
            text: root.label
            color: hover.hovered ? root.hoverColor : root.textColor
            font.family: Theme.font
            font.pixelSize: 9
            font.bold: true

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
