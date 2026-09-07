import QtQuick
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets
import Quickshell
import Quickshell.Io

QuickToggleModel {
    id: root
    icon: "vpn_lock"
    toggled: false
    available: false

    // Each entry: { id: string, account: string }
    property var accountList: []
    property int currentIndex: -1

    name: {
        if (currentIndex >= 0 && currentIndex < accountList.length)
            return Translation.tr("Tailscale") + " (" + accountList[currentIndex].id + ")"
        return Translation.tr("Tailscale")
    }
    statusText: {
        if (currentIndex >= 0 && currentIndex < accountList.length)
            return accountList[currentIndex].account
        return toggled ? Translation.tr("On") : Translation.tr("Off")
    }
    tooltipText: {
        if (currentIndex >= 0 && currentIndex < accountList.length)
            return Translation.tr("Tailscale VPN | %1 | Click text to switch account").arg(accountList[currentIndex].id)
        return Translation.tr("Tailscale VPN | Click text to switch account")
    }
    hasMenu: true

    mainAction: () => {
        if (root.toggled) {
            tsDown.running = true
        } else {
            tsUp.running = true
        }
    }

    function switchToAccount(id) {
        if (id === undefined || id === null || id === "") return
        if (root.currentIndex >= 0 && root.accountList[root.currentIndex]?.id === id) return
        switchProc.profileId = id
        switchProc.running = true
    }

    altAction: () => {
        if (root.accountList.length < 2) {
            Quickshell.execDetached(["notify-send", "Tailscale",
                "No accounts loaded — check 'sudo tailscale switch --list' works", "-a", "Shell"])
            return
        }
        const nextIdx = (root.currentIndex + 1) % root.accountList.length
        root.switchToAccount(root.accountList[nextIdx].id)
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
                    root.available = true
                    root.toggled = data.BackendState === "Running"
                } catch(e) {}
            }
        }
    }

    Process {
        id: accountsProc
        running: true
        // Output format (columns: ID  Tailnet  Account, active has trailing *)
        // ID    Tailnet                 Account
        // 8aad  ai.beetleops@gmail.com  iamumersani@gmail.com
        // ee07  beetleopsai@gmail.com   umerghafoor.lab@gmail.com*
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
                    // Account is always the last token; Tailnet column may be absent
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
        id: tsUp
        command: ["sudo", "tailscale", "up", "--timeout=10s", "--reset", "--operator=" + Quickshell.env("USER")]
        property string stdoutText: ""
        property string stderrText: ""
        stdout: StdioCollector {
            id: tsUpCollector
            onStreamFinished: tsUp.stdoutText = tsUpCollector.text
        }
        stderr: StdioCollector {
            id: tsUpErrCollector
            onStreamFinished: tsUp.stderrText = tsUpErrCollector.text
        }
        onStarted: root.toggled = true
        onExited: (exitCode) => {
            // Login URL is printed to stderr when re-auth is required
            const combined = tsUp.stdoutText + "\n" + tsUp.stderrText
            const urlMatch = combined.match(/https:\/\/\S+/)
            if (urlMatch) {
                Quickshell.execDetached(["xdg-open", urlMatch[0]])
            }
            if (exitCode !== 0) {
                root.toggled = false
                if (urlMatch) {
                    Quickshell.execDetached(["notify-send", "Tailscale",
                        "Re-authentication required — opening login page in browser",
                        "-a", "Shell"])
                } else {
                    Quickshell.execDetached(["notify-send", "Tailscale",
                        "Failed to connect — run 'tailscale up' in terminal if re-auth is needed",
                        "-a", "Shell"])
                }
            }
            refreshTimer.restart()
        }
    }

    Process {
        id: tsDown
        command: ["sudo", "tailscale", "down"]
        onStarted: root.toggled = false
        onExited: (exitCode) => {
            if (exitCode !== 0) {
                root.toggled = true
                Quickshell.execDetached(["notify-send", "Tailscale", "Failed to disconnect", "-a", "Shell"])
            }
            refreshTimer.restart()
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
                refreshTimer.restart()
            } else {
                // Switch succeeded — bring up the connection
                tsUp.running = true
            }
        }
    }
}
