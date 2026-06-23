import QtQuick
import QtQuick.Layouts
import qs.modules.common
import qs.modules.common.widgets

RippleButton {
    id: root

    required property string iconName
    required property string label

    implicitWidth: 180
    implicitHeight: 32
    buttonRadius: Appearance.rounding.small

    colBackground: "transparent"
    colBackgroundHover: Appearance.colors.colLayer1Hover
    colRipple: Appearance.colors.colLayer1Active

    opacity: enabled ? 1.0 : 0.4

    contentItem: RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 8
        anchors.rightMargin: 8
        spacing: 8

        MaterialSymbol {
            text: root.iconName
            iconSize: Appearance.font.pixelSize.large
            color: Appearance.colors.colOnSurfaceVariant
        }

        StyledText {
            Layout.fillWidth: true
            text: root.label
            color: Appearance.colors.colOnSurfaceVariant
            font.pixelSize: Appearance.font.pixelSize.normal
        }
    }
}
