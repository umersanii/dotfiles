import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import Quickshell
import Quickshell.Io

QuickToggleButton {
    id: root
    buttonIcon: "vpn_lock"
    toggled: false

    onClicked: {
        if (root.toggled) {
            root.toggled = false
            Quickshell.execDetached(["sudo", "tailscale", "down"])
        } else {
            root.toggled = true
            Quickshell.execDetached(["sudo", "tailscale", "up"])
        }
    }

    Process {
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

    StyledToolTip {
        text: Translation.tr("Tailscale VPN")
    }
}
