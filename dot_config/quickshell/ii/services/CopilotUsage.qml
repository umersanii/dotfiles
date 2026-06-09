pragma Singleton
pragma ComponentBehavior: Bound

import qs.modules.common
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    // premium_interactions: monthly limit for premium model usage
    property real premiumUsedPercentage: 0   // 0-1
    property int premiumRemaining: 0
    property int premiumEntitlement: 0
    property string resetDate: ""

    Timer {
        interval: 300000  // poll every 5 minutes
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: poller.running = true
    }

    Process {
        id: poller
        command: ["bash", "-c",
            "TOKEN=$(cat ~/.config/copilot-token 2>/dev/null | tr -d '\\n'); " +
            "curl -sf -H \"Authorization: token $TOKEN\" " +
            "-H \"Accept: application/json\" " +
            "https://api.github.com/copilot_internal/user 2>/dev/null"
        ]
        stdout: StdioCollector {
            id: pollerOut
            onStreamFinished: {
                const raw = pollerOut.text.trim()
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
        }
    }
}
