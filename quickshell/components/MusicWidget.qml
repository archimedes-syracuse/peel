import QtQuick
import "../theme"
import "../services"

Item {
    id: root

    readonly property var player: Media.player
    readonly property bool demo: !Media.hasTrack
    readonly property string trackTitle: demo ? "Ice u out" : Media.title
    readonly property string trackArtist: demo ? "Ninajirachi, Kota Banks" : Media.artist
    readonly property string artSource: !demo && player && player.trackArtUrl
        ? player.trackArtUrl
        : "../assets/ice-u-out.png"

    width: card.width + card.shadow
    height: card.height + card.shadow
    x: Widgets.musicX
    y: Widgets.musicY

    function moveBy(dx, dy) {
        const screenWidth = parent ? parent.width : 1920;
        const screenHeight = parent ? parent.height : 1080;
        const x = Math.max(Theme.gap, Math.min(screenWidth - width - Theme.gap, Widgets.musicX + dx));
        const y = Math.max(Theme.gap, Math.min(screenHeight - height - 8, Widgets.musicY + dy));
        Widgets.setMusicPosition(x, y);
    }

    RetroWindow {
        id: card
        width: 176
        height: 224
        stripHeight: 12
        draggable: true
        onDragBy: (dx, dy) => root.moveBy(dx, dy)

        Rectangle {
            id: artFrame
            x: 22
            y: 8
            width: 132
            height: 132
            color: card.ink

            Image {
                anchors.fill: parent
                anchors.margins: 3
                source: root.artSource
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                smooth: !root.demo
                sourceSize.width: 252
                sourceSize.height: 252
            }
        }

        PixelText {
            id: trackTitle
            x: 8
            y: artFrame.y + artFrame.height + 5
            width: parent.width - 16
            text: root.trackTitle
            font.pixelSize: 10
            horizontalAlignment: Text.AlignHCenter
            elide: Text.ElideRight
        }

        PixelText {
            id: trackArtist
            x: 8
            y: trackTitle.y + 15
            width: parent.width - 16
            text: root.trackArtist
            font.pixelSize: 9
            horizontalAlignment: Text.AlignHCenter
            elide: Text.ElideRight
        }

        Row {
            anchors.top: trackArtist.bottom
            anchors.topMargin: 8
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 7

            Rectangle {
                width: 25
                height: 22
                color: hoverPrev.hovered && !root.demo ? card.ink : card.paper
                border.width: 2
                border.color: card.ink

                Text {
                    anchors.centerIn: parent
                    text: Theme.gArrowLeft
                    color: hoverPrev.hovered && !root.demo ? card.paper : card.ink
                    font.family: Theme.font
                    font.pixelSize: 12
                }

                HoverHandler {
                    id: hoverPrev
                    enabled: !root.demo
                    cursorShape: Qt.PointingHandCursor
                }
                TapHandler {
                    enabled: !root.demo
                    onTapped: {
                        if (root.player && root.player.canGoPrevious)
                            root.player.previous();
                    }
                }
            }

            Rectangle {
                width: 25
                height: 22
                color: hoverPlay.hovered && !root.demo ? card.ink : card.paper
                border.width: 2
                border.color: card.ink

                Text {
                    anchors.centerIn: parent
                    text: root.player && root.player.isPlaying ? Theme.gPause : Theme.gPlay
                    color: hoverPlay.hovered && !root.demo ? card.paper : card.ink
                    font.family: Theme.font
                    font.pixelSize: 12
                }

                HoverHandler {
                    id: hoverPlay
                    enabled: !root.demo
                    cursorShape: Qt.PointingHandCursor
                }
                TapHandler {
                    enabled: !root.demo
                    onTapped: {
                        if (root.player)
                            root.player.togglePlaying();
                    }
                }
            }

            Rectangle {
                width: 25
                height: 22
                color: hoverNext.hovered && !root.demo ? card.ink : card.paper
                border.width: 2
                border.color: card.ink

                Text {
                    anchors.centerIn: parent
                    text: Theme.gArrowRight
                    color: hoverNext.hovered && !root.demo ? card.paper : card.ink
                    font.family: Theme.font
                    font.pixelSize: 12
                }

                HoverHandler {
                    id: hoverNext
                    enabled: !root.demo
                    cursorShape: Qt.PointingHandCursor
                }
                TapHandler {
                    enabled: !root.demo
                    onTapped: {
                        if (root.player && root.player.canGoNext)
                            root.player.next();
                    }
                }
            }
        }
    }
}
