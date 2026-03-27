import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import "../../services"

Item {
    id: gpuToggle

    width: 20
    height: 20

    Rectangle {
        anchors.fill: parent
        radius: 3
        color: GPU.hardwareAccelEnabled ? "#4CAF50" : "#FF9800"

        Text {
            anchors.centerIn: parent
            text: GPU.hardwareAccelEnabled ? "⚡" : "C"
            color: "white"
            font.pixelSize: 10
            font.bold: true
        }

        MouseArea {
            id: mouseArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor

            onClicked: {
                GPU.toggleHardwareAccel()
            }

            Rectangle {
                anchors.fill: parent
                radius: 3
                color: parent.containsMouse ? "white" : "transparent"
                opacity: 0.15
            }
        }

        ToolTip {
            visible: mouseArea.containsMouse
            text: GPU.hardwareAccelEnabled 
                ? "GPU Acceleration ON (⚡)\nClick to disable"
                : "CPU Rendering ON (C)\nClick to enable GPU"
            delay: 300
        }
    }
}
