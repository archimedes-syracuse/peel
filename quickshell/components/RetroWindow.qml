import QtQuick
import "../theme"

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
    property bool draggable: false
    property int stripHeight: 12
    property int shadow: 3

    signal dragBy(real dx, real dy)
    signal dragFinished()
    signal backRequested()
    signal forwardRequested()
    signal closeRequested()

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

    MouseArea {
        id: titleDrag
        visible: root.draggable
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        height: root.stripHeight + 2
        cursorShape: Qt.SizeAllCursor
        property real lastSceneX
        property real lastSceneY

        onPressed: (mouse) => {
            const point = titleDrag.mapToItem(null, mouse.x, mouse.y);
            lastSceneX = point.x;
            lastSceneY = point.y;
        }
        onPositionChanged: (mouse) => {
            if (!pressed)
                return;
            const point = titleDrag.mapToItem(null, mouse.x, mouse.y);
            const dx = point.x - lastSceneX;
            const dy = point.y - lastSceneY;
            if (dx !== 0 || dy !== 0)
                root.dragBy(dx, dy);
            lastSceneX = point.x;
            lastSceneY = point.y;
        }
        onReleased: root.dragFinished()
    }

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
        spacing: 8

        Item {
            width: 16
            height: root.stripHeight
            Text {
                anchors.centerIn: parent
                text: Theme.gArrowLeft
                color: navBack.hovered ? root.paper : root.titleTextColor
                font.family: Theme.font
                font.pixelSize: 16
            }
            MouseArea {
                id: navBack
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.backRequested()
            }
        }
        Item {
            width: 16
            height: root.stripHeight
            Text {
                anchors.centerIn: parent
                text: Theme.gArrowRight
                color: navForward.hovered ? root.paper : root.titleTextColor
                font.family: Theme.font
                font.pixelSize: 16
            }
            MouseArea {
                id: navForward
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.forwardRequested()
            }
        }
        Item {
            width: 14
            height: root.stripHeight
            Text {
                anchors.centerIn: parent
                text: Theme.gClose
                color: navClose.hovered ? root.paper : root.titleTextColor
                font.family: Theme.font
                font.pixelSize: 16
            }
            MouseArea {
                id: navClose
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.closeRequested()
            }
        }
    }

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
