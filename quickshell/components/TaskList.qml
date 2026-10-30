import QtQuick
import Quickshell
import Quickshell.Wayland
import "../theme"

Row {
    id: root

    spacing: 3
    clip: true

    function glyphFor(appId) {
        const id = (appId || "").toLowerCase();
        if (id.includes("alacritty") || id.includes("konsole") || id.includes("kitty") || id.includes("foot"))
            return Theme.gTerminal;
        if (id.includes("librewolf") || id.includes("firefox") || id.includes("chrom"))
            return Theme.gApps;
        if (id.includes("nautilus") || id.includes("file"))
            return Theme.gApps;
        if (id.includes("code") || id.includes("opencode") || id.includes("editor"))
            return Theme.gTerminal;
        return Theme.gApps;
    }

    Repeater {
        model: ToplevelManager.toplevels

        Rectangle {
            id: task

            readonly property bool selected: modelData.activated === true

            width: Math.min(210, Math.max(104, ((modelData.title || modelData.appId || "").length * 6.8) + 54))
            height: 24
            radius: Theme.radius
            color: selected
                ? Theme.accentSoft
                : hover.hovered ? Theme.bgHover : "transparent"
            border.width: selected ? 1 : 0
            border.color: Theme.accent
            clip: true

            Behavior on color { ColorAnimation { duration: Theme.duration } }

            Row {
                anchors.fill: parent
                anchors.leftMargin: 7
                anchors.rightMargin: 22
                spacing: 5

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.glyphFor(modelData.appId)
                    color: task.selected ? Theme.accent : Theme.deskTextDim
                    font.family: Theme.font
                    font.pixelSize: 12
                }

                Text {
                    width: Math.max(0, parent.width - 22)
                    anchors.verticalCenter: parent.verticalCenter
                    text: modelData.title || modelData.appId || "window"
                    color: task.selected ? Theme.accent : Theme.deskText
                    font.family: Theme.font
                    font.pixelSize: Theme.sizeSmall
                    elide: Text.ElideRight
                }
            }

            HoverHandler {
                id: hover
                cursorShape: Qt.PointingHandCursor
            }

            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.LeftButton | Qt.MiddleButton
                cursorShape: Qt.PointingHandCursor

                onClicked: (mouse) => {
                    if (mouse.button === Qt.MiddleButton) {
                        modelData.close();
                        return;
                    }
                    if (modelData.activated && !modelData.minimized) {
                        modelData.minimized = true;
                    } else {
                        modelData.minimized = false;
                        modelData.activate();
                    }
                }
            }

            Item {
                id: closeItem

                width: 16
                height: 16
                anchors.right: parent.right
                anchors.rightMargin: 4
                anchors.verticalCenter: parent.verticalCenter
                visible: hover.hovered || task.selected
                opacity: closeHover.hovered ? 1 : 0.65

                Text {
                    anchors.centerIn: parent
                    text: "\u00D7"
                    color: closeHover.hovered ? Theme.red : Theme.deskTextDim
                    font.family: Theme.font
                    font.pixelSize: 14
                    font.bold: true
                }

                HoverHandler {
                    id: closeHover
                    cursorShape: Qt.PointingHandCursor
                }

                MouseArea {
                    anchors.fill: parent
                    acceptedButtons: Qt.LeftButton
                    cursorShape: Qt.PointingHandCursor
                    onClicked: modelData.close()
                }
            }
        }
    }
}
