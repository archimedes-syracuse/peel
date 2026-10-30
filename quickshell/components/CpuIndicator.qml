import QtQuick
import "../theme"
import "../services"

BarButton {
    glyph: Theme.gCpu
    label: Math.round(SysStats.cpu) + "%"
    textColor: Theme.fg
    glyphColor: Theme.fgDim
}
