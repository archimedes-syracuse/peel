import QtQuick
import "../theme"
import "../services"

BarButton {
    glyph: Theme.gRam
    label: Math.round(SysStats.mem) + "%"
    textColor: Theme.fg
    glyphColor: Theme.fgDim
}
