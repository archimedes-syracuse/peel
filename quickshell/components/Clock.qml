import Quickshell
import QtQuick
import "../theme"

// Terminal-style center block: date › time. No box, no blinking colon.
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
        text: "›"
        color: Theme.accent2
        opacity: 0.55
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
}
