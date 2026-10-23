import QtQuick
import "../theme"

// Shared framing for the small desktop windows. The references use a paper
// fill, a slightly darker title strip, a hard 1px edge and a solid offset
// shadow -- no rounded corners and no blur.
Item {
    id: root

    property color paper: "#fdf6e3"
    property color strip: "#eee8d5"
    property color ink: "#2e3436"
    property color titleTextColor: ink
    property color shadowColor: ink

    property string title: ""
    property bool showTitle: false
    property bool showSquares: true
    property bool showHatch: false
    property bool showNav: false
    property int stripHeight: 12
    property int shadow: 3

    default property alias content: body.data

    Rectangle {
        x: root.shadow
        y: root.shadow
        width: root.width
        height: root.height
        color: root.shadowColor
    }

    Rectangle {
        id: frame
        width: root.width
        height: root.height
        color: root.paper
        border.width: 1
        border.color: root.ink
    }

    Rectangle {
        id: stripRect
        x: 1
        y: 1
        width: frame.width - 2
        height: root.stripHeight
        color: root.strip
    }

    Rectangle {
        x: 1
        y: root.stripHeight + 1
        width: frame.width - 2
        height: 1
        color: root.ink
    }

    // Dithered application mark used by the Notes reference.
    Item {
        visible: root.showHatch
        x: 9
        y: Math.round((root.stripHeight - 14) / 2)
        width: 14
        height: 14

        Rectangle {
            anchors.fill: parent
            color: root.titleTextColor
        }

        Repeater {
            model: 9

            Rectangle {
                width: 3
                height: 3
                x: (index % 3) * 5 + 1
                y: Math.floor(index / 3) * 5 + 1
                color: root.strip
                visible: (index + Math.floor(index / 3)) % 2 === 0
            }
        }
    }

    PixelText {
        id: titleText
        visible: root.showTitle
        x: root.showHatch ? 30 : 8
        width: {
            const right = root.showNav ? navRow.x - 8 : root.width - 10;
            return Math.max(0, right - x);
        }
        anchors.verticalCenter: stripRect.verticalCenter
        text: root.title
        color: root.titleTextColor
        font.pixelSize: 14
        elide: Text.ElideRight
    }

    Row {
        id: navRow
        visible: root.showNav
        anchors.right: parent.right
        anchors.rightMargin: 9
        anchors.verticalCenter: stripRect.verticalCenter
        spacing: 10

        Text {
            text: Theme.gArrowLeft
            color: root.titleTextColor
            font.family: Theme.font
            font.pixelSize: 16
        }
        Text {
            text: Theme.gArrowRight
            color: root.titleTextColor
            font.family: Theme.font
            font.pixelSize: 16
        }
        Text {
            text: Theme.gClose
            color: root.titleTextColor
            font.family: Theme.font
            font.pixelSize: 16
        }
    }

    // Two tiny window buttons in the paper-strip windows.
    Row {
        visible: root.showSquares
        anchors.right: parent.right
        anchors.rightMargin: 5
        anchors.verticalCenter: stripRect.verticalCenter
        spacing: 3

        Rectangle {
            width: 5
            height: 5
            color: "transparent"
            border.width: 1
            border.color: root.ink
        }
        Rectangle {
            width: 5
            height: 5
            color: "transparent"
            border.width: 1
            border.color: root.ink
        }
    }

    Item {
        id: body
        x: 1
        y: root.stripHeight + 2
        width: frame.width - 2
        height: frame.height - y - 1
        clip: true
    }
}
