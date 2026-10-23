pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Persistent desktop-widget state: positions, visibility and the editable note.
// Stored in Quickshell's per-shell state directory so config reloads and shell
// restarts keep the desktop arrangement.
Singleton {
    id: root

    readonly property string filePath: Quickshell.statePath("widgets.json")
    readonly property string defaultNote: "greys:\n"
        + "#edeceb\n"
        + "#dcdad\n"
        + "#d4cfc7\n"
        + "#d3d7cf\n"
        + "#d3d3dd\n"
        + "\n"
        + "---motif colours / xfce stellar ---\n"
        + "#aeb2c3, #9ba0b0, #b24d7a,\n"
        + "#7b7691\n"
        + "--------------------------------"

    property real weatherX: 32
    property real weatherY: 48
    property real musicX: 352
    property real musicY: 134
    property real notesX: 32
    property real notesY: 184
    property bool notesVisible: true
    property string noteText: defaultNote

    function load() {
        try {
            const data = JSON.parse(store.text());
            if (!data)
                return;

            if (typeof data.weatherX === "number") root.weatherX = data.weatherX;
            if (typeof data.weatherY === "number") root.weatherY = data.weatherY;
            if (typeof data.musicX === "number") root.musicX = data.musicX;
            if (typeof data.musicY === "number") root.musicY = data.musicY;
            if (typeof data.notesX === "number") root.notesX = data.notesX;
            if (typeof data.notesY === "number") root.notesY = data.notesY;
            if (typeof data.notesVisible === "boolean") root.notesVisible = data.notesVisible;
            if (typeof data.noteText === "string") root.noteText = data.noteText;
        } catch (e) {
            // Missing/corrupt state is fine: defaults are the initial layout.
        }
    }

    function scheduleSave() {
        saveTimer.restart();
    }

    function saveNow() {
        store.setText(JSON.stringify({
            weatherX: weatherX,
            weatherY: weatherY,
            musicX: musicX,
            musicY: musicY,
            notesX: notesX,
            notesY: notesY,
            notesVisible: notesVisible,
            noteText: noteText
        }, null, 2));
    }

    function setWeatherPosition(x, y) {
        weatherX = x;
        weatherY = y;
        scheduleSave();
    }

    function setMusicPosition(x, y) {
        musicX = x;
        musicY = y;
        scheduleSave();
    }

    function setNotesPosition(x, y) {
        notesX = x;
        notesY = y;
        scheduleSave();
    }

    function setNoteText(text) {
        if (noteText === text)
            return;
        noteText = text;
        scheduleSave();
    }

    function setNotesVisible(value) {
        if (notesVisible === value)
            return;
        notesVisible = value;
        scheduleSave();
    }

    FileView {
        id: store
        path: root.filePath
        blockLoading: true
        watchChanges: false
        onLoaded: root.load()
    }

    Timer {
        id: saveTimer
        interval: 250
        onTriggered: root.saveNow()
    }
}
