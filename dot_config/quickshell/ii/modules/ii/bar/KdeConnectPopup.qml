import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions

LazyLoader {
    id: root

    property Item hoverTarget
    required property string deviceName
    required property bool deviceReachable
    required property string deviceId
    required property int batteryLevel
    property bool popupOpen: false

    signal closed()

    active: popupOpen

    component: PanelWindow {
        id: popupWindow
        color: "transparent"

        anchors.left: !Config.options.bar.vertical || (Config.options.bar.vertical && !Config.options.bar.bottom)
        anchors.right: Config.options.bar.vertical && Config.options.bar.bottom
        anchors.top: Config.options.bar.vertical || (!Config.options.bar.vertical && !Config.options.bar.bottom)
        anchors.bottom: !Config.options.bar.vertical && Config.options.bar.bottom

        implicitWidth: popupBackground.implicitWidth + Appearance.sizes.elevationMargin * 2
        implicitHeight: popupBackground.implicitHeight + Appearance.sizes.elevationMargin * 2

        mask: Region {
            item: popupBackground
        }

        exclusionMode: ExclusionMode.Ignore
        exclusiveZone: 0
        margins {
            left: {
                if (!Config.options.bar.vertical) return root.QsWindow?.mapFromItem(
                    root.hoverTarget,
                    (root.hoverTarget.width - popupBackground.implicitWidth) / 2, 0
                ).x;
                return Appearance.sizes.verticalBarWidth
            }
            top: {
                if (!Config.options.bar.vertical) return Appearance.sizes.barHeight;
                return root.QsWindow?.mapFromItem(
                    root.hoverTarget,
                    (root.hoverTarget.height - popupBackground.implicitHeight) / 2, 0
                ).y;
            }
            right: Appearance.sizes.verticalBarWidth
            bottom: Appearance.sizes.barHeight
        }
        WlrLayershell.namespace: "quickshell:kdeconnect"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

        Component.onCompleted: GlobalFocusGrab.addDismissable(popupWindow)
        Component.onDestruction: GlobalFocusGrab.removeDismissable(popupWindow)

        Connections {
            target: GlobalFocusGrab
            function onDismissed() {
                root.closed();
            }
        }

        StyledRectangularShadow {
            target: popupBackground
        }

        Rectangle {
            id: popupBackground
            readonly property real margin: 10
            anchors {
                fill: parent
                leftMargin: Appearance.sizes.elevationMargin
                rightMargin: Appearance.sizes.elevationMargin
                topMargin: Appearance.sizes.elevationMargin
                bottomMargin: Appearance.sizes.elevationMargin
            }
            implicitWidth: popupContent.implicitWidth + margin * 2
            implicitHeight: popupContent.implicitHeight + margin * 2
            color: Appearance.m3colors.m3surfaceContainer
            radius: Appearance.rounding.small
            border.width: 1
            border.color: Appearance.colors.colLayer0Border

            Column {
                id: popupContent
                anchors.centerIn: parent
                spacing: 8

                StyledPopupHeaderRow {
                    icon: root.deviceReachable ? "smartphone" : "phonelink_off"
                    label: root.deviceName || "No device"
                }

                StyledPopupValueRow {
                    visible: root.batteryLevel >= 0
                    icon: root.batteryLevel > 80 ? "battery_full"
                        : root.batteryLevel > 50 ? "battery_5_bar"
                        : root.batteryLevel > 20 ? "battery_3_bar"
                        : "battery_1_bar"
                    label: "Battery:"
                    value: root.batteryLevel + "%"
                    valueColor: root.batteryLevel <= 20
                        ? Appearance.colors.colError
                        : Appearance.colors.colOnSurfaceVariant
                }

                StyledPopupValueRow {
                    icon: root.deviceReachable ? "link" : "link_off"
                    label: "Status:"
                    value: root.deviceReachable ? "Connected" : "Disconnected"
                    valueColor: root.deviceReachable
                        ? (Appearance.m3colors.m3primary ?? "#66BB6A")
                        : Appearance.colors.colError
                }

                Rectangle {
                    width: parent.width
                    height: 1
                    color: Appearance.colors.colOutlineVariant
                }

                Column {
                    spacing: 4
                    width: parent.width

                    KdeConnectActionButton {
                        enabled: root.deviceReachable
                        iconName: "content_paste_go"
                        label: "Send Clipboard"
                        onClicked: Quickshell.execDetached([
                            "kdeconnect-cli", "-d", root.deviceId, "--send-clipboard"
                        ])
                    }

                    KdeConnectActionButton {
                        enabled: root.deviceReachable
                        iconName: "ring_volume"
                        label: "Ring Phone"
                        onClicked: Quickshell.execDetached([
                            "kdeconnect-cli", "-d", root.deviceId, "--ring"
                        ])
                    }

                    KdeConnectActionButton {
                        enabled: root.deviceReachable
                        iconName: "upload_file"
                        label: "Send File"
                        onClicked: Quickshell.execDetached([
                            "bash", "-c",
                            "file=$(zenity --file-selection --title='Send file to phone') && [ -n \"$file\" ] && kdeconnect-cli -d " + root.deviceId + " --share \"$file\""
                        ])
                    }

                    KdeConnectActionButton {
                        enabled: root.deviceReachable
                        iconName: "notifications_active"
                        label: "Ping Phone"
                        onClicked: Quickshell.execDetached([
                            "kdeconnect-cli", "-d", root.deviceId, "--ping"
                        ])
                    }
                }
            }
        }
    }
}
