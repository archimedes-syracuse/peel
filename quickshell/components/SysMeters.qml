import QtQuick
import "../theme"
import "../services"

Row {
    id: root

    spacing: 10

    Column {
        spacing: 2
        anchors.verticalCenter: parent.verticalCenter

        Text {
            text: "CPU " + Math.round(SysStats.cpu) + "%"
            color: Theme.fgDim
            font.family: Theme.font
            font.pixelSize: 9
        }

        Rectangle {
            width: 42
            height: 2
            radius: 1
            color: Theme.bgHover

            Rectangle {
                width: parent.width * SysStats.cpu / 100
                height: parent.height
                radius: 1
                color: Theme.accent
                Behavior on width { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }
            }
        }
    }

    Column {
        spacing: 2
        anchors.verticalCenter: parent.verticalCenter

        Text {
            text: "MEM " + Math.round(SysStats.mem) + "%"
            color: Theme.fgDim
            font.family: Theme.font
            font.pixelSize: 9
        }

        Rectangle {
            width: 42
            height: 2
            radius: 1
            color: Theme.bgHover

            Rectangle {
                width: parent.width * SysStats.mem / 100
                height: parent.height
                radius: 1
                color: Theme.accent2
                Behavior on width { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }
            }
        }
    }
}
