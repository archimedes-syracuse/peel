import QtQuick
import "../theme"
import "../services"

// CPU load readout, updated by the shared SysStats sampler.
BarButton {
    glyph: Theme.gCpu
    label: Math.round(SysStats.cpu) + "%"
    textColor: Theme.fg
    glyphColor: Theme.fgDim
}
