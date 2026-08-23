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

    // ── Pace-based exhaustion estimate ──────────────────────────────────────
    // Samples of {t: epoch ms, pct: 0-100} taken across the current 5h window,
    // used to project when usage will hit 100% at the current burn rate.
    property var paceSamples: []
    // epoch ms projection of when 100% is reached at current pace, or 0 if
    // there aren't enough samples yet / usage is flat (no projection possible)
    property real paceExhaustionAt: 0
    // true when paceExhaustionAt falls before the window's natural reset —
    // i.e. you're on track to actually hit the cap early
    property bool paceWillExhaustEarly: false

    function recomputePace() {
        const samples = root.paceSamples
        if (samples.length < 2) {
            root.paceExhaustionAt = 0
            root.paceWillExhaustEarly = false
            return
        }

        // Recency-weighted burn rate: compute %/min for each consecutive
        // sample pair, weighting later (more recent) intervals more heavily.
        // This lets the estimate compound toward the current trend instead
        // of flattening it out with a single first-vs-last average.
        let weightedRateSum = 0
        let weightSum = 0
        for (let i = 1; i < samples.length; i++) {
            const dt = (samples[i].t - samples[i - 1].t) / 60000
            if (dt <= 0) continue
            const rate = (samples[i].pct - samples[i - 1].pct) / dt
            const weight = i
            weightedRateSum += rate * weight
            weightSum += weight
        }

        if (weightSum <= 0) {
            root.paceExhaustionAt = 0
            root.paceWillExhaustEarly = false
            return
        }

        const ratePerMin = weightedRateSum / weightSum
        if (ratePerMin <= 0) {
            root.paceExhaustionAt = 0
            root.paceWillExhaustEarly = false
            return
        }

        const last = samples[samples.length - 1]
        const minutesToFull = (100 - last.pct) / ratePerMin
        const projected = last.t + minutesToFull * 60000

        // Never project an exhaustion time past the window's own natural
        // reset — once it resets the 0-100% cap no longer applies, so a
        // projection beyond that (e.g. "8h" for a 5h window) isn't meaningful.
        const resetMs = new Date(root.fiveHourResetsAt).getTime()
        root.paceExhaustionAt = (!isNaN(resetMs) && projected > resetMs) ? resetMs : projected
        root.paceWillExhaustEarly = !isNaN(resetMs) && projected < resetMs
    }

    function recordSample(pct, resetsAt) {
        const now = Date.now()
        // New window (resetsAt changed) → drop old samples
        if (root._lastResetsAt !== resetsAt) {
            root._lastResetsAt = resetsAt
            root.paceSamples = []
        }
        const samples = root.paceSamples.slice(0)
        samples.push({ t: now, pct: pct })
        // Keep the last 30 samples — plenty for a stable slope, bounded memory
        if (samples.length > 30) samples.shift()
        root.paceSamples = samples
        root.recomputePace()
    }
    property string _lastResetsAt: ""

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
        const months = ["Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sep","Oct","Nov","Dec"]
        return months[d.getMonth()] + " " + d.getDate()
    }

    function parseUsage() {
        const raw = usageFile.text()
        if (!raw) return
        try {
            const d = JSON.parse(raw)
            // current_usage.json is the raw Claude Code statusline payload —
            // rate_limits come straight from Claude Code itself, no network
            // fetch involved, so this can't go stale from an API timeout.
            const fiveHour   = d?.rate_limits?.five_hour ?? null
            const sevenDay   = d?.rate_limits?.seven_day ?? null
            const sessionUsage   = fiveHour?.used_percentage ?? 0
            const sessionResetAt = fiveHour?.resets_at ? new Date(fiveHour.resets_at * 1000).toISOString() : ""
            root.fiveHourUsedPercentage = sessionUsage / 100
            root.sevenDayUsedPercentage = (sevenDay?.used_percentage ?? 0) / 100
            root.fiveHourResetsAt = sessionResetAt
            root.sevenDayResetsAt = sevenDay?.resets_at ? new Date(sevenDay.resets_at * 1000).toISOString() : ""
            if (sessionResetAt) root.recordSample(sessionUsage, sessionResetAt)
        } catch (e) {
            console.warn("[ClaudeUsage] parse error:", e.message)
        }
    }

    // "Xh Ym" / "Ym" until paceExhaustionAt, or "" if no projection yet
    function formatPaceEta() {
        if (!root.paceExhaustionAt) return ""
        const diff = root.paceExhaustionAt - Date.now()
        if (diff <= 0) return "now"
        const totalMin = Math.round(diff / 60000)
        const h = Math.floor(totalMin / 60)
        const m = totalMin % 60
        return h > 0 ? `${h}h ${m}m` : `${m}m`
    }

    // Wall-clock HH:MM for paceExhaustionAt, or "" if no projection yet
    function formatPaceAtTime() {
        if (!root.paceExhaustionAt) return ""
        return new Date(root.paceExhaustionAt).toLocaleTimeString([], { hour: "2-digit", minute: "2-digit", hour12: false })
    }

    Timer {
        id: readTimer
        interval: 100
        repeat: false
        onTriggered: root.parseUsage()
    }

    FileView {
        id: usageFile
        path: Qt.resolvedUrl(FileUtils.trimFileProtocol(`${Directories.home}/.claude/current_usage.json`))
        watchChanges: true
        onFileChanged: {
            this.reload()
            readTimer.start()
        }
        onLoaded: root.parseUsage()
    }
}
