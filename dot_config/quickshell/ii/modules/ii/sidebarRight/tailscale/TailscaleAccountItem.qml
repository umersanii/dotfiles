import qs
import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import QtQuick.Layouts

DialogListItem {
    id: root
    required property var account // { id: string, account: string }
    property bool current: false
    enabled: !current

    signal switchRequested()

    active: current
    onClicked: root.switchRequested()

    contentItem: RowLayout {
        anchors {
            fill: parent
            topMargin: root.verticalPadding
            bottomMargin: root.verticalPadding
            leftMargin: root.horizontalPadding
            rightMargin: root.horizontalPadding
        }
        spacing: 10

        MaterialSymbol {
            iconSize: Appearance.font.pixelSize.larger
            text: "person"
            color: Appearance.colors.colOnSurfaceVariant
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0

            StyledText {
                Layout.fillWidth: true
                elide: Text.ElideRight
                color: Appearance.colors.colOnSurfaceVariant
                text: root.account?.account ?? Translation.tr("Unknown")
                textFormat: Text.PlainText
            }

            StyledText {
                Layout.fillWidth: true
                elide: Text.ElideRight
                font.pixelSize: Appearance.font.pixelSize.smaller
                color: Appearance.colors.colOutline
                text: root.account?.id ?? ""
            }
        }

        MaterialSymbol {
            visible: root.current
            text: "check"
            iconSize: Appearance.font.pixelSize.larger
            color: Appearance.colors.colOnSurfaceVariant
        }
    }
}
