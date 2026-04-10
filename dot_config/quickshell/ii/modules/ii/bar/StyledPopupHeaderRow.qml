import QtQuick
import QtQuick.Layouts
import qs.modules.common
import qs.modules.common.widgets

Row {
    id: root
    required property var icon
    required property var label
    property string iconSource: ""
    spacing: 5

    Loader {
        anchors.verticalCenter: parent.verticalCenter
        sourceComponent: root.iconSource !== "" ? imgIcon : symIcon
    }
    Component {
        id: symIcon
        MaterialSymbol {
            fill: 0
            font.weight: Font.DemiBold
            text: root.icon
            iconSize: Appearance.font.pixelSize.large
            color: Appearance.colors.colOnSurfaceVariant
        }
    }
    Component {
        id: imgIcon
        Image {
            width: Appearance.font.pixelSize.large
            height: Appearance.font.pixelSize.large
            source: root.iconSource
            sourceSize.width: Appearance.font.pixelSize.large
            sourceSize.height: Appearance.font.pixelSize.large
            fillMode: Image.PreserveAspectFit
            smooth: true
            antialiasing: true
        }
    }

    StyledText {
        anchors.verticalCenter: parent.verticalCenter
        text: root.label
        font {
            weight: Font.DemiBold
            pixelSize: Appearance.font.pixelSize.normal
        }
        color: Appearance.colors.colOnSurfaceVariant
    }
}