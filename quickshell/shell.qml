import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire
import "theme"
import "services"
import "components"
import "overlays"

// Entry point. Run with: qs -c niri
ShellRoot {
    id: root

    // Keep the default sink alive even when no Volume widget is visible.
    PwObjectTracker {
        objects: [Pipewire.defaultAudioSink]
    }

    Variants {
        model: Quickshell.screens

        Bar {}
    }

    Launcher { id: launcher }
    PowerMenu { id: power }
    NotificationDaemon {}

    IpcHandler {
        target: "shell"

        function toggleLauncher() {
            launcher.toggle();
        }

        function togglePower() {
            power.toggle();
        }

        function closeOverlays() {
            launcher.close();
            power.close();
        }
    }
}
