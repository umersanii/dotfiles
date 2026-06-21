pragma Singleton
pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Io
import QtQuick
import qs.modules.common

Singleton {
    id: root

    readonly property real latitude: Config.options.bar.prayerTimes.latitude
    readonly property real longitude: Config.options.bar.prayerTimes.longitude
    readonly property int method: Config.options.bar.prayerTimes.method
    readonly property int fetchInterval: Config.options.bar.prayerTimes.fetchInterval * 60 * 1000

    property var timings: ({
        Fajr:    "--:--",
        Dhuhr:   "--:--",
        Asr:     "--:--",
        Maghrib: "--:--",
        Isha:    "--:--"
    })

    property string sunrise: "--:--"

    property string nextPrayer: "Fajr"
    property string nextPrayerTime: "--:--"
    property string activePrayer: ""
    property bool _initialized: false
    property int remainingSeconds: 0

    readonly property bool isUrgent: remainingSeconds > 0 && remainingSeconds < 600
    readonly property string remainingTimeStr: formatRemaining(remainingSeconds)

    function formatRemaining(s) {
        if (s <= 0) return "";
        const h = Math.floor(s / 3600);
        const m = Math.floor((s % 3600) / 60);
        const sec = s % 60;
        if (s < 600) return `${m}m ${String(sec).padStart(2, "0")}s`;
        if (h > 0) return `${h}h ${m}m`;
        return `${m}m`;
    }

    function updateRemaining() {
        const now = new Date();
        const currentSec = now.getHours() * 3600 + now.getMinutes() * 60 + now.getSeconds();

        function toSec(t) {
            if (!t || t === "--:--") return -1;
            const p = t.split(":");
            return p.length < 2 ? -1 : parseInt(p[0]) * 3600 + parseInt(p[1]) * 60;
        }

        // Fajr is only valid until Sunrise — check the actual window, not activePrayer
        // (activePrayer only stays set for 5 min, but Fajr is valid ~1.5h until Sunrise)
        const fajrSec = toSec(root.timings.Fajr);
        const sunriseSec = toSec(root.sunrise);
        if (fajrSec >= 0 && sunriseSec >= 0 && currentSec >= fajrSec && currentSec < sunriseSec) {
            root.remainingSeconds = sunriseSec - currentSec;
            return;
        }

        // Asr is valid until 20 min before Sunset (sun starts to turn yellow)
        const asrSec = toSec(root.timings.Asr);
        const asrEndSec = toSec(root.timings.Maghrib) - 20 * 60;
        if (asrSec >= 0 && asrEndSec >= 0 && currentSec >= asrSec && currentSec < asrEndSec) {
            root.remainingSeconds = asrEndSec - currentSec;
            return;
        }

        // All other cases: count down to next prayer start
        const targetSec = toSec(root.timings[root.nextPrayer]);
        if (targetSec < 0) { root.remainingSeconds = 0; return; }
        root.remainingSeconds = targetSec > currentSec
            ? targetSec - currentSec
            : 86400 - currentSec + targetSec; // wraps to tomorrow (Isha → Fajr)
    }

    readonly property var prayerNames: ["Fajr", "Dhuhr", "Asr", "Maghrib", "Isha"]

    function subtractMinutes(t, mins) {
        if (!t || t === "--:--") return "--:--";
        const p = t.split(":");
        if (p.length < 2) return "--:--";
        let total = parseInt(p[0]) * 60 + parseInt(p[1]) - mins;
        if (total < 0) total += 1440;
        const h = Math.floor(total / 60);
        const m = total % 60;
        return `${String(h).padStart(2, "0")}:${String(m).padStart(2, "0")}`;
    }

    readonly property var prayerEndTimes: ({
        "Fajr":    root.sunrise,
        "Dhuhr":   root.timings.Asr,
        "Asr":     root.subtractMinutes(root.timings.Maghrib, 20),
        "Maghrib": root.timings.Isha,
        "Isha":    root.timings.Fajr
    })

    readonly property var prayerIcons: ({
        "Fajr":    "wb_twilight",
        "Dhuhr":   "light_mode",
        "Asr":     "partly_cloudy_day",
        "Maghrib": "bedtime",
        "Isha":    "nightlight"
    })

    // Strip any trailing timezone like " (PKT)" from time strings
    function cleanTime(raw) {
        if (!raw) return "--:--";
        return raw.substring(0, 5);
    }

    // Convert "HH:MM" (24h) to "H:MM AM/PM"
    function to12h(t) {
        if (!t || t === "--:--") return "--:--";
        const parts = t.split(":");
        if (parts.length < 2) return t;
        let h = parseInt(parts[0]);
        const m = parts[1];
        const suffix = h >= 12 ? "PM" : "AM";
        h = h % 12;
        if (h === 0) h = 12;
        return `${h}:${m} ${suffix}`;
    }

    function computeNextPrayer() {
        const now = new Date();
        const currentMinutes = now.getHours() * 60 + now.getMinutes();

        // Detect if a prayer just started (within 5-minute window)
        let active = "";
        for (const prayer of root.prayerNames) {
            const t = root.timings[prayer];
            if (!t || t === "--:--") continue;
            const parts = t.split(":");
            if (parts.length < 2) continue;
            const prayerMinutes = parseInt(parts[0]) * 60 + parseInt(parts[1]);
            if (currentMinutes >= prayerMinutes && currentMinutes < prayerMinutes + 5) {
                active = prayer;
                break;
            }
        }
        if (active !== "" && active !== root.activePrayer && root._initialized) {
            root._notifyPrayer(active);
        }
        root.activePrayer = active;

        for (const prayer of root.prayerNames) {
            const t = root.timings[prayer];
            if (!t || t === "--:--") continue;
            const parts = t.split(":");
            if (parts.length < 2) continue;
            const prayerMinutes = parseInt(parts[0]) * 60 + parseInt(parts[1]);
            if (prayerMinutes > currentMinutes) {
                root.nextPrayer = prayer;
                root.nextPrayerTime = root.to12h(t);
                root._initialized = true;
                return;
            }
        }
        // Past Isha — next is Fajr (tomorrow)
        root.nextPrayer = "Fajr";
        root.nextPrayerTime = root.to12h(root.timings.Fajr);
        root._initialized = true;
    }

    function _notifyPrayer(prayer) {
        const iconPath = "/home/sani/.config/quickshell/ii/assets/icons/fluent/";
        const notifIcons = {
            "Fajr":    iconPath + "weather-sunny.svg",
            "Dhuhr":   iconPath + "weather-sunny-filled.svg",
            "Asr":     iconPath + "weather-sunny.svg",
            "Maghrib": iconPath + "weather-moon.svg",
            "Isha":    iconPath + "weather-moon-filled.svg"
        };
        const icon = notifIcons[prayer] ?? iconPath + "weather-sunny.svg";
        const now = new Date();
        let h = now.getHours(), m = now.getMinutes();
        const ampm = h >= 12 ? "PM" : "AM";
        h = h % 12 || 12;
        const timeStr = `${h}:${String(m).padStart(2, "0")} ${ampm}`;
        prayerNotifier.command[2] = `notify-send -a "Prayer" "${prayer}" "${timeStr}" -i "${icon}" -t 10000`;
        prayerNotifier.running = true;
    }

    function getData() {
        const today = new Date();
        const day   = String(today.getDate()).padStart(2, "0");
        const month = String(today.getMonth() + 1).padStart(2, "0");
        const year  = today.getFullYear();
        const dateStr = `${day}-${month}-${year}`;
        const cmd = `curl -s --max-time 5 "https://api.aladhan.com/v1/timings/${dateStr}?latitude=${root.latitude}&longitude=${root.longitude}&method=${root.method}" | jq .`;
        fetcher.command[2] = cmd;
        fetcher.running = true;
        console.info("[PrayerTimes] Fetching times for", dateStr);
    }

    Process {
        id: prayerNotifier
        command: ["bash", "-c", ""]
    }

    Process {
        id: fetcher
        command: ["bash", "-c", ""]
        stdout: StdioCollector {
            onStreamFinished: {
                if (text.length === 0) {
                    console.warn("[PrayerTimes] Empty response");
                    return;
                }
                try {
                    const d = JSON.parse(text);
                    const t = d?.data?.timings;
                    if (!t) {
                        console.warn("[PrayerTimes] No timings in response");
                        return;
                    }
                    root.sunrise = root.cleanTime(t.Sunrise);
                    root.timings = {
                        Fajr:    root.cleanTime(t.Fajr),
                        Dhuhr:   root.cleanTime(t.Dhuhr),
                        Asr:     root.cleanTime(t.Asr),
                        Maghrib: root.cleanTime(t.Maghrib),
                        Isha:    root.cleanTime(t.Isha)
                    };
                    root.computeNextPrayer();
                    console.info("[PrayerTimes] Loaded — next:", root.nextPrayer, "@", root.nextPrayerTime);
                } catch (e) {
                    console.error("[PrayerTimes] JSON parse error:", e.message);
                }
            }
        }
    }

    // Refetch daily
    Timer {
        interval: root.fetchInterval
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.getData()
    }

    // Recompute next prayer every minute (times don't change, pointer does)
    Timer {
        interval: 60000
        running: true
        repeat: true
        onTriggered: root.computeNextPrayer()
    }

    // Update remaining countdown every second
    Timer {
        interval: 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.updateRemaining()
    }
}
