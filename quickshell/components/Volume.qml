import QtQuick
import Quickshell.Services.Pipewire
import "../theme"

BarButton {
    id: root

    readonly property var sink: Pipewire.defaultAudioSink
    readonly property var audio: sink ? sink.audio : null
    readonly property real vol: audio ? audio.volume : 0
    readonly property bool muted: audio ? audio.muted : false

    glyph: muted ? Theme.gMuted : (vol < 0.4 ? Theme.gVolLow : Theme.gVolHigh)
    label: audio ? (muted ? "off" : Math.round(vol * 100) + "%") : "--"
    textColor: muted ? Theme.fgDim : Theme.fg
    glyphColor: muted ? Theme.fgDim : Theme.yellow

    onClicked: {
        if (audio)
            audio.muted = !audio.muted;
    }

    WheelHandler {
        onWheel: (event) => {
            if (!audio)
                return;
            const next = audio.volume + (event.angleDelta.y > 0 ? 0.05 : -0.05);
            audio.muted = false;
            audio.volume = Math.max(0, Math.min(1.5, next));
        }
    }
}
