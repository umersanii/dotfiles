import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import Quickshell
import Quickshell.Io

QuickToggleButton {
    id: root
    buttonIcon: "vpn_lock"
    toggled: false

    // Each entry: { id: string, account: string }
    property var accountList: []
    property int currentIndex: -1

    onClicked: {
        if (root.toggled) {
            root.toggled = false
            Quickshell.execDetached(["sudo", "tailscale", "down"])
        } else {
            root.toggled = true
            Quickshell.execDetached(["sudo", "tailscale", "up"])
        }
    }

    altAction: () => {
        if (root.accountList.length < 2) {
            Quickshell.execDetached(["notify-send", "Tailscale",
                "No accounts loaded — check 'sudo tailscale switch --list' works", "-a", "Shell"])
            return
        }
        const nextIdx = (root.currentIndex + 1) % root.accountList.length
        switchProc.profileId = root.accountList[nextIdx].id
        switchProc.running = true
    }

    Timer {
        id: pollTimer
        interval: 15000
        repeat: true
        running: true
        onTriggered: {
            statusProc.running = true
            accountsProc.running = true
        }
    }

    Timer {
        id: refreshTimer
        interval: 1500
        onTriggered: {
            statusProc.running = true
            accountsProc.running = true
        }
    }

    Process {
        id: statusProc
        running: true
        command: ["bash", "-c", "sudo tailscale status --json 2>/dev/null"]
        stdout: StdioCollector {
            id: statusCollector
            onStreamFinished: {
                const raw = statusCollector.text.trim()
                if (!raw) return
                try {
                    const data = JSON.parse(raw)
                    root.toggled = data.BackendState === "Running"
                    root.visible = true
                } catch(e) {}
            }
        }
    }

    Process {
        id: accountsProc
        running: true
        // Output format (columns: ID  Tailnet  Account, active has trailing *)
        command: ["sudo", "tailscale", "switch", "--list"]
        stdout: StdioCollector {
            id: accountsCollector
            onStreamFinished: {
                const lines = accountsCollector.text.split("\n")
                const accounts = []
                let activeIdx = -1
                for (let i = 1; i < lines.length; i++) { // skip header row
                    const line = lines[i].trim()
                    if (!line) continue
                    const tokens = line.split(/\s+/)
                    if (tokens.length < 2) continue
                    const id = tokens[0]
                    const accountRaw = tokens[tokens.length - 1]
                    const isCurrent = accountRaw.endsWith("*")
                    const account = accountRaw.replace(/\*$/, "")
                    accounts.push({ id, account })
                    if (isCurrent) activeIdx = accounts.length - 1
                }
                if (accounts.length > 0) root.accountList = accounts
                if (activeIdx >= 0) root.currentIndex = activeIdx
            }
        }
    }

    Process {
        id: switchProc
        property string profileId: ""
        command: ["sudo", "tailscale", "switch", profileId]
        onExited: (exitCode) => {
            if (exitCode !== 0) {
                Quickshell.execDetached(["notify-send", "Tailscale",
                    Translation.tr("Failed to switch account"), "-a", "Shell"])
            } else {
                Quickshell.execDetached(["sudo", "tailscale", "up"])
                root.toggled = true
            }
            refreshTimer.restart()
        }
    }

    StyledToolTip {
        text: {
            const acc = (root.currentIndex >= 0 && root.currentIndex < root.accountList.length)
                ? root.accountList[root.currentIndex].account : ""
            return acc
                ? Translation.tr("Tailscale VPN | %1 | Right-click to switch account").arg(acc)
                : Translation.tr("Tailscale VPN | Right-click to switch account")
        }
    }
}
