import QtQuick
import qs.services
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets
import Quickshell
import Quickshell.Io

QuickToggleModel {
    id: root
    name: Translation.tr("Proton VPN")
    icon: "shield_lock"
    toggled: false
    available: false

    property bool busy: false
    property string server: "" // e.g. "NL-FREE#15"

    statusText: {
        if (busy) return toggled ? Translation.tr("Connecting…") : Translation.tr("Disconnecting…")
        if (toggled && server.length > 0) return server
        return toggled ? Translation.tr("On") : Translation.tr("Off")
    }
    tooltipText: Translation.tr("Proton VPN | Fastest free server")

    mainAction: () => {
        if (root.busy) return
        root.busy = true
        if (root.toggled) {
            root.toggled = false
            disconnectProc.running = true
        } else {
            root.toggled = true
            connectProc.running = true
        }
    }

    Timer {
        interval: 5000
        repeat: true
        running: true
        onTriggered: if (!root.busy) statusProc.running = true
    }

    // Proton's CLI brings the tunnel up as a NetworkManager wireguard connection
    // named "ProtonVPN <server>", so nmcli is a cheap way to read state
    Process {
        id: statusProc
        running: true
        command: ["nmcli", "-t", "-f", "NAME,TYPE", "connection", "show", "--active"]
        stdout: StdioCollector {
            id: statusCollector
            onStreamFinished: {
                const line = statusCollector.text.split("\n")
                    .find(l => l.startsWith("ProtonVPN") && l.endsWith(":wireguard"))
                root.toggled = line !== undefined
                root.server = line ? line.replace(/^ProtonVPN\s*/, "").replace(/:wireguard$/, "") : ""
            }
        }
    }

    Process {
        id: availableProc
        running: true
        command: ["bash", "-c", "command -v protonvpn"]
        onExited: (exitCode) => root.available = exitCode === 0
    }

    Process {
        id: connectProc
        command: ["timeout", "30", "protonvpn", "connect"]
        onExited: (exitCode) => {
            root.busy = false
            if (exitCode !== 0) {
                // Don't leave a half-up tunnel eating all traffic
                Quickshell.execDetached(["protonvpn", "disconnect"])
                Quickshell.execDetached(["notify-send", Translation.tr("Proton VPN"),
                    Translation.tr("Connection failed. Try <tt>protonvpn connect</tt> in a terminal"), "-a", "Shell"])
            }
            statusProc.running = true
        }
    }

    Process {
        id: disconnectProc
        command: ["protonvpn", "disconnect"]
        onExited: (exitCode) => {
            root.busy = false
            if (exitCode !== 0)
                Quickshell.execDetached(["notify-send", Translation.tr("Proton VPN"),
                    Translation.tr("Failed to disconnect"), "-a", "Shell"])
            statusProc.running = true
        }
    }
}
