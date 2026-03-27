import QtQuick
import QtQuick.Layouts
import qs.modules.common
import qs.modules.common.widgets
import Quickshell

Item {
    id: root

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 16

        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            color: Appearance.colors.colLayer1
            radius: Appearance.rounding.normal

             ColumnLayout {
                anchors.centerIn: parent
                spacing: 20
                width: parent.width * 0.9

                StyledText {
                    Layout.alignment: Qt.AlignHCenter
                    text: "WhatsApp"
                    font.pixelSize: Appearance.font.pixelSize.large
                    font.bold: true
                }

                StyledText {
                    Layout.alignment: Qt.AlignHCenter
                    text: "Native Desktop Application"
                    color: Appearance.colors.colSubtext
                }

                Rectangle {
                    Layout.alignment: Qt.AlignHCenter
                    width: 160
                    height: 45
                    color: Appearance.colors.colLayer2
                    radius: Appearance.rounding.normal

                    Text {
                        anchors.centerIn: parent
                        text: "Launch WhatsApp"
                        color: Appearance.colors.colOnLayer2
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            Quickshell.run(["/opt/WhatsApp Desktop/whatsapp-linux-desktop"], {})
                        }
                    }
                }
            }
        }
    }
}
