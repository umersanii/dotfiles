pragma Singleton
pragma ComponentBehavior: Bound

import qs.modules.common
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property real fiveHourUsedPercentage: 0   // 0-1
    property real sevenDayUsedPercentage: 0   // 0-1
    property string fiveHourResetsAt: ""      // ISO date string
    property string sevenDayResetsAt: ""      // ISO date string

    // sessionResetAt / weeklyResetAt are ISO strings from ccstatusline
    function formatResetAt(isoString) {
        if (!isoString) return "?"
        const d = new Date(isoString)
        if (isNaN(d.getTime())) return "?"
        if (d.getTime() <= Date.now()) return "now"
        return d.toLocaleTimeString([], { hour: "2-digit", minute: "2-digit", hour12: false })
    }

    function formatResetDate(isoString) {
        if (!isoString) return ""
        const d = new Date(isoString)
        if (isNaN(d.getTime())) return ""
        if (d.getTime() <= Date.now()) return ""
        return d.toLocaleDateString([], { month: "short", day: "numeric" })
    }

    Timer {
        interval: 60000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: poller.running = true
    }

    // Reads ~/.cache/ccstatusline/usage.json — kept fresh (≤3 min) by ccstatusline's
    // OAuth API call to api.anthropic.com/api/oauth/usage during active sessions.
    Process {
        id: poller
        command: ["bash", "-c", "cat ~/.cache/ccstatusline/usage.json 2>/dev/null"]
        stdout: StdioCollector {
            id: pollerOut
            onStreamFinished: {
                const raw = pollerOut.text.trim()
                if (!raw) return
                try {
                    const d = JSON.parse(raw)
                    root.fiveHourUsedPercentage = (d?.sessionUsage ?? 0) / 100
                    root.sevenDayUsedPercentage = (d?.weeklyUsage ?? 0) / 100
                    root.fiveHourResetsAt = d?.sessionResetAt ?? ""
                    root.sevenDayResetsAt = d?.weeklyResetAt ?? ""
                } catch (e) {
                    console.warn("[ClaudeUsage] parse error:", e.message)
                }
            }
        }
    }
}
