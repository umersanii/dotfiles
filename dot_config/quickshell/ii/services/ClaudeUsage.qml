pragma Singleton
pragma ComponentBehavior: Bound

import qs.modules.common
import qs.modules.common.functions
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property real fiveHourUsedPercentage: 0   // 0-1
    property real sevenDayUsedPercentage: 0   // 0-1
    property string fiveHourResetsAt: ""      // ISO date string
    property string sevenDayResetsAt: ""      // ISO date string

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

    function parseUsage() {
        const raw = usageFile.text()
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

    Timer {
        id: readTimer
        interval: 100
        repeat: false
        onTriggered: root.parseUsage()
    }

    FileView {
        id: usageFile
        path: Qt.resolvedUrl(FileUtils.trimFileProtocol(`${Directories.genericCache}/ccstatusline/usage.json`))
        watchChanges: true
        onFileChanged: {
            this.reload()
            readTimer.start()
        }
        onLoaded: root.parseUsage()
    }
}
