import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.Pipewire
import "theme"
import "services"
import "components"
import "overlays"

ShellRoot {
    id: root

    PwObjectTracker {
        objects: [Pipewire.defaultAudioSink]
    }

    Variants {
        model: Quickshell.screens

        TopBar {
            visible: Widgets.barVisible
                && !wallpaperPicker.visible
                && !(Mango.focusedClient && Mango.focusedClient.is_fullscreen)
        }
    }

    // Disabled: the floating x lagged behind windows on move/resize.
    // Variants {
    //     model: Quickshell.screens

    //     WindowCloseOverlay {}
    // }

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
    NotificationCenter { id: notificationCenter }
    Calendar { id: calendar }
    WallpaperPicker { id: wallpaperPicker }
    OsdOverlay {}
    NotificationDaemon {}

    IpcHandler {
        target: "shell"

        function closeFocused() {
            if (ToplevelManager.activeToplevel) {
                ToplevelManager.activeToplevel.close();
                return;
            }
            if (Mango.available)
                Mango.dispatch("killclient");
        }

        function toggleLauncher() {
            if (launcher.visible) {
                launcher.close();
                return;
            }
            power.close();
            notificationCenter.close();
            calendar.close();
            wallpaperPicker.close();
            launcher.open();
        }

        function togglePower() {
            if (power.visible) {
                power.close();
                return;
            }
            launcher.close();
            notificationCenter.close();
            calendar.close();
            wallpaperPicker.close();
            power.open();
        }

        function toggleNotifications() {
            if (notificationCenter.visible) {
                notificationCenter.close();
                return;
            }
            launcher.close();
            power.close();
            calendar.close();
            wallpaperPicker.close();
            notificationCenter.open();
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
            notificationCenter.close();
            wallpaperPicker.close();
            calendar.open();
        }

        function toggleWallpaper() {
            if (wallpaperPicker.visible) {
                wallpaperPicker.close();
                return;
            }
            launcher.close();
            power.close();
            notificationCenter.close();
            calendar.close();
            wallpaperPicker.open();
        }

        function closeOverlays() {
            launcher.close();
            power.close();
            notificationCenter.close();
            calendar.close();
            wallpaperPicker.close();
        }

        function clearNotifications() {
            Notifications.clearAll();
        }
    }
}
