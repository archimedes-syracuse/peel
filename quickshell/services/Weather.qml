pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Current conditions from wttr.in. The service is intentionally quiet: if the
// request fails, the weather segment disappears instead of showing stale data.
Singleton {
    id: root

    property bool available: false
    property int tempC: 0
    property int code: 0
    property string description: ""
    property string icon: "\uF0C2"

    readonly property string label: available ? description + ", " + tempC + "°C" : ""

    function descriptionFor(weatherCode, raw) {
        if (weatherCode === 113)
            return "Clear";
        if (weatherCode === 116)
            return "Partly cloudy";
        if (weatherCode === 119 || weatherCode === 122)
            return weatherCode === 122 ? "Overcast" : "Cloudy";
        if ([143, 248, 260].indexOf(weatherCode) !== -1)
            return "Fog";

        if ([200, 386, 389, 392, 395].indexOf(weatherCode) !== -1)
            return "Storm";
        if ([179, 182, 185, 227, 230, 311, 314, 317, 320, 323, 326, 329, 332, 335, 338, 350, 362, 365, 368, 371, 374, 377].indexOf(weatherCode) !== -1)
            return "Snow";
        if ([176, 263, 266, 281, 284, 293, 296, 299, 302, 305, 308, 353, 356, 359].indexOf(weatherCode) !== -1)
            return "Rain";

        const clean = (raw || "").trim();
        return clean !== "" ? clean : "Weather";
    }

    function iconFor(weatherCode) {
        if (weatherCode === 113)
            return "\uF185";
        if ([200, 386, 389, 392, 395].indexOf(weatherCode) !== -1)
            return "\uF0E7";
        if ([179, 182, 185, 227, 230, 311, 314, 317, 320, 323, 326, 329, 332, 335, 338, 350, 362, 365, 368, 371, 374, 377].indexOf(weatherCode) !== -1)
            return "\uF2DC";
        if ([176, 263, 266, 281, 284, 293, 296, 299, 302, 305, 308, 353, 356, 359].indexOf(weatherCode) !== -1)
            return "\uF043";
        return "\uF0C2";
    }

    function parse(raw) {
        try {
            const data = JSON.parse(raw);
            const current = data.current_condition && data.current_condition[0];
            if (!current)
                return;

            const temp = parseInt(current.temp_C, 10);
            const weatherCode = parseInt(current.weatherCode, 10);
            if (isNaN(temp) || isNaN(weatherCode))
                return;

            const rawDescription = current.weatherDesc && current.weatherDesc[0]
                ? current.weatherDesc[0].value
                : "";

            root.tempC = temp;
            root.code = weatherCode;
            root.description = root.descriptionFor(weatherCode, rawDescription);
            root.icon = root.iconFor(weatherCode);
            root.available = true;
        } catch (e) {
            // Keep the last good reading; a dropped request should not clear it.
        }
    }

    Process {
        id: probe
        command: ["curl", "-sS", "--max-time", "12", "https://wttr.in/?format=j1"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: root.parse(text)
        }
    }

    Timer {
        interval: 900000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            if (!probe.running)
                probe.running = true;
        }
    }
}
