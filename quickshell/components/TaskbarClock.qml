import QtQuick
import Quickshell
import "../theme"

// Horizontal taskbar clock. The old rail clock was intentionally vertical.
Item {
    id: root

    implicitWidth: 96
    implicitHeight: 24

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    Row {
        anchors.centerIn: parent
        spacing: 6

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: Qt.formatDateTime(clock.date, "HH:mm")
            color: hover.hovered ? Theme.accent : Theme.deskText
            font.family: Theme.font
            font.pixelSize: Theme.sizeBig
            font.bold: true

            Behavior on color { ColorAnimation { duration: Theme.duration } }
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: Qt.formatDateTime(clock.date, "yyyy-MM-dd")
            color: Theme.deskTextDim
            font.family: Theme.fontRetro
            font.pixelSize: 8
        }
    }

    HoverHandler {
        id: hover
        cursorShape: Qt.PointingHandCursor
    }

    TapHandler {
        onTapped: Quickshell.execDetached(["qs", "-c", "niri", "ipc", "call", "shell", "toggleCalendar"])
    }
}
