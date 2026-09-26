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
    tooltipText: Translation.tr("Proton VPN | Right-click to pick a country")
    hasMenu: true

    // Countries with free-tier servers: [{ code: "NL", count: 40, cities: "Amsterdam" }]
    property var freeCountries: []
    readonly property string currentCountry: server.split("-")[0]

    mainAction: () => {
        if (root.busy) return
        root.busy = true
        if (root.toggled) {
            root.toggled = false
            disconnectProc.running = true
        } else {
            root.connectTo("")
        }
    }

    // Empty code = fastest free server anywhere. Proton switches servers
    // in place, so no disconnect is needed when already connected
    function connectTo(code) {
        root.busy = true
        root.toggled = true
        connectProc.country = code
        connectProc.running = true
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

    // Proton's CLI has no free-server listing, so read tier-0 servers from its cache
    Process {
        id: countriesProc
        running: true
        command: ["python3", "-c", `
import json, os
d = json.load(open(os.path.expanduser("~/.cache/Proton/VPN/serverlist.json")))
out = {}
for s in d["LogicalServers"]:
    if s.get("Tier") != 0: continue
    c = out.setdefault(s["ExitCountry"], {"code": s["ExitCountry"], "count": 0, "cities": []})
    c["count"] += 1
    if s.get("City") and s["City"] not in c["cities"]: c["cities"].append(s["City"])
res = sorted(out.values(), key=lambda c: -c["count"])
for c in res: c["cities"] = ", ".join(c["cities"])
print(json.dumps(res))
`]
        stdout: StdioCollector {
            id: countriesCollector
            onStreamFinished: {
                try {
                    root.freeCountries = JSON.parse(countriesCollector.text)
                } catch (e) {}
            }
        }
    }

    Process {
        id: connectProc
        property string country: ""
        command: country.length > 0
            ? ["timeout", "30", "protonvpn", "connect", "--country", country]
            : ["timeout", "30", "protonvpn", "connect"]
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
