pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property bool available: false
    property int tempC: 0
    property real feelsLikeC: 0
    property int minTempC: 0
    property int maxTempC: 0
    property real rainMM: 0
    property real rainSoFarMM: 0
    property string sunset: ""
    property int code: 0
    property string description: ""
    property string icon: "\uF0C2"

    readonly property string label: available ? description + ", " + tempC + "°C" : ""
    readonly property string advice: !available ? ""
        : minTempC < 17 ? "You'll need a jumper."
        : maxTempC >= 25 ? "Light clothes today."
        : "A light layer will do."
    readonly property string rainAdvice: !available ? ""
        : rainMM >= 0.2 ? "Bring an umbrella."
        : "No umbrella needed."

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

    function number(value, fallback) {
        const parsed = parseFloat(value);
        return isNaN(parsed) ? fallback : parsed;
    }

    function clock24(value) {
        const raw = (value || "").trim();
        const match = /^(\d{1,2}):(\d{2})\s*(AM|PM)$/i.exec(raw);
        if (!match)
            return raw;

        let hour = parseInt(match[1], 10);
        if (match[3].toUpperCase() === "PM" && hour !== 12)
            hour += 12;
        if (match[3].toUpperCase() === "AM" && hour === 12)
            hour = 0;
        return (hour < 10 ? "0" : "") + hour + ":" + match[2];
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
            const today = data.weather && data.weather[0] ? data.weather[0] : null;
            const hourly = today && today.hourly ? today.hourly : [];
            const astronomy = today && today.astronomy ? today.astronomy[0] : null;
            let rain = 0;
            for (let i = 0; i < hourly.length; i++)
                rain += number(hourly[i].precipMM, 0);

            const localHour = new Date().getHours();
            let rainSoFar = 0;
            for (let i = 0; i < hourly.length; i++) {
                const hour = number(hourly[i].time, -1) / 60;
                if (hour >= 0 && hour < localHour)
                    rainSoFar += number(hourly[i].precipMM, 0);
            }

            root.tempC = temp;
            root.feelsLikeC = number(current.FeelsLikeC, temp);
            root.minTempC = today ? Math.round(number(today.mintempC, temp)) : temp;
            root.maxTempC = today ? Math.round(number(today.maxtempC, temp)) : temp;
            root.rainMM = Math.round(rain * 10) / 10;
            root.rainSoFarMM = Math.round(rainSoFar * 10) / 10;
            root.sunset = astronomy ? root.clock24(astronomy.sunset) : "";
            root.code = weatherCode;
            root.description = root.descriptionFor(weatherCode, rawDescription);
            root.icon = root.iconFor(weatherCode);
            root.available = true;
        } catch (e) {
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
