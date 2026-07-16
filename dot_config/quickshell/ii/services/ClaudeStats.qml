pragma Singleton
pragma ComponentBehavior: Bound

import qs.modules.common
import qs.modules.common.functions
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    // ── Raw data ────────────────────────────────────────────────────────────
    property var rawData: null
    readonly property bool hasData: rawData !== null

    // ── All-time totals (exposed for convenience) ────────────────────────────
    readonly property int    totalSessions:  rawData?.totalSessions  ?? 0
    readonly property int    totalMessages:  rawData?.totalMessages  ?? 0
    readonly property int    currentStreak:  rawData?.currentStreak  ?? 0
    readonly property int    longestStreak:  rawData?.longestStreak  ?? 0
    readonly property string favoriteModel:  rawData?.favoriteModel  ?? ""
    readonly property string lastComputedDate: rawData?.lastComputedDate ?? ""

    readonly property var dailyActivity:    rawData?.dailyActivity    ?? []
    readonly property var dailyModelTokens: rawData?.dailyModelTokens ?? []
    readonly property var modelUsage:       rawData?.modelUsage       ?? {}
    readonly property var hourCounts:       rawData?.hourCounts       ?? {}

    readonly property int activeDays: dailyActivity.length

    // ── Derived: peak hour label ─────────────────────────────────────────────
    readonly property string peakHour: {
        const hc = rawData?.hourCounts
        if (!hc) return "--"
        let maxCount = 0, peakH = -1
        for (const [h, count] of Object.entries(hc)) {
            if (count > maxCount) { maxCount = count; peakH = parseInt(h) }
        }
        if (peakH < 0)    return "--"
        if (peakH === 0)  return "12 AM"
        if (peakH === 12) return "12 PM"
        return peakH < 12 ? `${peakH} AM` : `${peakH - 12} PM`
    }

    // ── Helpers (called from QML window) ────────────────────────────────────

    // Return filtered slice of dailyActivity
    function filteredActivity(filter) {
        const all = rawData?.dailyActivity ?? []
        if (filter === "all") return all
        const days = filter === "30d" ? 30 : 7
        const cutoff = new Date()
        cutoff.setDate(cutoff.getDate() - days)
        const cutoffStr = cutoff.toISOString().split("T")[0]
        return all.filter(d => d.date >= cutoffStr)
    }

    // ── File watcher ─────────────────────────────────────────────────────────
    FileView {
        id: statsFile
        path: Qt.resolvedUrl(FileUtils.trimFileProtocol(
            `${Directories.genericCache}/claude-stats/stats.json`))
        watchChanges: true
        onFileChanged: { this.reload(); parseTimer.start() }
        onLoaded: root.parseStats()
    }

    Timer {
        id: parseTimer
        interval: 100
        repeat: false
        onTriggered: root.parseStats()
    }

    function parseStats() {
        const raw = statsFile.text()
        if (!raw) return
        try {
            root.rawData = JSON.parse(raw)
        } catch (e) {
            console.warn("[ClaudeStats] parse error:", e.message)
        }
    }
}
