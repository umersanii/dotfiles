import qs.services
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland

Scope {
    id: root

    readonly property var tabButtonList: [
        { "icon": "dashboard",  "name": "Overview" },
        { "icon": "monitoring", "name": "Models"   },
        { "icon": "terminal",   "name": "Session"  },
    ]

    // Compact state lives outside the Loader so it survives re-creation
    property bool compactMode: false
    // Dragged position offset from the default (top-right) spot; also survives re-creation
    property real dragOffsetX: 0
    property real dragOffsetY: 0

    // ═══════════════════════════════════════════════════════════════════════
    //  Window loader
    // ═══════════════════════════════════════════════════════════════════════
    Loader {
        id: windowLoader
        active: false
        onLoaded: {
            item.compact = root.compactMode
            item.offsetX = root.dragOffsetX
            item.offsetY = root.dragOffsetY
        }

        sourceComponent: PanelWindow {
            id: statsRoot
            visible: windowLoader.active

            anchors { top: true; bottom: true; left: true; right: true }

            function hide() { windowLoader.active = false }

            exclusiveZone: 0
            WlrLayershell.namespace: "quickshell:claude-stats"
            color: "transparent"

            mask: Region { item: statsBackground }

            // No GlobalFocusGrab — widget is meant to stay visible (compact mode always-on)

            // ── Filter state ───────────────────────────────────────────────
            property string filterMode: "all"

            // ── Active sessions ─────────────────────────────────────────────
            // current_usage.json: full stats for the last-active session
            property var    lastUsage:        null   // parsed current_usage.json
            // sessions/*.json: list of ALL running sessions
            property var    activeSessions:   []     // [{pid, sessionId, cwd, startedAt, kind}]
            property string credentialsEmail: ""

            // current_usage watcher
            FileView {
                id: usageFile
                path: Qt.resolvedUrl(FileUtils.trimFileProtocol(
                    `${Directories.home}/.claude/current_usage.json`))
                watchChanges: true
                onFileChanged: { this.reload(); usageParseTimer.start() }
                onLoaded: statsRoot.parseUsageFile()
            }
            Timer {
                id: usageParseTimer
                interval: 150; repeat: false
                onTriggered: statsRoot.parseUsageFile()
            }
            function parseUsageFile() {
                const raw = usageFile.text()
                if (!raw) return
                try { statsRoot.lastUsage = JSON.parse(raw) }
                catch (e) { console.warn("[ClaudeStats] usage parse:", e.message) }
            }

            // credentials: read email directly so it's available even without active sessions
            FileView {
                id: credentialsFile
                path: Qt.resolvedUrl(FileUtils.trimFileProtocol(
                    `${Directories.home}/.claude/.credentials.json`))
                onLoaded: statsRoot.parseCredentials()
            }
            function parseCredentials() {
                try {
                    const token = (JSON.parse(credentialsFile.text())?.claudeAiOauth?.accessToken ?? "")
                    const b64   = (token.split('.')[1] ?? "").replace(/-/g, '+').replace(/_/g, '/')
                    if (b64) statsRoot.credentialsEmail = JSON.parse(atob(b64))?.email ?? ""
                } catch(e) {}
            }

            // sessions poller: Python writes atomically to /tmp/claude-sessions.json
            // FileView watches via inotify — no StdioCollector accumulation issues
            FileView {
                id: sessionsFile
                path: "file:///tmp/claude-sessions.json"
                watchChanges: true
                onFileChanged: reload()
                onLoaded: {
                    const raw = text().trim()
                    if (!raw) return
                    try { statsRoot.activeSessions = JSON.parse(raw) }
                    catch(e) { console.warn("[ClaudeStats] sessions parse:", e.message) }
                }
            }
            Process {
                id: sessionsProc
                command: ["python3", "-c", "
import json,glob,os,re,subprocess,time
def to_proj(cwd): return re.sub(r'[^a-zA-Z0-9_]','-',cwd)
try:
    _prev=json.load(open('/tmp/claude-sessions.json'))
    _ecache={s['pid']:s.get('email','') for s in _prev if 'pid' in s}
except:
    _ecache={}
def check(p):
    try:
        sz=os.path.getsize(p);fh=open(p,'rb');fh.seek(max(0,sz-2048));tail=fh.read().decode('utf-8',errors='ignore');fh.close()
        lines=[l.strip() for l in tail.strip().split('\\n') if l.strip()]
        for l in reversed(lines):
            try:
                d=json.loads(l)
                t=d.get('type','')
                # a tool_use stop_reason means Claude is mid-turn (running a tool or
                # waiting on a permission prompt) — NOT idle. Only a genuine final
                # assistant reply (no pending tool call) counts as idle.
                pending_tool=t=='assistant' and d.get('message',{}).get('stop_reason')=='tool_use'
                idle=(t!='user') and not pending_tool
                mtime=int(os.path.getmtime(p)*1000)
                # give fast/auto-approved tool calls a grace period before treating
                # a stuck tool_use as \"waiting on you\" (green) instead of \"working\"
                asking=pending_tool and (int(time.time()*1000)-mtime) > 8000
                return idle,mtime,asking
            except: continue
    except: pass
    return False,0,False
def get_email(pid):
    if pid in _ecache: return _ecache[pid]
    try:
        env=open(f'/proc/{pid}/environ','rb').read().decode('utf-8',errors='ignore').split('\\x00')
        home=next((v.split('=',1)[1] for v in env if v.startswith('HOME=')),os.path.expanduser('~'))
        creds=json.load(open(os.path.join(home,'.claude','.credentials.json')))
        token=creds.get('claudeAiOauth',{}).get('accessToken','')
        if not token: return ''
        import base64
        payload=token.split('.')[1] if token.count('.')==2 else ''
        if payload:
            payload+='=='*((-len(payload))%4)
            return json.loads(base64.b64decode(payload)).get('email','')
    except: pass
    try:
        out=subprocess.check_output(['claude','auth','status','--json'],timeout=3,stderr=subprocess.DEVNULL)
        return json.loads(out).get('email','')
    except: return ''
base=os.path.expanduser('~/.claude')
result=[]
for f in glob.glob(base+'/sessions/*.json'):
    try:
        s=json.load(open(f))
        sid=s.get('sessionId','')
        jsonl=f\"{base}/projects/{to_proj(s.get('cwd',''))}/{sid}.jsonl\"
        if not os.path.exists(jsonl):
            m=glob.glob(f'{base}/projects/*/{sid}.jsonl')
            jsonl=m[0] if m else None
        if jsonl:
            idle,mtime,asking=check(jsonl)
            s['working']=not idle
            s['idleSince']=mtime if idle else 0
            s['asking']=asking
        else:
            s['working']=False;s['idleSince']=0;s['asking']=False
        s['email']=get_email(s.get('pid',0))
        result.append(s)
    except: pass
tmp='/tmp/.claude-sessions.tmp'
open(tmp,'w').write(json.dumps(result))
os.replace(tmp,'/tmp/claude-sessions.json')
"]
            }
            Timer {
                id: sessionsRefreshTimer
                interval: 1500; repeat: true; running: true
                triggeredOnStart: true
                onTriggered: { if (!sessionsProc.running) sessionsProc.running = true }
            }

            // Helper: get full usage data for a session (only available for last-active)
            function usageFor(sessionId) {
                return (lastUsage?.session_id === sessionId) ? lastUsage : null
            }

            // Walk /proc tree from Claude PID → find ancestor that is a Hyprland window → focus it
            readonly property string focusScript: "
import sys, subprocess, json
t = int(sys.argv[1])
cl = json.loads(subprocess.check_output(['hyprctl', '-j', 'clients']))
cp = {c['pid'] for c in cl}
p = t; s = set()
while p > 1 and p not in s:
    s.add(p)
    if p in cp:
        subprocess.run(['hyprctl', 'dispatch', 'focuswindow', 'pid:' + str(p)])
        break
    try:
        st = open('/proc/' + str(p) + '/status').read()
        p = int(next(l.split()[1] for l in st.splitlines() if l.startswith('PPid:')))
    except:
        break
"
            function focusSession(pid) {
                Quickshell.execDetached(["python3", "-c", focusScript, String(pid)])
                if (!compact) statsRoot.hide()
            }

            // ── Compact / full toggle ───────────────────────────────────────
            property bool compact: false
            onCompactChanged: root.compactMode = compact

            // ── Drag offset from default (top-right) position ───────────────
            property real offsetX: 0
            property real offsetY: 0
            property bool dragging: false
            onOffsetXChanged: root.dragOffsetX = offsetX
            onOffsetYChanged: root.dragOffsetY = offsetY

            // ── Clock for idle-age computation (updates every 10s) ──────────
            property real nowMs: Date.now()
            Timer {
                interval: 10000; repeat: true; running: true
                onTriggered: statsRoot.nowMs = Date.now()
            }

            // ── Session dot state: 0=working, 1=ready<5min, 2=stale, 3=asking ─
            // Claude brand orange: #D97757
            readonly property color claudeColor: "#D97757"
            readonly property color askingColor: "#4CAF50"
            function dotState(session) {
                if (session?.asking ?? false) return 3
                if (session?.working ?? false) return 0
                const idleSince = session?.idleSince ?? 0
                if (idleSince === 0) return 2
                return (nowMs - idleSince) < 300000 ? 1 : 2
            }
            function dotColor(state) {
                if (state === 3) return askingColor
                if (state === 0) return claudeColor
                if (state === 1) return Appearance.colors.colPrimary
                return Appearance.colors.colOutline
            }

            // ── Filtered stat values (single pass) ──────────────────────────
            readonly property var displayStats: {
                const _dep = ClaudeStats.dailyActivity   // track dependency
                const filtered = ClaudeStats.filteredActivity(filterMode)
                let sessions = 0, messages = 0
                for (const d of filtered) {
                    sessions += d.sessionCount ?? 0
                    messages += d.messageCount ?? 0
                }
                return { sessions, messages, activeDays: filtered.length }
            }
            // ── Account email: credentials file first, sessions fallback ─────
            readonly property string accountEmail: {
                if (credentialsEmail !== "") return credentialsEmail
                for (const s of activeSessions) {
                    const e = s.email ?? ""
                    if (e) return e
                }
                return ""
            }

            readonly property real displayTokens: {
                const dmt = ClaudeStats.dailyModelTokens
                const days = filterMode === "30d" ? 30 : filterMode === "7d" ? 7 : 0
                let cutoffStr = ""
                if (days > 0) {
                    const c = new Date()
                    c.setDate(c.getDate() - days)
                    cutoffStr = c.toISOString().split("T")[0]
                }
                let tokens = 0
                for (const d of dmt) {
                    if (cutoffStr && d.date < cutoffStr) continue
                    for (const t of Object.values(d.tokensByModel ?? {})) tokens += t
                }
                return tokens
            }

            // ── Heatmap grid (all-time, last 53 weeks) ─────────────────────
            readonly property var heatmapWeeks: {
                const lookup = {}
                let maxCount = 1
                for (const d of ClaudeStats.dailyActivity) {
                    lookup[d.date] = d.messageCount
                    if (d.messageCount > maxCount) maxCount = d.messageCount
                }
                const today  = new Date()
                const weeks  = []
                const start  = new Date(today)
                start.setDate(today.getDate() - 52 * 7)
                const dow = start.getDay()
                start.setDate(start.getDate() - (dow === 0 ? 6 : dow - 1))   // align Mon
                for (let w = 0; w < 53; w++) {
                    const days = []
                    for (let di = 0; di < 7; di++) {
                        const cell = new Date(start)
                        cell.setDate(start.getDate() + w * 7 + di)
                        const ds    = cell.toISOString().split("T")[0]
                        const count = lookup[ds] ?? 0
                        days.push({
                            date:      ds,
                            count:     count,
                            future:    cell > today,
                            intensity: count === 0 ? 0
                                : Math.max(0.18, Math.min(1.0, count / (maxCount * 0.45))),
                        })
                    }
                    weeks.push(days)
                }
                return weeks
            }

            // ── Model list sorted by output tokens ─────────────────────────
            readonly property var modelList: {
                const usage = ClaudeStats.modelUsage
                return Object.keys(usage).sort(
                    (a, b) => (usage[b]?.outputTokens ?? 0) - (usage[a]?.outputTokens ?? 0))
            }
            readonly property real maxModelTokens: {
                const usage = ClaudeStats.modelUsage
                let max = 1
                for (const m of modelList) {
                    const t = (usage[m]?.inputTokens ?? 0) + (usage[m]?.outputTokens ?? 0)
                    if (t > max) max = t
                }
                return max
            }

            // ── Pure helpers ───────────────────────────────────────────────
            function fmt(n) {
                n = Math.round(n)
                if (n >= 1e9) return (n / 1e9).toFixed(1) + "B"
                if (n >= 1e6) return (n / 1e6).toFixed(1) + "M"
                if (n >= 1e3) return Math.round(n / 1e3) + "K"
                return n.toString()
            }

            function modelName(id) {
                const map = {
                    "claude-sonnet-4-6":         "Sonnet 4.6",
                    "claude-opus-4-6":            "Opus 4.6",
                    "claude-haiku-4-5-20251001":  "Haiku 4.5",
                    "claude-haiku-4-5":           "Haiku 4.5",
                    "claude-sonnet-4-5":          "Sonnet 4.5",
                    "claude-3-5-sonnet-20241022": "Sonnet 3.5",
                    "claude-3-5-haiku-20241022":  "Haiku 3.5",
                }
                return map[id] ?? id
            }

            function funFact(tokens) {
                const facts = [
                    { t: 2000,  s: n => `That's ${fmt(n)} Wikipedia articles worth of context.`   },
                    { t: 300,   s: n => `That's like writing ${fmt(n)} emails.`                    },
                    { t: 1000,  s: n => `That's ${fmt(n)} news articles worth of reading.`         },
                    { t: 375,   s: n => `Roughly ${fmt(n)} pages of a novel.`                      },
                    { t: 70,    s: n => `That's ${fmt(n)} tweets of conversation.`                 },
                    { t: 10000, s: n => `Enough to transcribe ${fmt(n)} hours of audio.`           },
                    { t: 22000, s: n => `That's ${fmt(n)} full movie scripts.`                     },
                    { t: 400,   s: n => `Roughly ${fmt(n)} Stack Overflow answers.`                },
                    { t: 650,   s: n => `That's ${fmt(n)} college essays.`                         },
                    { t: 600,   s: n => `That's ${fmt(n)} GitHub READMEs.`                         },
                ]
                const f = facts[Math.floor(tokens / 250000) % facts.length]
                return f.s(Math.round(tokens / f.t))
            }

            // ══════════════════════════════════════════════════════════════
            //  UI
            // ══════════════════════════════════════════════════════════════
            StyledRectangularShadow { target: statsBackground }

            Rectangle {
                id: statsBackground
                color:        Appearance.colors.colLayer0Base
                border.width: 1
                border.color: Appearance.colors.colLayer0Border
                radius:       Appearance.rounding.windowRounding

                // ── Size ───────────────────────────────────────────────────
                implicitWidth:  statsRoot.compact ? 300 : mainColumn.implicitWidth + 48
                implicitHeight: statsRoot.compact ? compactCol.implicitHeight + 20 : mainColumn.implicitHeight + 32

                // ── Position: top-right corner by default, draggable via header ─
                x: parent.width - width - 20 + statsRoot.offsetX
                y: 8 + statsRoot.offsetY

                Behavior on x { enabled: !statsRoot.dragging; NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
                Behavior on y { enabled: !statsRoot.dragging; NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
                Behavior on implicitWidth  { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
                Behavior on implicitHeight { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }

                Keys.onPressed: event => {
                    if (event.key === Qt.Key_Escape) statsRoot.hide()
                }

                // ── Compact content ─────────────────────────────────────────
                ColumnLayout {
                    id: compactCol
                    visible: statsRoot.compact
                    anchors { fill: parent; margins: 10 }
                    spacing: 8

                    // Header (also the drag handle)
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 6

                        HoverHandler { cursorShape: Qt.SizeAllCursor }
                        DragHandler {
                            id: compactDragHandler
                            target: null
                            property real startOffsetX: 0
                            property real startOffsetY: 0
                            onActiveChanged: {
                                statsRoot.dragging = active
                                if (active) { startOffsetX = statsRoot.offsetX; startOffsetY = statsRoot.offsetY }
                            }
                            onTranslationChanged: {
                                statsRoot.offsetX = startOffsetX + translation.x
                                statsRoot.offsetY = startOffsetY + translation.y
                            }
                        }

                        StyledText {
                            text: "✳"
                            font.pixelSize: Appearance.font.pixelSize.normal
                            color: Appearance.colors.colPrimary
                        }
                        StyledText {
                            text: "Claude"
                            font.pixelSize: Appearance.font.pixelSize.normal
                            font.weight: Font.Medium
                            color: Appearance.colors.colOnSurface
                        }
                        StyledText {
                            text: statsRoot.activeSessions.length + " active"
                            font.pixelSize: Appearance.font.pixelSize.smaller
                            color: Appearance.colors.colOnSurfaceVariant
                        }
                        Item { Layout.fillWidth: true }
                        // Expand button
                        RippleButton {
                            implicitWidth: 28; implicitHeight: 28
                            buttonRadius: Appearance.rounding.full
                            borderWidth: 0
                            colBackground: Appearance.colors.colLayer1
                            onClicked: statsRoot.compact = false
                            contentItem: MaterialSymbol {
                                anchors.centerIn: parent
                                text: "open_in_full"
                                font.pixelSize: Appearance.font.pixelSize.normal
                                color: Appearance.colors.colOnSurface
                            }
                        }
                        RippleButton {
                            implicitWidth: 28; implicitHeight: 28
                            buttonRadius: Appearance.rounding.full
                            borderWidth: 0
                            colBackground: Appearance.colors.colLayer1
                            onClicked: statsRoot.hide()
                            contentItem: MaterialSymbol {
                                anchors.centerIn: parent
                                text: "close"
                                font.pixelSize: Appearance.font.pixelSize.normal
                                color: Appearance.colors.colOnSurface
                            }
                        }
                    }

                    // Divider
                    Rectangle {
                        Layout.fillWidth: true; height: 1
                        color: Appearance.colors.colOutlineVariant
                    }

                    // Session rows
                    Repeater {
                        model: statsRoot.activeSessions
                        delegate: ColumnLayout {
                            required property var modelData
                            required property int index
                            property var  usage: statsRoot.usageFor(modelData.sessionId)
                            property bool hasUsage: usage !== null
                            property int  dotSt: statsRoot.dotState(modelData)
                            Layout.fillWidth: true
                            spacing: 4

                            HoverHandler { id: compactCardHover; cursorShape: Qt.PointingHandCursor }
                            TapHandler   { onTapped: statsRoot.focusSession(modelData.pid) }

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 6
                                Rectangle {
                                    id: compactDot
                                    width: 7; height: 7; radius: 4
                                    color: statsRoot.dotColor(dotSt)
                                    SequentialAnimation on opacity {
                                        running: dotSt === 1
                                        loops: Animation.Infinite
                                        NumberAnimation { to: 0.25; duration: 700; easing.type: Easing.InOutSine }
                                        NumberAnimation { to: 1.0;  duration: 700; easing.type: Easing.InOutSine }
                                        onStopped: compactDot.opacity = 1
                                    }
                                }
                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 0
                                    StyledText {
                                        text: {
                                            const parts = modelData.cwd.split("/")
                                            return parts[parts.length - 1] || modelData.cwd
                                        }
                                        font.pixelSize: Appearance.font.pixelSize.small
                                        font.weight: Font.Medium
                                        color: Appearance.colors.colOnSurface
                                        elide: Text.ElideRight
                                        Layout.fillWidth: true
                                    }
                                    StyledText {
                                        visible: (modelData.email ?? "") !== ""
                                        text: modelData.email ?? ""
                                        font.pixelSize: Appearance.font.pixelSize.smallest
                                        color: Appearance.colors.colOutline
                                        elide: Text.ElideRight
                                        Layout.fillWidth: true
                                    }
                                }
                                StyledText {
                                    visible: hasUsage
                                    text: (usage?.context_window?.used_percentage ?? 0) + "%"
                                    font.pixelSize: Appearance.font.pixelSize.smaller
                                    color: (usage?.context_window?.used_percentage ?? 0) > 80
                                        ? Appearance.colors.colError
                                        : Appearance.colors.colOnSurfaceVariant
                                }
                            }

                            // Context bar
                            StyledProgressBar {
                                visible: hasUsage
                                property int pct: usage?.context_window?.used_percentage ?? 0
                                Layout.fillWidth: true
                                value: pct / 100
                                valueBarHeight: 4
                                valueBarGap: 0
                                trackColor: Appearance.colors.colLayer2
                                highlightColor: pct > 80 ? Appearance.colors.colError
                                    : pct > 60  ? Appearance.colors.colSecondary
                                    : Appearance.colors.colPrimary
                            }

                            // Divider between sessions
                            Rectangle {
                                visible: index < statsRoot.activeSessions.length - 1
                                Layout.fillWidth: true; height: 1
                                color: Appearance.colors.colOutlineVariant
                                opacity: 0.5
                            }
                        }
                    }

                    // No sessions fallback
                    StyledText {
                        visible: statsRoot.activeSessions.length === 0
                        text: "No active sessions"
                        font.pixelSize: Appearance.font.pixelSize.small
                        color: Appearance.colors.colOnSurfaceVariant
                        Layout.alignment: Qt.AlignHCenter
                    }
                }

                // ── Full content column ──────────────────────────────────────
                ColumnLayout {
                    id: mainColumn
                    visible: !statsRoot.compact
                    anchors { top: parent.top; left: parent.left; right: parent.right; topMargin: 16; leftMargin: 24; rightMargin: 24 }
                    spacing: 16

                    // ── Header ──────────────────────────────────────────────
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 6

                        // Row 1: ✳ + title + window controls (all at x=0 so content below aligns)
                        // Also doubles as the drag handle
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 8

                            HoverHandler { cursorShape: Qt.SizeAllCursor }
                            DragHandler {
                                id: fullDragHandler
                                target: null
                                property real startOffsetX: 0
                                property real startOffsetY: 0
                                onActiveChanged: {
                                    statsRoot.dragging = active
                                    if (active) { startOffsetX = statsRoot.offsetX; startOffsetY = statsRoot.offsetY }
                                }
                                onTranslationChanged: {
                                    statsRoot.offsetX = startOffsetX + translation.x
                                    statsRoot.offsetY = startOffsetY + translation.y
                                }
                            }

                            StyledText {
                                text: "✳"
                                font.pixelSize: Appearance.font.pixelSize.larger + 4
                                color: Appearance.colors.colPrimary
                            }
                            StyledText {
                                text: "What's up, Sani?"
                                font.pixelSize: Appearance.font.pixelSize.larger
                                font.weight: Font.Medium
                                color: Appearance.colors.colOnSurface
                            }
                            Item { Layout.fillWidth: true }
                            RippleButton {
                                implicitWidth: 32; implicitHeight: 32
                                buttonRadius: Appearance.rounding.full
                                borderWidth: 0
                                colBackground: Appearance.colors.colLayer1
                                onClicked: statsRoot.compact = true
                                contentItem: MaterialSymbol {
                                    anchors.centerIn: parent
                                    text: "close_fullscreen"
                                    font.pixelSize: Appearance.font.pixelSize.normal
                                    color: Appearance.colors.colOnSurface
                                }
                            }
                            RippleButton {
                                implicitWidth: 32; implicitHeight: 32
                                buttonRadius: Appearance.rounding.full
                                borderWidth: 0
                                colBackground: Appearance.colors.colLayer1
                                onClicked: statsRoot.hide()
                                contentItem: MaterialSymbol {
                                    anchors.centerIn: parent
                                    text: "close"
                                    font.pixelSize: Appearance.font.pixelSize.normal
                                    color: Appearance.colors.colOnSurface
                                }
                            }
                        }

                        // Row 2: email
                        StyledText {
                            visible: statsRoot.accountEmail !== ""
                            text: statsRoot.accountEmail
                            font.pixelSize: Appearance.font.pixelSize.smaller
                            color: Appearance.colors.colOnSurfaceVariant
                        }

                        // Row 3: fun fact left, filter chips right
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 8
                            StyledText {
                                visible: ClaudeStats.hasData
                                text: statsRoot.funFact(statsRoot.displayTokens)
                                font.pixelSize: Appearance.font.pixelSize.small
                                color: Appearance.colors.colOnSurfaceVariant
                                wrapMode: Text.Wrap
                                Layout.fillWidth: true
                            }
                            Repeater {
                                model: ["All", "30d", "7d"]
                                delegate: RippleButton {
                                    required property string modelData
                                    implicitWidth:  48
                                    implicitHeight: 28
                                    buttonRadius: Appearance.rounding.full
                                    toggled: {
                                        if (modelData === "All") return statsRoot.filterMode === "all"
                                        return statsRoot.filterMode === modelData.toLowerCase()
                                    }
                                    onClicked: {
                                        statsRoot.filterMode = (modelData === "All") ? "all" : modelData.toLowerCase()
                                    }
                                    contentItem: StyledText {
                                        text: parent.modelData
                                        horizontalAlignment: Text.AlignHCenter
                                        verticalAlignment: Text.AlignVCenter
                                        font.pixelSize: Appearance.font.pixelSize.small
                                        color: parent.toggled
                                            ? Appearance.colors.colOnPrimary
                                            : Appearance.colors.colOnSurface
                                    }
                                }
                            }
                        }
                    }

                    // ── Tab bar ─────────────────────────────────────────────
                    Toolbar {
                        Layout.alignment: Qt.AlignLeft
                        enableShadow: false
                        colBackground: "transparent"
                        ToolbarTabBar {
                            id: tabBar
                            tabButtonList: root.tabButtonList
                            onCurrentIndexChanged: swipeView.currentIndex = currentIndex
                        }
                    }

                    // ── Page content ─────────────────────────────────────────
                    SwipeView {
                        id: swipeView
                        Layout.fillWidth: true
                        interactive: false
                        clip: true
                        implicitWidth:  760
                        implicitHeight: Math.max.apply(null, contentChildren.map(c => c.implicitHeight || 0))

                        // ╔══════════════════════════════════════════════════╗
                        // ║  Overview page                                   ║
                        // ╚══════════════════════════════════════════════════╝
                        Item {
                            implicitWidth:  swipeView.width
                            implicitHeight: overviewCol.implicitHeight

                            ColumnLayout {
                                id: overviewCol
                                width: parent.width
                                spacing: 16

                                // ── Stat cards – row 1 ───────────────────────
                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: 10

                                    // Sessions
                                    Rectangle {
                                        Layout.fillWidth: true
                                        implicitHeight: 76
                                        color:        Appearance.colors.colLayer1
                                        radius:       Appearance.rounding.normal
                                        border.width: 1
                                        border.color: Appearance.colors.colLayer0Border
                                        ColumnLayout {
                                            anchors { fill: parent; margins: 12 }
                                            spacing: 2
                                            StyledText {
                                                text: "Sessions"
                                                font.pixelSize: Appearance.font.pixelSize.smaller
                                                color: Appearance.colors.colOnSurfaceVariant
                                            }
                                            StyledText {
                                                text: statsRoot.fmt(statsRoot.displayStats.sessions)
                                                font.pixelSize: Appearance.font.pixelSize.huge
                                                font.weight: Font.DemiBold
                                                color: Appearance.colors.colOnSurface
                                            }
                                        }
                                    }

                                    // Messages
                                    Rectangle {
                                        Layout.fillWidth: true
                                        implicitHeight: 76
                                        color:        Appearance.colors.colLayer1
                                        radius:       Appearance.rounding.normal
                                        border.width: 1
                                        border.color: Appearance.colors.colLayer0Border
                                        ColumnLayout {
                                            anchors { fill: parent; margins: 12 }
                                            spacing: 2
                                            StyledText {
                                                text: "Messages"
                                                font.pixelSize: Appearance.font.pixelSize.smaller
                                                color: Appearance.colors.colOnSurfaceVariant
                                            }
                                            StyledText {
                                                text: statsRoot.fmt(statsRoot.displayStats.messages)
                                                font.pixelSize: Appearance.font.pixelSize.huge
                                                font.weight: Font.DemiBold
                                                color: Appearance.colors.colOnSurface
                                            }
                                        }
                                    }

                                    // Total tokens
                                    Rectangle {
                                        Layout.fillWidth: true
                                        implicitHeight: 76
                                        color:        Appearance.colors.colLayer1
                                        radius:       Appearance.rounding.normal
                                        border.width: 1
                                        border.color: Appearance.colors.colLayer0Border
                                        ColumnLayout {
                                            anchors { fill: parent; margins: 12 }
                                            spacing: 2
                                            StyledText {
                                                text: "Total tokens"
                                                font.pixelSize: Appearance.font.pixelSize.smaller
                                                color: Appearance.colors.colOnSurfaceVariant
                                            }
                                            StyledText {
                                                text: statsRoot.fmt(statsRoot.displayTokens)
                                                font.pixelSize: Appearance.font.pixelSize.huge
                                                font.weight: Font.DemiBold
                                                color: Appearance.colors.colOnSurface
                                            }
                                        }
                                    }

                                    // Active days
                                    Rectangle {
                                        Layout.fillWidth: true
                                        implicitHeight: 76
                                        color:        Appearance.colors.colLayer1
                                        radius:       Appearance.rounding.normal
                                        border.width: 1
                                        border.color: Appearance.colors.colLayer0Border
                                        ColumnLayout {
                                            anchors { fill: parent; margins: 12 }
                                            spacing: 2
                                            StyledText {
                                                text: "Active days"
                                                font.pixelSize: Appearance.font.pixelSize.smaller
                                                color: Appearance.colors.colOnSurfaceVariant
                                            }
                                            StyledText {
                                                text: statsRoot.displayStats.activeDays.toString()
                                                font.pixelSize: Appearance.font.pixelSize.huge
                                                font.weight: Font.DemiBold
                                                color: Appearance.colors.colOnSurface
                                            }
                                        }
                                    }
                                }

                                // ── Secondary stats strip ────────────────────
                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: 20

                                    ColumnLayout {
                                        spacing: 1
                                        StyledText {
                                            text: "Streak"
                                            font.pixelSize: Appearance.font.pixelSize.smallest
                                            color: Appearance.colors.colOnSurfaceVariant
                                        }
                                        StyledText {
                                            text: ClaudeStats.currentStreak + "d"
                                            font.pixelSize: Appearance.font.pixelSize.normal
                                            font.weight: Font.Medium
                                            color: Appearance.colors.colOnSurface
                                        }
                                    }
                                    Rectangle {
                                        width: 1; implicitHeight: 28
                                        color: Appearance.colors.colOutlineVariant
                                        Layout.alignment: Qt.AlignVCenter
                                    }
                                    ColumnLayout {
                                        spacing: 1
                                        StyledText {
                                            text: "Best streak"
                                            font.pixelSize: Appearance.font.pixelSize.smallest
                                            color: Appearance.colors.colOnSurfaceVariant
                                        }
                                        StyledText {
                                            text: ClaudeStats.longestStreak + "d"
                                            font.pixelSize: Appearance.font.pixelSize.normal
                                            font.weight: Font.Medium
                                            color: Appearance.colors.colOnSurface
                                        }
                                    }
                                    Rectangle {
                                        width: 1; implicitHeight: 28
                                        color: Appearance.colors.colOutlineVariant
                                        Layout.alignment: Qt.AlignVCenter
                                    }
                                    ColumnLayout {
                                        spacing: 1
                                        StyledText {
                                            text: "Peak hour"
                                            font.pixelSize: Appearance.font.pixelSize.smallest
                                            color: Appearance.colors.colOnSurfaceVariant
                                        }
                                        StyledText {
                                            text: ClaudeStats.peakHour
                                            font.pixelSize: Appearance.font.pixelSize.normal
                                            font.weight: Font.Medium
                                            color: Appearance.colors.colOnSurface
                                        }
                                    }
                                    Rectangle {
                                        width: 1; implicitHeight: 28
                                        color: Appearance.colors.colOutlineVariant
                                        Layout.alignment: Qt.AlignVCenter
                                    }
                                    ColumnLayout {
                                        spacing: 1
                                        StyledText {
                                            text: "Top model"
                                            font.pixelSize: Appearance.font.pixelSize.smallest
                                            color: Appearance.colors.colOnSurfaceVariant
                                        }
                                        StyledText {
                                            text: statsRoot.modelName(ClaudeStats.favoriteModel)
                                            font.pixelSize: Appearance.font.pixelSize.normal
                                            font.weight: Font.Medium
                                            color: Appearance.colors.colOnSurface
                                        }
                                    }
                                    Item { Layout.fillWidth: true }
                                }

                                // ── Activity heatmap ──────────────────────────
                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 8

                                    StyledText {
                                        text: "Activity"
                                        font.pixelSize: Appearance.font.pixelSize.smaller
                                        color: Appearance.colors.colOnSurfaceVariant
                                    }

                                    // Day-of-week labels + grid in one row
                                    RowLayout {
                                        spacing: 6

                                        // Mon/Wed/Fri labels
                                        Column {
                                            spacing: 3
                                            Repeater {
                                                model: ["M", "", "W", "", "F", "", ""]
                                                StyledText {
                                                    required property string modelData
                                                    text: modelData
                                                    font.pixelSize: 9
                                                    color: Appearance.colors.colOutline
                                                    width: 10
                                                    height: 11
                                                    verticalAlignment: Text.AlignVCenter
                                                }
                                            }
                                        }

                                        // Heatmap grid
                                        Row {
                                            spacing: 3
                                            Repeater {
                                                model: statsRoot.heatmapWeeks
                                                delegate: Column {
                                                    required property var modelData  // array of 7 day objects
                                                    spacing: 3
                                                    Repeater {
                                                        model: modelData
                                                        delegate: Rectangle {
                                                            required property var modelData
                                                            width: 11; height: 11
                                                            radius: 2
                                                            color: modelData.future
                                                                ? "transparent"
                                                                : (modelData.count === 0
                                                                    ? Appearance.colors.colLayer2
                                                                    : Appearance.colors.colPrimary)
                                                            opacity: modelData.future ? 0
                                                                : (modelData.count === 0 ? 1
                                                                    : modelData.intensity)

                                                            HoverHandler { id: heatHover }
                                                            ToolTip {
                                                                visible: heatHover.hovered && !modelData.future && modelData.count > 0
                                                                text: modelData.date + " · " + modelData.count + " messages"
                                                                delay: 300
                                                            }
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }

                                // ── Divider ──────────────────────────────────
                                Rectangle {
                                    Layout.fillWidth: true
                                    height: 1
                                    color: Appearance.colors.colOutlineVariant
                                }

                                // ── Rate limits + last-updated ────────────────
                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: 16

                                    StyledText {
                                        text: "Rate limits"
                                        font.pixelSize: Appearance.font.pixelSize.smaller
                                        color: Appearance.colors.colOnSurfaceVariant
                                    }

                                    // 5-hour bar
                                    RowLayout {
                                        spacing: 6
                                        StyledText {
                                            text: "5hr"
                                            font.pixelSize: Appearance.font.pixelSize.smaller
                                            color: Appearance.colors.colOnSurfaceVariant
                                            Layout.preferredWidth: 22
                                        }
                                        StyledProgressBar {
                                            value: ClaudeUsage.fiveHourUsedPercentage
                                            valueBarWidth: 160
                                            valueBarHeight: 6
                                            valueBarGap: 0
                                            trackColor: Appearance.colors.colLayer2
                                            highlightColor: ClaudeUsage.fiveHourUsedPercentage > 0.8
                                                ? Appearance.colors.colError
                                                : Appearance.colors.colPrimary
                                        }
                                        StyledText {
                                            text: Math.round(ClaudeUsage.fiveHourUsedPercentage * 100) + "%"
                                            font.pixelSize: Appearance.font.pixelSize.smaller
                                            color: Appearance.colors.colOnSurface
                                            Layout.preferredWidth: 34
                                        }
                                        StyledText {
                                            text: ClaudeUsage.formatResetAt(ClaudeUsage.fiveHourResetsAt)
                                            font.pixelSize: Appearance.font.pixelSize.smaller
                                            color: Appearance.colors.colOutline
                                        }
                                    }

                                    // 7-day bar
                                    RowLayout {
                                        spacing: 6
                                        StyledText {
                                            text: "7d"
                                            font.pixelSize: Appearance.font.pixelSize.smaller
                                            color: Appearance.colors.colOnSurfaceVariant
                                            Layout.preferredWidth: 22
                                        }
                                        StyledProgressBar {
                                            value: ClaudeUsage.sevenDayUsedPercentage
                                            valueBarWidth: 160
                                            valueBarHeight: 6
                                            valueBarGap: 0
                                            trackColor: Appearance.colors.colLayer2
                                            highlightColor: ClaudeUsage.sevenDayUsedPercentage > 0.8
                                                ? Appearance.colors.colError
                                                : Appearance.colors.colPrimary
                                        }
                                        StyledText {
                                            text: Math.round(ClaudeUsage.sevenDayUsedPercentage * 100) + "%"
                                            font.pixelSize: Appearance.font.pixelSize.smaller
                                            color: Appearance.colors.colOnSurface
                                            Layout.preferredWidth: 34
                                        }
                                        StyledText {
                                            readonly property string _date: ClaudeUsage.formatResetDate(ClaudeUsage.sevenDayResetsAt)
                                            text: ClaudeUsage.formatResetAt(ClaudeUsage.sevenDayResetsAt) + (_date ? " · " + _date : "")
                                            font.pixelSize: Appearance.font.pixelSize.smaller
                                            color: Appearance.colors.colOutline
                                        }
                                    }

                                    Item { Layout.fillWidth: true }
                                }

                            } // overviewCol
                        } // overview page

                        // ╔══════════════════════════════════════════════════╗
                        // ║  Models page                                     ║
                        // ╚══════════════════════════════════════════════════╝
                        Item {
                            implicitWidth:  swipeView.width
                            implicitHeight: modelsCol.implicitHeight

                            ColumnLayout {
                                id: modelsCol
                                width: parent.width
                                spacing: 24

                                // No-data placeholder
                                Item {
                                    visible: !ClaudeStats.hasData
                                    Layout.fillWidth: true
                                    implicitHeight: 120
                                    StyledText {
                                        anchors.centerIn: parent
                                        text: "Run compute_claude_stats.py to load data"
                                        font.pixelSize: Appearance.font.pixelSize.normal
                                        color: Appearance.colors.colOnSurfaceVariant
                                    }
                                }

                                Repeater {
                                    model: statsRoot.modelList
                                    delegate: ColumnLayout {
                                        required property string modelData
                                        required property int    index
                                        Layout.fillWidth: true
                                        spacing: 6

                                        property var  usage:       ClaudeStats.modelUsage[modelData] ?? {}
                                        property real inOut:       (usage.inputTokens ?? 0) + (usage.outputTokens ?? 0)
                                        property real barFraction: inOut / Math.max(1, statsRoot.maxModelTokens)

                                        // Name + bar + token count
                                        RowLayout {
                                            Layout.fillWidth: true
                                            spacing: 10

                                            StyledText {
                                                text: statsRoot.modelName(modelData)
                                                font.pixelSize: Appearance.font.pixelSize.normal
                                                font.weight: Font.Medium
                                                color: Appearance.colors.colOnSurface
                                                Layout.preferredWidth: 100
                                            }

                                            StyledProgressBar {
                                                Layout.fillWidth: true
                                                value: barFraction
                                                valueBarHeight: 8
                                                valueBarGap: 0
                                                trackColor: Appearance.colors.colLayer2
                                            }

                                            StyledText {
                                                text: statsRoot.fmt(inOut)
                                                font.pixelSize: Appearance.font.pixelSize.small
                                                color: Appearance.colors.colOnSurfaceVariant
                                                Layout.preferredWidth: 56
                                                horizontalAlignment: Text.AlignRight
                                            }
                                        }

                                        // Detail breakdown
                                        StyledText {
                                            Layout.leftMargin: 110
                                            text: {
                                                const u = usage
                                                return [
                                                    `In: ${statsRoot.fmt(u.inputTokens ?? 0)}`,
                                                    `Out: ${statsRoot.fmt(u.outputTokens ?? 0)}`,
                                                    `Cache read: ${statsRoot.fmt(u.cacheReadInputTokens ?? 0)}`,
                                                    `Cache write: ${statsRoot.fmt(u.cacheCreationInputTokens ?? 0)}`,
                                                ].join("  ·  ")
                                            }
                                            font.pixelSize: Appearance.font.pixelSize.smaller
                                            color: Appearance.colors.colOutline
                                        }
                                    }
                                }
                            }
                        } // models page

                        // ╔══════════════════════════════════════════════════╗
                        // ║  Session page                                    ║
                        // ╚══════════════════════════════════════════════════╝
                        Item {
                            implicitWidth:  swipeView.width
                            implicitHeight: sessionCol.implicitHeight

                            ColumnLayout {
                                id: sessionCol
                                width: parent.width
                                spacing: 14

                                // No sessions placeholder
                                Item {
                                    visible: statsRoot.activeSessions.length === 0
                                    Layout.fillWidth: true
                                    implicitHeight: 80
                                    StyledText {
                                        anchors.centerIn: parent
                                        text: "No active Claude sessions"
                                        font.pixelSize: Appearance.font.pixelSize.normal
                                        color: Appearance.colors.colOnSurfaceVariant
                                    }
                                }

                                // One card per session
                                Repeater {
                                    model: statsRoot.activeSessions
                                    delegate: Rectangle {
                                        required property var modelData
                                        required property int index

                                        property var  usage:        statsRoot.usageFor(modelData.sessionId)
                                        property bool hasUsage:     usage !== null
                                        property bool isLastActive: hasUsage
                                        property int  dotSt:        statsRoot.dotState(modelData)

                                        Layout.fillWidth: true
                                        implicitHeight: sessionCardCol.implicitHeight + 24
                                        color: cardHover.hovered
                                            ? Appearance.colors.colLayer1Hover
                                            : Appearance.colors.colLayer1
                                        radius: Appearance.rounding.normal
                                        border.width: isLastActive ? 2 : 1
                                        border.color: isLastActive
                                            ? Appearance.colors.colPrimary
                                            : Appearance.colors.colLayer0Border

                                        HoverHandler { id: cardHover; cursorShape: Qt.PointingHandCursor }
                                        TapHandler { onTapped: statsRoot.focusSession(modelData.pid) }

                                        ColumnLayout {
                                            id: sessionCardCol
                                            anchors { fill: parent; margins: 12 }
                                            spacing: 10

                                            // ── Header row ──────────────────
                                            RowLayout {
                                                Layout.fillWidth: true
                                                spacing: 8

                                                // Working / idle dot
                                                Rectangle {
                                                    id: fullDot
                                                    width: 8; height: 8; radius: 4
                                                    color: statsRoot.dotColor(dotSt)
                                                    SequentialAnimation on opacity {
                                                        running: dotSt === 1
                                                        loops: Animation.Infinite
                                                        NumberAnimation { to: 0.3; duration: 800; easing.type: Easing.InOutSine }
                                                        NumberAnimation { to: 1.0; duration: 800; easing.type: Easing.InOutSine }
                                                        onStopped: fullDot.opacity = 1
                                                    }
                                                }

                                                // cwd
                                                StyledText {
                                                    text: modelData.cwd
                                                    font.pixelSize: Appearance.font.pixelSize.normal
                                                    font.weight: Font.Medium
                                                    color: Appearance.colors.colOnSurface
                                                    elide: Text.ElideLeft
                                                    Layout.fillWidth: true
                                                }

                                                // kind badge
                                                Rectangle {
                                                    implicitHeight: 20
                                                    implicitWidth: kindLabel.implicitWidth + 12
                                                    radius: height / 2
                                                    color: Appearance.colors.colSecondaryContainer
                                                    StyledText {
                                                        id: kindLabel
                                                        anchors.centerIn: parent
                                                        text: modelData.kind ?? "interactive"
                                                        font.pixelSize: Appearance.font.pixelSize.smallest
                                                        color: Appearance.colors.colOnSecondaryContainer
                                                    }
                                                }
                                            }

                                            // ── Sub-info (model + started) ──
                                            RowLayout {
                                                Layout.fillWidth: true
                                                spacing: 16

                                                StyledText {
                                                    text: hasUsage
                                                        ? statsRoot.modelName(usage.model?.id ?? "")
                                                        : "PID " + modelData.pid
                                                    font.pixelSize: Appearance.font.pixelSize.smaller
                                                    color: Appearance.colors.colOnSurfaceVariant
                                                }

                                                StyledText {
                                                    visible: (modelData.email ?? "") !== ""
                                                    text: modelData.email ?? ""
                                                    font.pixelSize: Appearance.font.pixelSize.smaller
                                                    color: Appearance.colors.colOutline
                                                }

                                                StyledText {
                                                    text: {
                                                        const ms = Date.now() - modelData.startedAt
                                                        const m  = Math.floor(ms / 60000)
                                                        const h  = Math.floor(m / 60)
                                                        return h > 0 ? `${h}h ${m % 60}m` : `${m}m`
                                                    }
                                                    font.pixelSize: Appearance.font.pixelSize.smaller
                                                    color: Appearance.colors.colOutline
                                                }

                                                Item { Layout.fillWidth: true }

                                                // Cost — only if we have usage data
                                                StyledText {
                                                    visible: hasUsage
                                                    text: "$" + (usage?.cost?.total_cost_usd ?? 0).toFixed(4)
                                                    font.pixelSize: Appearance.font.pixelSize.smaller
                                                    color: Appearance.colors.colOnSurface
                                                }
                                            }

                                            // ── Context bar (only last-active) ─
                                            ColumnLayout {
                                                visible: hasUsage
                                                Layout.fillWidth: true
                                                spacing: 4

                                                RowLayout {
                                                    StyledText {
                                                        text: "Context"
                                                        font.pixelSize: Appearance.font.pixelSize.smaller
                                                        color: Appearance.colors.colOnSurfaceVariant
                                                    }
                                                    Item { Layout.fillWidth: true }
                                                    StyledText {
                                                        text: (usage?.context_window?.used_percentage ?? 0) + "%  ·  "
                                                            + statsRoot.fmt(usage?.context_window?.context_window_size ?? 200000) + " ctx"
                                                        font.pixelSize: Appearance.font.pixelSize.smaller
                                                        color: Appearance.colors.colOutline
                                                    }
                                                }

                                                StyledProgressBar {
                                                    property int pct: usage?.context_window?.used_percentage ?? 0
                                                    Layout.fillWidth: true
                                                    value: pct / 100
                                                    valueBarHeight: 6
                                                    valueBarGap: 0
                                                    trackColor: Appearance.colors.colLayer2
                                                    highlightColor: pct > 80 ? Appearance.colors.colError
                                                        : pct > 60  ? Appearance.colors.colSecondary
                                                        : Appearance.colors.colPrimary
                                                }

                                                // Token breakdown
                                                RowLayout {
                                                    spacing: 16
                                                    Repeater {
                                                        model: [
                                                            { label: "In",    value: usage?.context_window?.current_usage?.input_tokens ?? 0 },
                                                            { label: "Out",   value: usage?.context_window?.current_usage?.output_tokens ?? 0 },
                                                            { label: "Cache", value: (usage?.context_window?.current_usage?.cache_read_input_tokens ?? 0)
                                                                                   + (usage?.context_window?.current_usage?.cache_creation_input_tokens ?? 0) },
                                                        ]
                                                        delegate: StyledText {
                                                            required property var modelData
                                                            text: modelData.label + ": " + statsRoot.fmt(modelData.value)
                                                            font.pixelSize: Appearance.font.pixelSize.smaller
                                                            color: Appearance.colors.colOutline
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }

                                // ── Rate limits (from last-active, shared across sessions) ─
                                Rectangle {
                                    visible: statsRoot.lastUsage !== null
                                    Layout.fillWidth: true
                                    implicitHeight: rateLimitsCol.implicitHeight + 24
                                    color: Appearance.colors.colLayer1
                                    radius: Appearance.rounding.normal
                                    border.width: 1; border.color: Appearance.colors.colLayer0Border

                                    ColumnLayout {
                                        id: rateLimitsCol
                                        anchors { fill: parent; margins: 12 }
                                        spacing: 8

                                        StyledText {
                                            text: "Rate limits (account-wide)"
                                            font.pixelSize: Appearance.font.pixelSize.smaller
                                            color: Appearance.colors.colOnSurfaceVariant
                                        }

                                        component RateLimitRow: RowLayout {
                                            property string label: ""
                                            property int    pct:   0
                                            Layout.fillWidth: true
                                            spacing: 10
                                            StyledText {
                                                text: label
                                                font.pixelSize: Appearance.font.pixelSize.small
                                                color: Appearance.colors.colOnSurfaceVariant
                                                Layout.preferredWidth: 60
                                            }
                                            StyledProgressBar {
                                                Layout.fillWidth: true
                                                value: pct / 100
                                                valueBarHeight: 7
                                                valueBarGap: 0
                                                trackColor: Appearance.colors.colLayer2
                                                highlightColor: pct > 80 ? Appearance.colors.colError : Appearance.colors.colPrimary
                                            }
                                            StyledText {
                                                text: pct + "%"
                                                font.pixelSize: Appearance.font.pixelSize.small
                                                color: Appearance.colors.colOnSurface
                                                Layout.preferredWidth: 36
                                                horizontalAlignment: Text.AlignRight
                                            }
                                        }

                                        RateLimitRow {
                                            label: "5 hour"
                                            pct: statsRoot.lastUsage?.rate_limits?.five_hour?.used_percentage ?? 0
                                        }
                                        RateLimitRow {
                                            label: "7 day"
                                            pct: statsRoot.lastUsage?.rate_limits?.seven_day?.used_percentage ?? 0
                                        }
                                    }
                                }

                            } // sessionCol
                        } // session page

                    } // SwipeView
                } // mainColumn
            } // statsBackground
        } // PanelWindow
    } // Loader

    // ═══════════════════════════════════════════════════════════════════════
    //  IPC + shortcuts
    // ═══════════════════════════════════════════════════════════════════════
    IpcHandler {
        target: "claude-stats"
        function toggle(): void { windowLoader.active = !windowLoader.active }
        function open():   void { windowLoader.active = true  }
        function close():  void { windowLoader.active = false }
    }

    GlobalShortcut {
        name: "claudeStatsToggle"
        description: "Toggle Claude stats window (cycles: closed → compact → full → closed)"
        onPressed: {
            if (!windowLoader.active) {
                root.compactMode = true
                windowLoader.active = true
                // onLoaded will apply compactMode to the item
            } else if (root.compactMode) {
                root.compactMode = false
                if (windowLoader.item) windowLoader.item.compact = false
            } else {
                windowLoader.active = false
            }
        }
    }
    GlobalShortcut {
        name: "claudeStatsOpen"
        description: "Open Claude stats window"
        onPressed: windowLoader.active = true
    }
    GlobalShortcut {
        name: "claudeStatsClose"
        description: "Close Claude stats window"
        onPressed: windowLoader.active = false
    }
}
