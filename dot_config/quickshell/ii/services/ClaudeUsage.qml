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
        if (samples.length < 3) {
            root.paceExhaustionAt = 0
            root.paceWillExhaustEarly = false
            return
        }

        const last = samples[samples.length - 1]
        const first = samples[0]
        // A couple of samples seconds apart produce wildly unstable slopes
        // once extrapolated over hours — require a real time baseline first.
        if ((last.t - first.t) < 3 * 60000) {
            root.paceExhaustionAt = 0
            root.paceWillExhaustEarly = false
            return
        }

        // Recency-weighted linear regression over ALL samples (not just
        // adjacent-pair deltas). A single bursty jump in used_percentage
        // (e.g. one large turn) gets diluted by the rest of the trend line
        // instead of single-handedly setting the rate, while the recency
        // decay still lets the slope lean toward the current pace.
        const halfLifeMs = 15 * 60000
        let sw = 0, swt = 0, swp = 0
        for (const s of samples) {
            const w = Math.pow(0.5, (last.t - s.t) / halfLifeMs)
            sw += w
            swt += w * s.t
            swp += w * s.pct
        }
        const tMean = swt / sw
        const pMean = swp / sw

        let num = 0, den = 0
        for (const s of samples) {
            const w = Math.pow(0.5, (last.t - s.t) / halfLifeMs)
            const dt = s.t - tMean
            num += w * dt * (s.pct - pMean)
            den += w * dt * dt
        }

        if (den <= 0) {
            root.paceExhaustionAt = 0
            root.paceWillExhaustEarly = false
            return
        }

        const ratePerMin = (num / den) * 60000
        if (ratePerMin <= 0) {
            root.paceExhaustionAt = 0
            root.paceWillExhaustEarly = false
            return
        }

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
        // Fresh singleton (e.g. quickshell just reloaded/restarted) — try to
        // resume this window's samples from disk instead of starting blank.
        if (root._lastResetsAt === "" && root._persistedResetsAt === resetsAt && root._persistedSamples.length > 0) {
            root.paceSamples = root._persistedSamples
            root._lastResetsAt = resetsAt
        }
        // New window (resetsAt changed) → drop old samples and clear the
        // stale on-disk cache right away, so the old window's data can't
        // bleed into the new one even if we crash/restart before the next
        // write below lands.
        if (root._lastResetsAt !== resetsAt) {
            root._lastResetsAt = resetsAt
            root.paceSamples = []
            root._persistedResetsAt = ""
            root._persistedSamples = []
            paceFileView.setText(JSON.stringify({ resetsAt: resetsAt, samples: [] }))
        }
        const samples = root.paceSamples.slice(0)
        samples.push({ t: now, pct: pct })
        // Keep the last 30 samples — plenty for a stable slope, bounded memory
        if (samples.length > 30) samples.shift()
        root.paceSamples = samples
        root.recomputePace()
        paceFileView.setText(JSON.stringify({ resetsAt: resetsAt, samples: samples }))
    }
    property string _lastResetsAt: ""
    property string _persistedResetsAt: ""
    property var    _persistedSamples: []

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

    // Persists paceSamples for the current window to disk so the pace
    // estimate survives a quickshell reload/restart instead of resetting.
    FileView {
        id: paceFileView
        path: Qt.resolvedUrl(FileUtils.trimFileProtocol(`${Directories.genericCache}/claude-stats/pace-samples.json`))
        onLoaded: {
            try {
                const d = JSON.parse(paceFileView.text())
                if (d && d.resetsAt && Array.isArray(d.samples)) {
                    root._persistedResetsAt = d.resetsAt
                    root._persistedSamples = d.samples
                    // Usage may have already parsed a first sample for this same
                    // window before this file finished loading — resume now.
                    if (root.fiveHourResetsAt === d.resetsAt && root.paceSamples.length <= 1) {
                        root.paceSamples = d.samples
                        root._lastResetsAt = d.resetsAt
                        root.recomputePace()
                    }
                }
            } catch (e) {
                console.warn("[ClaudeUsage] pace cache parse error:", e.message)
            }
        }
        onLoadFailed: (error) => {
            if (error !== FileViewError.FileNotFound)
                console.warn("[ClaudeUsage] pace cache load error:", error)
        }
    }
}
