import QtQuick
import "../theme"
import "../components"

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
        color: Theme.barPill
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
            layer.enabled: true
            layer.effect: TextOutline {}
        }

        Text {
            width: root.valueMaxWidth > 0
                ? Math.min(root.valueMaxWidth, implicitWidth)
                : implicitWidth
            text: root.value
            color: Theme.deskText
            font.family: Theme.font
            font.pixelSize: 14
            layer.enabled: true
            layer.effect: TextOutline {}
            elide: Text.ElideRight
        }
    }
}
