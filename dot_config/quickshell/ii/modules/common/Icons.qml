pragma Singleton

// From https://github.com/caelestia-dots/shell (GPLv3)

import Quickshell

Singleton {
    id: root

    function getBluetoothDeviceMaterialSymbol(systemIconName: string): string {
        if (systemIconName.includes("headset") || systemIconName.includes("headphones"))
            return "headphones";
        if (systemIconName.includes("audio"))
            return "speaker";
        if (systemIconName.includes("phone"))
            return "smartphone";
        if (systemIconName.includes("mouse"))
            return "mouse";
        if (systemIconName.includes("keyboard"))
            return "keyboard";
        return "bluetooth";
    }

    readonly property var weatherIconMap: ({
        // wttr.in codes (legacy)
        "113": "clear_day",
        "116": "partly_cloudy_day",
        "119": "cloud",
        "122": "cloud",
        "143": "foggy",
        "176": "rainy",
        "179": "rainy",
        "182": "rainy",
        "185": "rainy",
        "200": "thunderstorm",
        "227": "cloudy_snowing",
        "230": "snowing_heavy",
        "248": "foggy",
        "260": "foggy",
        "263": "rainy",
        "266": "rainy",
        "281": "rainy",
        "284": "rainy",
        "293": "rainy",
        "296": "rainy",
        "299": "rainy",
        "302": "weather_hail",
        "305": "rainy",
        "308": "weather_hail",
        "311": "rainy",
        "314": "rainy",
        "317": "rainy",
        "320": "cloudy_snowing",
        "323": "cloudy_snowing",
        "326": "cloudy_snowing",
        "329": "snowing_heavy",
        "332": "snowing_heavy",
        "335": "snowing",
        "338": "snowing_heavy",
        "350": "rainy",
        "353": "rainy",
        "356": "rainy",
        "359": "weather_hail",
        "362": "rainy",
        "365": "rainy",
        "368": "cloudy_snowing",
        "371": "snowing",
        "374": "rainy",
        "377": "rainy",
        "386": "thunderstorm",
        "389": "thunderstorm",
        "392": "thunderstorm",
        "395": "snowing",
        // WMO codes (Open-Meteo)
        "0": "clear_day",
        "1": "clear_day",
        "2": "partly_cloudy_day",
        "3": "cloud",
        "45": "foggy",
        "48": "foggy",
        "51": "rainy",
        "53": "rainy",
        "55": "rainy",
        "56": "rainy",
        "57": "rainy",
        "61": "rainy",
        "63": "rainy",
        "65": "rainy",
        "66": "rainy",
        "67": "rainy",
        "71": "cloudy_snowing",
        "73": "cloudy_snowing",
        "75": "snowing_heavy",
        "77": "cloudy_snowing",
        "80": "rainy",
        "81": "rainy",
        "82": "weather_hail",
        "85": "cloudy_snowing",
        "86": "snowing_heavy",
        "95": "thunderstorm",
        "96": "thunderstorm",
        "99": "thunderstorm"
    })


    // Composite weather icons: a plain cloud glyph in the base color with a
    // small colored accent glyph (drop, snowflake, bolt, sun) placed next to it,
    // Google Weather style. `color` alone (no accent) tints the whole glyph —
    // used for cloudless sun/moon icons.
    // accent: { icon, color, size, cx, cy, fill, behind }
    //   size = accent icon size as fraction of the main icon size
    //   cx/cy = accent center as fractions of the glyph bounding box
    //   behind = draw accent behind the cloud (sun/moon peeking out)
    readonly property var weatherComposeMap: ({
        "clear_day": { color: "#ffb300" },
        "clear_night": { color: "#9fa8da" },
        "partly_cloudy_day": { base: "cloud", accent: { icon: "clear_day", color: "#ffb300", size: 0.55, cx: 0.74, cy: 0.26, fill: 1, behind: true } },
        "partly_cloudy_night": { base: "cloud", accent: { icon: "clear_night", color: "#9fa8da", size: 0.55, cx: 0.74, cy: 0.26, fill: 1, behind: true } },
        "rainy": { base: "cloud", accent: { icon: "water_drop", color: "#4fc3f7", size: 0.42, cx: 0.58, cy: 0.86, fill: 1 } },
        "weather_hail": { base: "cloud", accent: { icon: "water_drop", color: "#29b6f6", size: 0.42, cx: 0.58, cy: 0.86, fill: 1 } },
        "snowing": { base: "cloud", accent: { icon: "ac_unit", color: "#81d4fa", size: 0.45, cx: 0.58, cy: 0.86, fill: 0 } },
        "cloudy_snowing": { base: "cloud", accent: { icon: "ac_unit", color: "#81d4fa", size: 0.45, cx: 0.58, cy: 0.86, fill: 0 } },
        "snowing_heavy": { base: "cloud", accent: { icon: "ac_unit", color: "#b3e5fc", size: 0.5, cx: 0.56, cy: 0.87, fill: 0 } },
        "thunderstorm": { base: "cloud", accent: { icon: "bolt", color: "#ffd54f", size: 0.5, cx: 0.56, cy: 0.85, fill: 1 } }
    })

    function getWeatherIcon(code, isDay) {
        const key = String(code)
        if (weatherIconMap.hasOwnProperty(key)) {
            let icon = weatherIconMap[key]
            if (isDay === false) {
                if (icon === "clear_day") return "clear_night"
                if (icon === "partly_cloudy_day") return "partly_cloudy_night"
            }
            return icon
        }
    }
}
