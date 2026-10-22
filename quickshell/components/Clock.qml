import Quickshell
import QtQuick
import "../theme"

// Clock + date. The colon fades on odd seconds so it feels alive without
// a full second-by-second layout jitter.
Rectangle {
    id: root

    implicitWidth: row.implicitWidth + 20
    implicitHeight: 26
    radius: 8
    color: "transparent"

    SystemClock {
        id: clock
        precision: SystemClock.Seconds
    }

    Row {
        id: row
        anchors.centerIn: parent
        spacing: 9

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: Qt.formatDateTime(clock.date, "HH:mm")
            color: Theme.fg
            font.family: Theme.font
            font.pixelSize: Theme.sizeBig
            font.bold: true
            opacity: Qt.formatDateTime(clock.date, "ss") % 2 === 0 ? 1 : 0.55
            Behavior on opacity { NumberAnimation { duration: 180 } }
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: Qt.formatDateTime(clock.date, "ddd dd MMM")
            color: Theme.fgDim
            font.family: Theme.font
            font.pixelSize: Theme.sizeSmall
        }
    }
}
