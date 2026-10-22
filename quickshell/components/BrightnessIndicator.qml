import QtQuick
import "../theme"
import "../services"

// Backlight percentage, shown only when brightnessctl finds a device.
BarButton {
    visible: Brightness.available
    glyph: Theme.gBrightness
    label: Brightness.available ? Brightness.pct + "%" : ""
    textColor: Theme.fg
    glyphColor: Theme.yellow
}
