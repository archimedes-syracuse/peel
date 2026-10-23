pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.Pipewire

// Shared state for the transient volume/brightness overlay. Audio changes
// arrive immediately through Pipewire; brightness is sampled by its service.
Singleton {
    id: root

    property bool shown: false
    property string kind: ""
    property int pct: 0
    property bool muted: false
    property bool armed: false

    readonly property var sink: Pipewire.defaultAudioSink
    readonly property var audio: sink ? sink.audio : null

    function showVolume() {
        if (!armed || !audio)
            return;
        kind = "volume";
        pct = Math.round(audio.volume * 100);
        muted = audio.muted;
        shown = true;
        hide.restart();
    }

    function showBrightness() {
        if (!armed || !Brightness.available)
            return;
        kind = "brightness";
        pct = Brightness.pct;
        muted = false;
        shown = true;
        hide.restart();
    }

    Connections {
        target: root.audio
        ignoreUnknownSignals: true

        function onVolumeChanged() {
            root.showVolume();
        }

        function onMutedChanged() {
            root.showVolume();
        }
    }

    Connections {
        target: Brightness

        function onPctChanged() {
            root.showBrightness();
        }
    }

    Timer {
        id: arm
        interval: 1200
        running: true
        onTriggered: root.armed = true
    }

    Timer {
        id: hide
        interval: 1600
        onTriggered: root.shown = false
    }
}
