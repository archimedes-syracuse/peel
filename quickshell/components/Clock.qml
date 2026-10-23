import Quickshell
import QtQuick
import "../theme"
import "../services"

// Terminal-style center block: date · time · weather. No box, no blinking.
// The root is a MouseArea so the whole block can open the calendar without
// putting an interactive, parent-filling item inside a Row positioner.
MouseArea {
    id: root

    width: content.implicitWidth
    height: content.implicitHeight
    implicitWidth: content.implicitWidth
    implicitHeight: content.implicitHeight
    cursorShape: Qt.PointingHandCursor
    onClicked: Quickshell.execDetached(["qs", "-c", "niri", "ipc", "call", "shell", "toggleCalendar"])

    Row {
        id: content

        spacing: 7

        SystemClock {
            id: clock
            precision: SystemClock.Minutes
        }

        Text {
            height: Theme.barHeight
            verticalAlignment: Text.AlignVCenter
            text: Qt.formatDateTime(clock.date, "ddd dd MMM").toLowerCase()
            color: Theme.fg
            font.family: Theme.font
            font.pixelSize: Theme.size
        }

        Text {
            height: Theme.barHeight
            verticalAlignment: Text.AlignVCenter
            text: "·"
            color: Theme.fgDim
            opacity: 0.6
            font.family: Theme.font
            font.pixelSize: Theme.size
        }

        Text {
            height: Theme.barHeight
            verticalAlignment: Text.AlignVCenter
            text: Qt.formatDateTime(clock.date, "HH:mm")
            color: Theme.accent
            font.family: Theme.font
            font.pixelSize: Theme.sizeBig
            font.bold: true
        }

        Text {
            height: Theme.barHeight
            verticalAlignment: Text.AlignVCenter
            visible: Weather.available
            text: "·"
            color: Theme.fgDim
            opacity: 0.6
            font.family: Theme.font
            font.pixelSize: Theme.size
        }

        Row {
            height: Theme.barHeight
            visible: Weather.available
            spacing: 6

            Text {
                height: parent.height
                verticalAlignment: Text.AlignVCenter
                text: Weather.icon
                color: Theme.yellow
                font.family: Theme.font
                font.pixelSize: Theme.size
            }

            Text {
                height: parent.height
                verticalAlignment: Text.AlignVCenter
                text: Weather.label
                color: Theme.fg
                font.family: Theme.font
                font.pixelSize: Theme.size
            }
        }
    }
}
