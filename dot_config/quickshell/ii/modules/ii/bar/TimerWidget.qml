import qs.services
import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import QtQuick.Layouts

Item {
    id: root
    implicitWidth: rowLayout.implicitWidth
    implicitHeight: Appearance.sizes.barHeight

    RowLayout {
        id: rowLayout
        anchors.centerIn: parent
        spacing: 4

        MaterialSymbol {
            text: "timer"
            iconSize: Appearance.font.pixelSize.small
            color: Appearance.colors.colOnLayer1
        }

        StyledText {
            font.pixelSize: Appearance.font.pixelSize.small
            color: Appearance.colors.colOnLayer1
            text: {
                const totalSeconds = Math.floor(TimerService.stopwatchTime / 100)
                const hours = Math.floor(totalSeconds / 3600)
                const minutes = Math.floor((totalSeconds % 3600) / 60).toString().padStart(2, "0")
                const seconds = Math.floor(totalSeconds % 60).toString().padStart(2, "0")
                return hours > 0 ? `${hours}:${minutes}:${seconds}` : `${minutes}:${seconds}`
            }
        }

        StyledText {
            font.pixelSize: Appearance.font.pixelSize.small
            color: Appearance.colors.colSubtext
            text: `.${(Math.floor(TimerService.stopwatchTime) % 100).toString().padStart(2, "0")}`
        }
    }
}
