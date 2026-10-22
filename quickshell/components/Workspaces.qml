import QtQuick
import "../theme"
import "../services"

// Roman-numeral workspace strip. Active is the only accent; occupied
// workspaces are quieter, empty ones recede almost completely.
Row {
    id: root

    spacing: 9

    readonly property var all: Niri.workspaces
    readonly property var numerals: ["I", "II", "III", "IV", "V"]

    function goTo(idx) {
        Niri.focusWorkspace(idx);
    }

    Repeater {
        model: 5

        Text {
            id: label

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

            text: root.numerals[index]
            color: selected ? Theme.accent : hover.hovered ? Theme.fg : used ? Theme.fg : Theme.fgDim
            opacity: selected ? 1 : hover.hovered ? 1 : used ? 0.8 : 0.35
            font.family: Theme.font
            font.pixelSize: Theme.size
            font.bold: selected

            Behavior on color { ColorAnimation { duration: Theme.duration } }
            Behavior on opacity { NumberAnimation { duration: Theme.duration } }

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
