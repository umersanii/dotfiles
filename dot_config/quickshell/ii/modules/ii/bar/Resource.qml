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
    readonly property color colActive: root.warning
        ? Qt.rgba(0xEF/255, 0x44/255, 0x44/255, 1.0)
        : Appearance.colors.colOnLayer1
    // Accent-colored progress arc; falls back to black when the accent is the
    // base theme's pure white (invisible against the white circle fill)
    readonly property color colArc: (root.warning || Qt.colorEqual(Appearance.colors.colPrimary, "#ffffff"))
        ? "black"
        : Appearance.colors.colPrimary

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
            colPrimary: root.colArc
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
