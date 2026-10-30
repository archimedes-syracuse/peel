import QtQuick
import "../theme"

Item {
    id: root

    property string iconSource: ""
    property string label: ""
    property var command: []
    signal activated()

    width: 86
    height: 82

    Rectangle {
        anchors.fill: parent
        radius: 0
        color: hover.hovered ? "#22e8dcc4" : "transparent"
        border.width: hover.hovered ? 1 : 0
        border.color: "#55e8dcc4"
    }

    Column {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.topMargin: 3
        spacing: 2

        Image {
            anchors.horizontalCenter: parent.horizontalCenter
            width: 40
            height: 40
            source: root.iconSource
            sourceSize.width: 40
            sourceSize.height: 40
            smooth: false
            fillMode: Image.PreserveAspectFit
        }

        Text {
            width: root.width - 8
            anchors.horizontalCenter: parent.horizontalCenter
            text: root.label
            color: Theme.deskText
            style: Text.Outline
            styleColor: Theme.deskShadow
            font.family: Theme.fontRetro
            font.pixelSize: 10
            font.bold: true
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.WordWrap
            maximumLineCount: 2
            elide: Text.ElideRight
        }
    }

    HoverHandler {
        id: hover
        cursorShape: Qt.PointingHandCursor
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton
        onDoubleClicked: root.activated()
    }
}
