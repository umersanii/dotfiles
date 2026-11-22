pragma ComponentBehavior: Bound

import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import QtQuick.Layouts

StyledPopup {
    id: root
    property var ts

    ColumnLayout {
        anchors.centerIn: parent
        spacing: 4

        StyledPopupHeaderRow {
            icon: "vpn_lock"
            label: "Tailscale"
        }

        StyledPopupValueRow {
            icon: "power_settings_new"
            label: "Status:"
            value: root.ts.running ? "Connected" : "Disconnected"
            valueColor: root.ts.running ? "#ffffff" : "#8a8a8a"
        }
        StyledPopupValueRow {
            visible: root.ts.hostName !== ""
            icon: "computer"
            label: root.ts.hostName
            value: root.ts.selfIp
        }
        StyledPopupValueRow {
            visible: root.ts.tailnet !== ""
            icon: "lan"
            label: "Tailnet:"
            value: root.ts.tailnet
        }
        StyledPopupValueRow {
            icon: "alt_route"
            label: "Exit node:"
            value: root.ts.exitNode !== "" ? root.ts.exitNode : "None"
        }

        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 1
            color: Appearance.colors.colOutlineVariant
            Layout.topMargin: 2
            Layout.bottomMargin: 2
        }

        StyledText {
            text: `Devices · ${root.ts.onlineCount}/${root.ts.peers.length} online`
            color: Appearance.colors.colOnSurfaceVariant
            font.pixelSize: Appearance.font.pixelSize.small
        }

        Repeater {
            model: root.ts.peers
            delegate: RowLayout {
                id: peerRow
                required property var modelData
                spacing: 8
                readonly property color fg: modelData.online ? "#ffffff" : "#8a8a8a"

                MaterialSymbol {
                    text: peerRow.modelData.os === "android" || peerRow.modelData.os === "iOS" ? "smartphone" : "computer"
                    iconSize: Appearance.font.pixelSize.normal
                    color: peerRow.fg
                }
                StyledText {
                    Layout.minimumWidth: 110
                    text: peerRow.modelData.name
                    font.pixelSize: Appearance.font.pixelSize.small
                    font.weight: peerRow.modelData.online ? Font.Medium : Font.Normal
                    color: peerRow.fg
                }
                StyledText {
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignRight
                    text: peerRow.modelData.ip
                    font.pixelSize: Appearance.font.pixelSize.small
                    color: peerRow.fg
                }
            }
        }
    }
}
