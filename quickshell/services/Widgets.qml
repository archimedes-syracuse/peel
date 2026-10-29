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
    property bool notesVisible: false
    property bool barVisible: true
    property bool widgetsVisible: false
    property bool desktopIconsVisible: false
    property bool companionVisible: false
    property real companionX: 760
    property real companionY: 160
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
            // The bar is always visible: never restore a hidden state, so a stray
            // toggle can't leave it gone after a restart.
            root.barVisible = true;
            if (typeof data.widgetsVisible === "boolean") root.widgetsVisible = data.widgetsVisible;
            if (typeof data.desktopIconsVisible === "boolean") root.desktopIconsVisible = data.desktopIconsVisible;
            if (typeof data.companionVisible === "boolean") root.companionVisible = data.companionVisible;
            if (typeof data.companionX === "number") root.companionX = data.companionX;
            if (typeof data.companionY === "number") root.companionY = data.companionY;
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
            barVisible: barVisible,
            widgetsVisible: widgetsVisible,
            desktopIconsVisible: desktopIconsVisible,
            companionVisible: companionVisible,
            companionX: companionX,
            companionY: companionY,
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

    function setBarVisible(value) {
        if (barVisible === value)
            return;
        barVisible = value;
        scheduleSave();
    }

    function setWidgetsVisible(value) {
        if (widgetsVisible === value)
            return;
        widgetsVisible = value;
        scheduleSave();
    }

    function setDesktopIconsVisible(value) {
        if (desktopIconsVisible === value)
            return;
        desktopIconsVisible = value;
        scheduleSave();
    }

    function setCompanionVisible(value) {
        if (companionVisible === value)
            return;
        companionVisible = value;
        scheduleSave();
    }

    function setCompanionPosition(x, y) {
        companionX = x;
        companionY = y;
        scheduleSave();
    }

    function toggleDesktop() {
        const next = !(desktopIconsVisible || companionVisible);
        setDesktopIconsVisible(next);
        setCompanionVisible(next);
    }

    function hideChrome() {
        setBarVisible(false);
        setWidgetsVisible(false);
        setDesktopIconsVisible(false);
        setCompanionVisible(false);
    }

    function showChrome() {
        setBarVisible(true);
        setDesktopIconsVisible(true);
        setCompanionVisible(true);
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
