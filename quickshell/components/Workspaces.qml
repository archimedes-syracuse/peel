import QtQuick
import "../theme"
import "../services"

// Five Niri workspace pills. The active one expands and fills with the
// accent; occupied-but-hidden ones get a faint surface.
Row {
    id: root

    spacing: 4

    readonly property var all: Niri.workspaces

    function goTo(idx) {
        Niri.focusWorkspace(idx);
    }

    Repeater {
        model: 5

        Rectangle {
            id: pill

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

            width: selected ? 28 : used ? 20 : 16
            height: 20
            radius: 6
            color: selected ? Theme.accent : used ? Theme.bgHover : "transparent"

            Behavior on width { NumberAnimation { duration: Theme.duration; easing.type: Easing.OutCubic } }
            Behavior on color { ColorAnimation { duration: Theme.duration } }

            Text {
                anchors.centerIn: parent
                text: index + 1
                color: pill.selected ? Theme.bg : pill.used ? Theme.fg : Theme.fgDim
                opacity: pill.used || pill.selected ? 1 : 0.45
                font.family: Theme.font
                font.pixelSize: 10
                font.bold: pill.selected
            }

            HoverHandler {
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
