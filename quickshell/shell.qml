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

        BottomBar {
            visible: Widgets.barVisible
        }
    }

    Variants {
        model: Quickshell.screens

        DesktopIcons {
            visible: Widgets.desktopIconsVisible
        }
    }

    Variants {
        model: Quickshell.screens

        Companion {
            visible: Widgets.companionVisible
        }
    }

    Variants {
        model: Quickshell.screens

        WidgetLayer {
            visible: Widgets.widgetsVisible
        }
    }

    Launcher { id: launcher }
    PowerMenu { id: power }
    ControlCenter { id: controlCenter }
    NotificationCenter { id: notificationCenter }
    Calendar { id: calendar }
    OsdOverlay {}
    NotificationDaemon {}

    IpcHandler {
        target: "shell"

        function toggleLauncher() {
            if (launcher.visible) {
                launcher.close();
                return;
            }
            power.close();
            controlCenter.close();
            notificationCenter.close();
            calendar.close();
            launcher.open();
        }

        function togglePower() {
            if (power.visible) {
                power.close();
                return;
            }
            launcher.close();
            controlCenter.close();
            notificationCenter.close();
            calendar.close();
            power.open();
        }

        function toggleNotifications() {
            if (notificationCenter.visible) {
                notificationCenter.close();
                return;
            }
            launcher.close();
            power.close();
            controlCenter.close();
            calendar.close();
            notificationCenter.open();
        }

        function toggleControl() {
            if (controlCenter.visible) {
                controlCenter.close();
                return;
            }
            launcher.close();
            power.close();
            notificationCenter.close();
            calendar.close();
            controlCenter.open();
        }

        function toggleNotes() {
            Widgets.setNotesVisible(!Widgets.notesVisible);
        }

        function toggleBar() {
            Widgets.setBarVisible(!Widgets.barVisible);
        }

        function toggleWidgets() {
            Widgets.setWidgetsVisible(!Widgets.widgetsVisible);
        }

        function toggleDesktop() {
            Widgets.toggleDesktop();
        }

        function toggleCompanion() {
            Widgets.setCompanionVisible(!Widgets.companionVisible);
        }

        function toggleIcons() {
            Widgets.setDesktopIconsVisible(!Widgets.desktopIconsVisible);
        }

        function hideChrome() {
            Widgets.hideChrome();
        }

        function showChrome() {
            Widgets.showChrome();
        }

        function toggleChrome() {
            if (Widgets.barVisible || Widgets.desktopIconsVisible || Widgets.companionVisible)
                Widgets.hideChrome();
            else
                Widgets.showChrome();
        }

        function toggleCalendar() {
            if (calendar.visible) {
                calendar.close();
                return;
            }
            launcher.close();
            power.close();
            controlCenter.close();
            notificationCenter.close();
            calendar.open();
        }

        function closeOverlays() {
            launcher.close();
            power.close();
            controlCenter.close();
            notificationCenter.close();
            calendar.close();
        }

        function clearNotifications() {
            Notifications.clearAll();
        }
    }
}
