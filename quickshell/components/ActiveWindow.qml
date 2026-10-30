import QtQuick
import "../theme"
import "../services"

Row {
    id: root

    readonly property var win: Compositor.focusedWindow

    spacing: 7
    visible: win !== null

    Text {
        anchors.verticalCenter: parent.verticalCenter
        text: root.win ? (root.win.app_id || "") : ""
        color: Theme.accent
        font.family: Theme.font
        font.pixelSize: Theme.sizeSmall
        width: Math.min(110, implicitWidth)
        elide: Text.ElideRight
        visible: text !== ""
    }

    Text {
        anchors.verticalCenter: parent.verticalCenter
        text: root.win ? (root.win.title || "") : ""
        color: Theme.fgDim
        font.family: Theme.font
        font.pixelSize: Theme.size
        width: Math.min(300, implicitWidth)
        elide: Text.ElideRight
        visible: text !== ""
    }
}
