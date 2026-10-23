import QtQuick
import "../theme"
import "../services"

// Weather window from the supplied desktop mockup. WidgetLayer puts it on the
// wallpaper layer, below tiled windows, with live wttr.in data.
Item {
    id: root

    width: card.width + card.shadow
    height: card.height + card.shadow
    x: Widgets.weatherX
    y: Widgets.weatherY

    function moveBy(dx, dy) {
        const screenWidth = parent ? parent.width : 1920;
        const screenHeight = parent ? parent.height : 1080;
        const x = Math.max(8, Math.min(screenWidth - width - Theme.barWidth - 8, Widgets.weatherX + dx));
        const y = Math.max(Theme.gap, Math.min(screenHeight - height - 8, Widgets.weatherY + dy));
        Widgets.setWeatherPosition(x, y);
    }

    RetroWindow {
        id: card
        width: 300
        height: 118
        stripHeight: 12
        draggable: true
        onDragBy: (dx, dy) => root.moveBy(dx, dy)

        Canvas {
            anchors.left: parent.left
            anchors.leftMargin: 14
            anchors.verticalCenter: parent.verticalCenter
            width: 62
            height: 62

            onPaint: {
                const ctx = getContext("2d");
                ctx.reset();
                ctx.fillStyle = "#2e3436";
                ctx.beginPath();
                ctx.arc(31, 31, 28, 0, Math.PI * 2);
                ctx.fill();
                ctx.fillStyle = "#fdf6e3";
                ctx.beginPath();
                ctx.arc(43, 22, 26, 0, Math.PI * 2);
                ctx.fill();
            }
        }

        Column {
            anchors.left: parent.left
            anchors.leftMargin: 92
            anchors.right: parent.right
            anchors.rightMargin: 12
            anchors.verticalCenter: parent.verticalCenter
            spacing: 2

            PixelText {
                width: parent.width
                text: Weather.available
                    ? "It currently feels like " + Weather.feelsLikeC.toFixed(1) + "°C."
                    : "Waiting for weather..."
                font.pixelSize: 9
                lineHeightMode: Text.FixedHeight
                lineHeight: 11
                wrapMode: Text.Wrap
            }

            PixelText {
                width: parent.width
                visible: Weather.available
                text: "It will be " + Weather.minTempC + "°C to " + Weather.maxTempC + "°C today."
                font.pixelSize: 9
                lineHeightMode: Text.FixedHeight
                lineHeight: 11
                wrapMode: Text.Wrap
            }

            PixelText {
                width: parent.width
                visible: Weather.available
                text: Weather.advice
                font.pixelSize: 9
                lineHeightMode: Text.FixedHeight
                lineHeight: 11
                wrapMode: Text.Wrap
            }

            PixelText {
                width: parent.width
                visible: Weather.available
                text: "We've had " + Weather.rainSoFarMM.toFixed(1) + "mm rain so far. " + Weather.rainAdvice
                font.pixelSize: 9
                lineHeightMode: Text.FixedHeight
                lineHeight: 11
                wrapMode: Text.Wrap
            }

            PixelText {
                width: parent.width
                visible: Weather.available
                text: "The sun will set at " + (Weather.sunset || "--:--") + "."
                font.pixelSize: 9
                lineHeightMode: Text.FixedHeight
                lineHeight: 11
                wrapMode: Text.Wrap
            }
        }
    }
}
