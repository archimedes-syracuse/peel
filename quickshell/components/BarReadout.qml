import QtQuick
import "../theme"

// A square, hairline-bordered text readout for the top bar.
Item {
    id: root

    property string label: ""
    property string value: ""
    property int valueMaxWidth: 0

    implicitWidth: row.implicitWidth + 16
    implicitHeight: 28
    width: implicitWidth
    height: implicitHeight

    Rectangle {
        anchors.fill: parent
        color: Theme.barGlass
        border.width: 1
        border.color: Theme.barGlassBorder
    }

    Row {
        id: row

        anchors.centerIn: parent
        spacing: 4

        Text {
            text: root.label
            color: Theme.deskTextDim
            font.family: Theme.font
            font.pixelSize: 14
        }

        Text {
            width: root.valueMaxWidth > 0
                ? Math.min(root.valueMaxWidth, implicitWidth)
                : implicitWidth
            text: root.value
            color: Theme.deskText
            font.family: Theme.font
            font.pixelSize: 14
            elide: Text.ElideRight
        }
    }
}
