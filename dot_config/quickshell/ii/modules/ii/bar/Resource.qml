import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import QtQuick.Layouts

Item {
    id: root
    required property string iconName
    property string iconSource: ""
    required property double percentage
    property int warningThreshold: 100
    property bool shown: true
    property var customColor: null
    clip: true
    visible: width > 0 && height > 0
    implicitWidth: resourceRowLayout.x < 0 ? 0 : resourceRowLayout.implicitWidth + 8
    implicitHeight: Appearance.sizes.barHeight
    property bool warning: percentage * 100 >= warningThreshold
    readonly property color colActive: {
        let p = percentage * 100;
        let r, g, b;
        if (p < 25) {
            r = 0x22/255; g = 0xC5/255; b = 0x5E/255;  // green
        } else if (p < 50) {
            r = 0xFB/255; g = 0xBC/255; b = 0x04/255;  // yellow
        } else if (p < 75) {
            r = 0xF9/255; g = 0x73/255; b = 0x16/255;  // orange
        } else {
            r = 0xEF/255; g = 0x44/255; b = 0x44/255;  // red
        }
        let levelMin = Math.floor(p / 25) * 25;
        let t = Math.max(0.1, (p - levelMin) / 25);
        // Mix toward white at low usage, pure color at high usage
        return Qt.rgba(1 - t * (1 - r), 1 - t * (1 - g), 1 - t * (1 - b), 1.0);
    }

    RowLayout {
        id: resourceRowLayout
        spacing: 2
        x: shown ? 4 : -(resourceRowLayout.width + 4)
        anchors {
            verticalCenter: parent.verticalCenter
        }

        ClippedFilledCircularProgress {
            id: resourceCircProg
            Layout.alignment: Qt.AlignVCenter
            lineWidth: Appearance.rounding.unsharpen
            value: percentage
            implicitSize: 21
            colPrimary: "black"
            colSecondary: root.colActive
            accountForLightBleeding: !root.warning
            enableAnimation: true

            Item {
                anchors.centerIn: parent
                width: resourceCircProg.implicitSize - 8
                height: resourceCircProg.implicitSize - 8
                
                Loader {
                    anchors.fill: parent
                    sourceComponent: root.iconSource !== "" ? imgIcon : symIcon
                }
                Component {
                    id: symIcon
                    MaterialSymbol {
                        font.weight: Font.DemiBold
                        fill: 1
                        text: iconName
                        iconSize: parent.height
                        antialiasing: true
                        renderType: Text.QtRendering
                        color: "black"
                    }
                }
                Component {
                    id: imgIcon
                    Image {
                        width: parent.width
                        height: parent.height
                        source: root.iconSource
                        sourceSize.width: parent.width
                        sourceSize.height: parent.height
                        fillMode: Image.PreserveAspectFit
                        smooth: true
                        antialiasing: true
                    }
                }
            }
        }

        Behavior on x {
            animation: Appearance.animation.elementMove.numberAnimation.createObject(this)
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.NoButton
        enabled: resourceRowLayout.x >= 0 && root.width > 0 && root.visible
    }

    Behavior on implicitWidth {
        NumberAnimation {
            duration: Appearance.animation.elementMove.duration
            easing.type: Appearance.animation.elementMove.type
            easing.bezierCurve: Appearance.animation.elementMove.bezierCurve
        }
    }
}
