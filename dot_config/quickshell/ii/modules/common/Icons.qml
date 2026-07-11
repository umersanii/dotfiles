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


    // Colored accent region per weather icon. The cloud part of the glyph keeps
    // the base color; only the region below (drops, snow, bolt) or the sun/moon
    // gets tinted. rect = [x, y, w, h] as fractions of the glyph bounding box;
    // omit rect to tint the whole glyph (sun/moon icons with no cloud).
    readonly property var weatherAccentMap: ({
        "clear_day": { color: "#ffb300" },
        "clear_night": { color: "#9fa8da" },
        "partly_cloudy_day": { color: "#ffb300", rect: [0.45, 0, 0.55, 0.48] },
        "partly_cloudy_night": { color: "#9fa8da", rect: [0.45, 0, 0.55, 0.48] },
        "rainy": { color: "#4fc3f7", rect: [0, 0.55, 1, 0.45] },
        "weather_hail": { color: "#29b6f6", rect: [0, 0.55, 1, 0.45] },
        "snowing": { color: "#81d4fa", rect: [0, 0.55, 1, 0.45] },
        "cloudy_snowing": { color: "#81d4fa", rect: [0, 0.55, 1, 0.45] },
        "snowing_heavy": { color: "#81d4fa", rect: [0, 0.55, 1, 0.45] },
        "thunderstorm": { color: "#ffd54f", rect: [0, 0.5, 1, 0.5] }
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
