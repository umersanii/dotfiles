pragma Singleton
pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Io
import QtQuick
import QtPositioning

import qs.modules.common

Singleton {
    id: root
    // 10 minute
    readonly property int fetchInterval: Config.options.bar.weather.fetchInterval * 60 * 1000
    readonly property string city: Config.options.bar.weather.city
    readonly property bool useUSCS: Config.options.bar.weather.useUSCS
    property bool gpsActive: Config.options.bar.weather.enableGPS

    onUseUSCSChanged: {
        root.getData();
    }
    onCityChanged: {
        root.getData();
    }

    property var location: ({
        valid: false,
        lat: 0,
        lon: 0
    })

    property var data: ({
        uv: 0,
        humidity: 0,
        sunrise: 0,
        sunset: 0,
        windDir: 0,
        wCode: 0,
        city: 0,
        wind: 0,
        precip: 0,
        visib: 0,
        press: 0,
        temp: 0,
        tempFeelsLike: 0,
        lastRefresh: 0,
    })

    readonly property var cityCoordinates: ({
        "islamabad": { lat: 33.6844, lon: 73.0479 },
        "karachi": { lat: 24.8607, lon: 67.0011 },
        "lahore": { lat: 31.5204, lon: 74.3587 },
        "rawalpindi": { lat: 33.5731, lon: 73.1898 },
        "faisalabad": { lat: 31.4181, lon: 72.9881 },
        "multan": { lat: 30.1575, lon: 71.4388 },
        "hyderabad": { lat: 25.3928, lon: 68.3829 },
        "peshawar": { lat: 34.0223, lon: 71.5789 },
        "quetta": { lat: 30.1798, lon: 66.9750 },
        "gilgit": { lat: 35.9206, lon: 74.3114 },
        "srinagar": { lat: 34.0841, lon: 75.5999 },
        "new york": { lat: 40.7128, lon: -74.0060 },
        "london": { lat: 51.5074, lon: -0.1278 },
        "paris": { lat: 48.8566, lon: 2.3522 },
        "tokyo": { lat: 35.6762, lon: 139.6503 },
        "sydney": { lat: -33.8688, lon: 151.2093 },
        "dubai": { lat: 25.2048, lon: 55.2708 },
        "singapore": { lat: 1.3521, lon: 103.8198 }
    })

    function getCityCoordinates(cityName) {
        const key = cityName.toLowerCase().trim();
        if (root.cityCoordinates.hasOwnProperty(key)) {
            return root.cityCoordinates[key];
        }
        // Default to Islamabad if city not found
        return root.cityCoordinates["islamabad"];
    }

    function refineData(data) {
        let temp = {};
        // Handle both wttr.in and Open-Meteo formats
        if (data?.current) {
            // Check if it's wttr.in format (has uvIndex) or Open-Meteo format (has temperature)
            if (typeof data.current.temperature !== 'undefined') {
                // Open-Meteo format
                const current = data.current;
                const hourly = data?.hourly;
                const daily = data?.daily;
                
                temp.city = root.city || "Location";
                temp.wCode = current.weather_code || 0;
                temp.windDir = "N"; // TODO: improve wind direction
                temp.humidity = hourly?.relative_humidity_2m?.[0] || 0;
                if (typeof temp.humidity === 'number') {
                    temp.humidity = Math.round(temp.humidity) + "%";
                }
                
                // Extract sunrise/sunset times (format: "2026-02-16T06:51" -> "06:51")
                if (daily?.sunrise?.[0]) {
                    const sunriseStr = daily.sunrise[0];
                    temp.sunrise = sunriseStr.substring(11, 16);
                } else {
                    temp.sunrise = "--:--";
                }
                if (daily?.sunset?.[0]) {
                    const sunsetStr = daily.sunset[0];
                    temp.sunset = sunsetStr.substring(11, 16);
                } else {
                    temp.sunset = "--:--";
                }
                
                if (root.useUSCS) {
                    const tempF = Math.round(current.temperature * 9/5 + 32);
                    temp.temp = tempF + "°F";
                    temp.tempFeelsLike = tempF + "°F";
                    temp.wind = Math.round(current.windspeed * 0.621371) + " mph";
                } else {
                    temp.temp = Math.round(current.temperature) + "°C";
                    temp.tempFeelsLike = Math.round(current.temperature) + "°C";
                    temp.wind = Math.round(current.windspeed) + " km/h";
                }
                temp.uv = "--";
                temp.precip = "--";
                temp.visib = "--";
                temp.press = "--";
            } else {
                // wttr.in format
                temp.uv = data?.current?.uvIndex || 0;
                temp.humidity = (data?.current?.humidity || 0) + "%";
                temp.sunrise = data?.astronomy?.sunrise || "0.0";
                temp.sunset = data?.astronomy?.sunset || "0.0";
                temp.windDir = data?.current?.winddir16Point || "N";
                temp.wCode = data?.current?.weatherCode || "113";
                temp.city = data?.location?.areaName[0]?.value || "City";
                temp.temp = "";
                temp.tempFeelsLike = "";
                if (root.useUSCS) {
                    temp.wind = (data?.current?.windspeedMiles || 0) + " mph";
                    temp.precip = (data?.current?.precipInches || 0) + " in";
                    temp.visib = (data?.current?.visibilityMiles || 0) + " m";
                    temp.press = (data?.current?.pressureInches || 0) + " psi";
                    temp.temp += (data?.current?.temp_F || 0);
                    temp.tempFeelsLike += (data?.current?.FeelsLikeF || 0);
                    temp.temp += "°F";
                    temp.tempFeelsLike += "°F";
                } else {
                    temp.wind = (data?.current?.windspeedKmph || 0) + " km/h";
                    temp.precip = (data?.current?.precipMM || 0) + " mm";
                    temp.visib = (data?.current?.visibility || 0) + " km";
                    temp.press = (data?.current?.pressure || 0) + " hPa";
                    temp.temp += (data?.current?.temp_C || 0);
                    temp.tempFeelsLike += (data?.current?.FeelsLikeC || 0);
                    temp.temp += "°C";
                    temp.tempFeelsLike += "°C";
                }
            }
        }
        
        temp.lastRefresh = DateTime.time + " • " + DateTime.date;
        root.data = temp;
    }

    function getData() {
        let lat, lon;
        
        if (root.gpsActive && root.location.valid) {
            lat = root.location.lat;
            lon = root.location.long;
        } else {
            const coords = getCityCoordinates(root.city);
            lat = coords.lat;
            lon = coords.lon;
        }
        
        // Use Open-Meteo API (fast, no rate limits, no auth required)
        let command = `curl -s --max-time 3 "https://api.open-meteo.com/v1/forecast?latitude=${lat}&longitude=${lon}&current=temperature,weather_code,windspeed&hourly=relative_humidity_2m&daily=sunrise,sunset&temperature_unit=celsius&timezone=auto" | jq .`;
        
        fetcher.command[2] = command;
        fetcher.running = true;
        console.info(`[WeatherService] Fetching weather for lat=${lat}, lon=${lon}`);
    }

    Component.onCompleted: {
        if (!root.gpsActive) return;
        console.info("[WeatherService] Starting the GPS service.");
        positionSource.start();
    }

    Process {
        id: fetcher
        command: ["bash", "-c", ""]
        stdout: StdioCollector {
            onStreamFinished: {
                if (text.length === 0) {
                    console.warn("[WeatherService] Empty response from weather API");
                    return;
                }
                try {
                    const parsedData = JSON.parse(text);
                    root.refineData(parsedData);
                    console.info(`[WeatherService] Weather data updated for ${root.city}`);
                } catch (e) {
                    console.error(`[WeatherService] JSON parse error: ${e.message}`);
                    console.error(`[WeatherService] Response: ${text.substring(0, 200)}`);
                }
            }
        }
    }

    PositionSource {
        id: positionSource
        updateInterval: root.fetchInterval

        onPositionChanged: {
            // update the location if the given location is valid
            // if it fails getting the location, use the last valid location
            if (position.latitudeValid && position.longitudeValid) {
                root.location.lat = position.coordinate.latitude;
                root.location.long = position.coordinate.longitude;
                root.location.valid = true;
                // console.info(`📍 Location: ${position.coordinate.latitude}, ${position.coordinate.longitude}`);
                root.getData();
                // if can't get initialized with valid location deactivate the GPS
            } else {
                root.gpsActive = root.location.valid ? true : false;
                console.error("[WeatherService] Failed to get the GPS location.");
            }
        }

        onValidityChanged: {
            if (!positionSource.valid) {
                positionSource.stop();
                root.location.valid = false;
                root.gpsActive = false;
                Quickshell.execDetached(["notify-send", Translation.tr("Weather Service"), Translation.tr("Cannot find a GPS service. Using the fallback method instead."), "-a", "Shell"]);
                console.error("[WeatherService] Could not aquire a valid backend plugin.");
            }
        }
    }

    Timer {
        running: !root.gpsActive
        repeat: true
        interval: root.fetchInterval
        triggeredOnStart: !root.gpsActive
        onTriggered: root.getData()
    }
}
