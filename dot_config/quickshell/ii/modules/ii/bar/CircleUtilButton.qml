import qs.modules.common
import qs.modules.common.functions
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

    // Light tint of the accent hue, forced light regardless of dark/light mode
    // (colPrimaryContainer flips dark in dark mode, which isn't what we want here)
    colBackground: ColorUtils.colorWithLightness(Appearance.colors.colPrimary, 0.85)
    colBackgroundHover: ColorUtils.colorWithLightness(Appearance.colors.colPrimary, 0.78)
}
