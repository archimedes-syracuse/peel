import QtQuick
import "../theme"
import "../services"

// Numeric workspace strip for the vertical rail. Active is the only accent;
// occupied workspaces are quieter, empty ones recede almost completely.
Column {
    id: root

    spacing: 1

    readonly property var all: Niri.workspaces

    function goTo(idx) {
        Niri.focusWorkspace(idx);
    }

    Repeater {
        model: 5

        Item {
            id: item

            readonly property bool used: {
                for (let i = 0; i < root.all.length; i++) {
                    if (root.all[i].idx === index + 1)
                        return true;
                }
                return false;
            }

            readonly property bool selected: {
                for (let i = 0; i < root.all.length; i++) {
                    if (root.all[i].idx === index + 1 && root.all[i].is_active)
                        return true;
                }
                return false;
            }

            width: 28
            height: 23

            Rectangle {
                anchors.fill: parent
                radius: Theme.radius
                color: item.selected
                    ? Theme.accentSoft
                    : hover.hovered ? Theme.bgHover : "transparent"
                border.width: item.selected ? 1 : 0
                border.color: Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.45)

                Behavior on color { ColorAnimation { duration: Theme.duration } }
            }

            Text {
                anchors.centerIn: parent
                text: String(index + 1)
                color: item.selected ? Theme.accent : hover.hovered ? Theme.fg : item.used ? Theme.fg : Theme.fgDim
                opacity: item.selected ? 1 : hover.hovered ? 1 : item.used ? 0.8 : 0.35
                font.family: Theme.font
                font.pixelSize: Theme.size
                font.bold: item.selected

                Behavior on color { ColorAnimation { duration: Theme.duration } }
                Behavior on opacity { NumberAnimation { duration: Theme.duration } }
            }

            HoverHandler {
                id: hover
                cursorShape: Qt.PointingHandCursor
            }

            TapHandler {
                onTapped: root.goTo(index + 1)
            }
        }
    }

    WheelHandler {
        onWheel: (event) => {
            if (event.angleDelta.y > 0)
                Niri.workspaceUp();
            else
                Niri.workspaceDown();
        }
    }
}
