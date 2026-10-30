import QtQuick
import Quickshell
import Quickshell.Services.SystemTray
import "../theme"

Row {
    id: root

    spacing: 2
    visible: repeater.count > 0

    Repeater {
        id: repeater
        model: SystemTray.items

        Item {
            width: 20
            height: 20
            anchors.verticalCenter: parent.verticalCenter

            Image {
                anchors.centerIn: parent
                source: modelData.icon
                sourceSize.width: 16
                sourceSize.height: 16
                smooth: true
                fillMode: Image.PreserveAspectFit
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
                onClicked: (mouse) => {
                    if (mouse.button === Qt.LeftButton)
                        modelData.activate();
                    else
                        modelData.secondaryActivate();
                }
            }
        }
    }
}
