pragma Singleton

import qs.modules.common
import qs.modules.common.functions
import QtQuick
import Quickshell
import Quickshell.Io

/*
 * System updates service. Currently only supports Arch.
 */
Singleton {
    id: root

    property bool available: false
    property alias checking: checkUpdatesProc.running
    property int count: 0
    property int lastUpdateTimestamp: 0

    readonly property bool anyUpdates: available && count > 0
    readonly property bool updateAdvised: available && count > Config.options.updates.adviseUpdateThreshold
    readonly property bool updateStronglyAdvised: available && count > Config.options.updates.stronglyAdviseUpdateThreshold
    readonly property int daysSinceLastUpdate: lastUpdateTimestamp > 0 ? Math.floor((Date.now() / 1000 - lastUpdateTimestamp) / 86400) : 0
    readonly property bool shouldAnimate: anyUpdates && (daysSinceLastUpdate >= 14 || count > 50)

    function load() {}
    function refresh() {
        if (!available) return;
        print("[Updates] Checking for system updates")
        checkUpdatesProc.running = true;
    }

    Timer {
        interval: Config.options.updates.checkInterval * 60 * 1000
        repeat: true
        running: Config.ready
        onTriggered: {
            print("[Updates] Periodic update check due")
            root.refresh();
        }
    }

    Process {
        id: checkLastUpdateProc
        running: true
        command: ["bash", "-c", "stat -c %Y /var/lib/pacman/local"]
        stdout: StdioCollector {
            onStreamFinished: {
                root.lastUpdateTimestamp = parseInt(text.trim());
            }
        }
    }

    property string updateChecker: "checkupdates"

    Process {
        id: checkAvailabilityProc
        running: true
        command: ["bash", "-c", "if which checkupdates >/dev/null; then echo 'checkupdates'; elif which yay >/dev/null; then echo 'yay -Qu'; else exit 1; fi"]
        stdout: StdioCollector {
            onStreamFinished: {
                root.updateChecker = text.trim();
                root.available = true;
                root.refresh();
            }
        }
    }

    Process {
        id: checkUpdatesProc
        command: ["bash", "-c", `${root.updateChecker} | wc -l`]
        stdout: StdioCollector {
            onStreamFinished: {
                root.count = parseInt(text.trim());
            }
        }
    }
}
