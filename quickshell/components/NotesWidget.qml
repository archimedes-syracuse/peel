import QtQuick
import "../theme"
import "../services"

// Editable retro notepad. The title bar is the drag handle; the body is a real
// TextEdit and saves into Widgets state. The arrow buttons undo/redo, and X
// hides the note until Mod+Shift+W (or the IPC toggleNotes) brings it back.
Item {
    id: root

    width: card.width + card.shadow
    height: card.height + card.shadow
    x: Widgets.notesX
    y: Widgets.notesY
    visible: Widgets.notesVisible

    onVisibleChanged: {
        if (!visible)
            noteEditor.focus = false;
    }

    function clearEditorFocus() {
        noteEditor.focus = false;
    }

    function moveBy(dx, dy) {
        const screenWidth = parent ? parent.width : 1920;
        const screenHeight = parent ? parent.height : 1080;
        const x = Math.max(8, Math.min(screenWidth - width - 8, Widgets.notesX + dx));
        const y = Math.max(Theme.barHeight + 4, Math.min(screenHeight - height - 8, Widgets.notesY + dy));
        Widgets.setNotesPosition(x, y);
    }

    RetroWindow {
        id: card
        width: 282
        height: 260
        stripHeight: 30
        paper: "#f7eb96"
        strip: "#69633f"
        ink: "#69633f"
        shadowColor: "#4d4830"
        titleTextColor: "#e3ddb0"
        title: "Notes - Notes"
        showTitle: true
        showSquares: false
        showHatch: true
        showNav: true
        draggable: true

        onDragBy: (dx, dy) => root.moveBy(dx, dy)
        onBackRequested: noteEditor.undo()
        onForwardRequested: noteEditor.redo()
        onCloseRequested: {
            noteEditor.focus = false;
            Widgets.setNotesVisible(false);
        }

        TextEdit {
            id: noteEditor
            anchors.fill: parent
            anchors.margins: 10
            text: Widgets.noteText
            color: "#5b5537"
            selectionColor: "#69633f"
            selectedTextColor: "#f7eb96"
            font.family: "Nimbus Mono PS"
            font.pixelSize: 12
            font.bold: true
            font.hintingPreference: Font.PreferFullHinting
            renderType: Text.NativeRendering
            wrapMode: TextEdit.Wrap
            selectByMouse: true
            activeFocusOnPress: true
            Keys.onEscapePressed: noteEditor.focus = false
            onTextChanged: Widgets.setNoteText(text)
        }
    }
}
