import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import Quickshell
import Quickshell.Io
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions

Item {
    id: root
    implicitWidth: 28
    implicitHeight: 28

    property bool deviceReachable: false
    property string deviceName: ""
    property string deviceId: ""
    property int batteryLevel: -1
    property bool popupOpen: false

    // Poll device status every 15 seconds
    Timer {
        interval: 15000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: statusProc.running = true
    }

    Process {
        id: statusProc
        command: ["kdeconnect-cli", "-a", "--name-only"]
        stdout: SplitParser {
            onRead: data => {
                const line = data.trim();
                if (line.length > 0) {
                    root.deviceReachable = true;
                    root.deviceName = line;
                }
            }
        }
        onExited: (code, status) => {
            if (code !== 0) root.deviceReachable = false;
            if (root.deviceReachable) idProc.running = true;
        }
    }

    Process {
        id: idProc
        command: ["kdeconnect-cli", "-a", "--id-only"]
        stdout: SplitParser {
            onRead: data => {
                const id = data.trim();
                if (id.length > 0) {
                    root.deviceId = id;
                    batteryProc.running = true;
                }
            }
        }
    }

    Process {
        id: batteryProc
        command: ["qdbus6", "org.kde.kdeconnect",
            "/modules/kdeconnect/devices/" + root.deviceId + "/battery",
            "org.kde.kdeconnect.device.battery.charge"]
        stdout: SplitParser {
            onRead: data => {
                const val = parseInt(data.trim());
                if (!isNaN(val) && val >= 0) root.batteryLevel = val;
            }
        }
    }

    // Battery-based color: red <=5%, yellow <=20%, green >=80%, default otherwise
    property color batteryColor: root.batteryLevel <= 5 ? "#F44336"
        : root.batteryLevel <= 20 ? "#FBBC04"
        : root.batteryLevel >= 80 ? "#4CAF50"
        : Appearance.colors.colOnLayer0

    MouseArea {
        id: buttonMouseArea
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton
        onPressed: event => {
            event.accepted = true;
            root.popupOpen = !root.popupOpen;
        }

        MaterialSymbol {
            id: phoneIcon
            anchors.centerIn: parent
            text: root.deviceReachable ? "smartphone" : "phonelink_off"
            iconSize: 18
            color: root.batteryColor
        }
    }

    KdeConnectPopup {
        id: popup
        hoverTarget: buttonMouseArea
        popupOpen: root.popupOpen
        deviceName: root.deviceName
        deviceReachable: root.deviceReachable
        deviceId: root.deviceId
        batteryLevel: root.batteryLevel
        onClosed: root.popupOpen = false
    }
}
