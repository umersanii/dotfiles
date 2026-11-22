pragma ComponentBehavior: Bound

import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import Quickshell.Io

MouseArea {
    id: root
    implicitWidth: 28
    implicitHeight: Appearance.sizes.barHeight

    hoverEnabled: !Config.options.bar.tooltips.clickToShow
    acceptedButtons: Qt.LeftButton | Qt.RightButton

    property bool available: false
    property bool running: false
    property string hostName: ""
    property string selfIp: ""
    property string tailnet: ""
    property string exitNode: ""
    // [{ name, ip, os, online, exitNode }] — online first
    property var peers: []
    readonly property int onlineCount: peers.filter(p => p.online).length

    onPressed: mouse => {
        if (mouse.button === Qt.RightButton) {
            statusProc.running = true;
            mouse.accepted = false;
        }
    }

    Timer {
        interval: 15000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: statusProc.running = true
    }

    Process {
        id: statusProc
        command: ["tailscale", "status", "--json"]
        stdout: StdioCollector {
            id: collector
            onStreamFinished: {
                const raw = collector.text.trim();
                if (!raw) { root.available = false; return; }
                try {
                    const d = JSON.parse(raw);
                    root.available = true;
                    root.running = d.BackendState === "Running";
                    root.hostName = d.Self?.HostName ?? "";
                    root.selfIp = d.Self?.TailscaleIPs?.[0] ?? "";
                    root.tailnet = d.CurrentTailnet?.Name ?? "";
                    const list = Object.values(d.Peer ?? {}).map(p => ({
                        name: p.HostName,
                        ip: p.TailscaleIPs?.[0] ?? "",
                        os: p.OS ?? "",
                        online: !!p.Online,
                        exitNode: !!p.ExitNode
                    }));
                    list.sort((a, b) => (b.online - a.online) || a.name.localeCompare(b.name));
                    root.peers = list;
                    root.exitNode = list.find(p => p.exitNode)?.name ?? "";
                } catch (e) {
                    root.available = false;
                }
            }
        }
    }

    MaterialSymbol {
        anchors.centerIn: parent
        text: "vpn_lock"
        iconSize: Appearance.font.pixelSize.larger
        // monochrome: white = connected, mid-grey = down
        color: root.running ? "#ffffff" : "#8a8a8a"
    }

    TailscalePopup {
        hoverTarget: root
        ts: root
    }
}
