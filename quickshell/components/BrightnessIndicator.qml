import QtQuick
import "../theme"
import "../services"

BarButton {
    visible: Brightness.available
    glyph: Theme.gBrightness
    label: Brightness.available ? Brightness.pct + "%" : ""
    textColor: Theme.fg
    glyphColor: Theme.yellow
}
