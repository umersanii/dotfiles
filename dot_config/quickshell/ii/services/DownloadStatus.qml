pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property bool active: false
    property string name: ""
    property real progress: 0       // -1 means indeterminate (Firefox/Zen)
    property real downloadedBytes: 0
    property real totalBytes: 0
    readonly property bool hasProgress: active && progress >= 0

    Timer {
        interval: 2000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: checkProc.running = true
    }

    Process {
        id: checkProc
        command: [Quickshell.shellPath("scripts/download-status.sh")]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const d = JSON.parse(text.trim())
                    root.active = d.active ?? false
                    root.name = d.name ?? ""
                    root.progress = d.progress ?? 0
                    root.downloadedBytes = d.downloaded ?? 0
                    root.totalBytes = d.total ?? 0
                } catch(e) {
                    root.active = false
                }
            }
        }
    }
}
