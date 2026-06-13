pragma Singleton
pragma ComponentBehavior: Bound

import qs.modules.common
import qs.modules.common.functions
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property real premiumUsedPercentage: 0   // 0-1
    property int premiumRemaining: 0
    property int premiumEntitlement: 0
    property string resetDate: ""

    function parseUsage() {
        const raw = usageFile.text()
        if (!raw) return
        try {
            const d = JSON.parse(raw)
            const pi = d?.quota_snapshots?.premium_interactions
            if (pi) {
                root.premiumUsedPercentage = pi.unlimited ? 0 : (1 - (pi.percent_remaining / 100))
                root.premiumRemaining = pi.remaining ?? 0
                root.premiumEntitlement = pi.entitlement ?? 0
            }
            root.resetDate = d?.quota_reset_date ?? ""
        } catch (e) {
            console.warn("[CopilotUsage] parse error:", e.message)
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
        path: Qt.resolvedUrl(FileUtils.trimFileProtocol(`${Directories.genericCache}/copilot-usage.json`))
        watchChanges: true
        onFileChanged: {
            this.reload()
            readTimer.start()
        }
        onLoaded: root.parseUsage()
    }
}
