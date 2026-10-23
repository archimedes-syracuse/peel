import Quickshell
import QtQuick
import "../theme"
import "../services"

// Two-line rail clock: weekday, hour, minute. Clicking it opens the calendar.
MouseArea {
    id: root

    width: 34
    height: 54
    cursorShape: Qt.PointingHandCursor
    onClicked: Quickshell.execDetached(["qs", "-c", "niri", "ipc", "call", "shell", "toggleCalendar"])

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    Column {
        anchors.centerIn: parent
        spacing: -1

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: Qt.formatDateTime(clock.date, "ddd").toLowerCase()
            color: hover.hovered ? Theme.accent : Theme.fgDim
            font.family: Theme.font
            font.pixelSize: 8

            Behavior on color { ColorAnimation { duration: Theme.duration } }
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: Qt.formatDateTime(clock.date, "HH")
            color: Theme.fg
            font.family: Theme.font
            font.pixelSize: Theme.sizeBig
            font.bold: true
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: Qt.formatDateTime(clock.date, "mm")
            color: Theme.accent
            font.family: Theme.font
            font.pixelSize: Theme.sizeBig
            font.bold: true
        }
    }

    HoverHandler {
        id: hover
        cursorShape: Qt.PointingHandCursor
    }
}
