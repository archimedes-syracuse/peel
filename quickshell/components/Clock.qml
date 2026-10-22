import Quickshell
import QtQuick
import "../theme"
import "../services"

// Terminal-style center block: date · time · weather. No box, no blinking.
Row {
    id: root

    spacing: 7

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    Text {
        anchors.verticalCenter: parent.verticalCenter
        text: Qt.formatDateTime(clock.date, "ddd dd MMM").toLowerCase()
        color: Theme.fg
        font.family: Theme.font
        font.pixelSize: Theme.size
    }

    Text {
        anchors.verticalCenter: parent.verticalCenter
        text: "·"
        color: Theme.fgDim
        opacity: 0.6
        font.family: Theme.font
        font.pixelSize: Theme.size
    }

    Text {
        anchors.verticalCenter: parent.verticalCenter
        text: Qt.formatDateTime(clock.date, "HH:mm")
        color: Theme.accent
        font.family: Theme.font
        font.pixelSize: Theme.sizeBig
        font.bold: true
    }

    Text {
        anchors.verticalCenter: parent.verticalCenter
        visible: Weather.available
        text: "·"
        color: Theme.fgDim
        opacity: 0.6
        font.family: Theme.font
        font.pixelSize: Theme.size
    }

    Row {
        anchors.verticalCenter: parent.verticalCenter
        visible: Weather.available
        spacing: 6

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: Weather.icon
            color: Theme.yellow
            font.family: Theme.font
            font.pixelSize: Theme.size
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: Weather.label
            color: Theme.fg
            font.family: Theme.font
            font.pixelSize: Theme.size
        }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: Quickshell.execDetached(["qs", "-c", "niri", "ipc", "call", "shell", "toggleCalendar"])
    }
}
