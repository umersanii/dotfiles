import qs.modules.common
import qs.modules.common.widgets
import QtQuick

RippleButton {
    id: button

    required default property Item content
    property bool extraActiveCondition: false

    implicitHeight: Math.max(content.implicitHeight, 26, content.implicitHeight)
    implicitWidth: implicitHeight
    contentItem: content

    // Enable borders on utility buttons
    borderWidth: 1
    borderColor: Appearance.colors.colOutlineVariant

    // Light accent-tinted background instead of the default layer color
    colBackground: Appearance.colors.colPrimaryContainer
    colBackgroundHover: Appearance.colors.colPrimaryContainerHover
}
