import qs.modules.common
import qs.services
import QtQuick
import QtQuick.Layouts

MouseArea {
    id: root
    property bool borderless: Config.options.bar.borderless
    property bool alwaysShowAllResources: false
    implicitWidth: rowLayout.implicitWidth + rowLayout.anchors.leftMargin + rowLayout.anchors.rightMargin
    implicitHeight: Appearance.sizes.barHeight
    hoverEnabled: !Config.options.bar.tooltips.clickToShow

    RowLayout {
        id: rowLayout

        spacing: 0
        anchors.fill: parent
        anchors.leftMargin: 2
        anchors.rightMargin: 2

        Resource {
            iconName: "memory"
            percentage: ResourceUsage.memoryUsedPercentage
            warningThreshold: Config.options.bar.resources.memoryWarningThreshold
            customColor: percentage >= 0.85 ? Appearance.colors.colError : (percentage >= 0.70 ? "#FBBC04" : null)
        }

        Resource {
            iconName: "planner_review"
            percentage: ResourceUsage.cpuUsage
            shown: Config.options.bar.resources.alwaysShowCpu || 
                !(MprisController.activePlayer?.trackTitle?.length > 0) ||
                root.alwaysShowAllResources
            Layout.leftMargin: shown ? 3 : 0
            warningThreshold: Config.options.bar.resources.cpuWarningThreshold
            customColor: percentage >= 0.85 ? Appearance.colors.colError : (percentage >= 0.70 ? "#FBBC04" : null)
        }

        Resource {
            iconName: "developer_board"
            percentage: ResourceUsage.gpuUsage
            shown: true
            Layout.leftMargin: 3
            warningThreshold: Config.options.bar.resources.cpuWarningThreshold
            customColor: percentage >= 0.85 ? Appearance.colors.colError : (percentage >= 0.70 ? "#FBBC04" : null)
        }

        Resource {
            iconName: "cloud_download"
            percentage: Math.min(1, (ResourceUsage.networkDownloadSpeed + ResourceUsage.networkUploadSpeed) / 2 / 12800)
            shown: (ResourceUsage.networkDownloadSpeed > 0 || ResourceUsage.networkUploadSpeed > 0) ||
                root.alwaysShowAllResources
            Layout.leftMargin: shown ? 3 : 0
            warningThreshold: Config.options.bar.resources.cpuWarningThreshold
            customColor: percentage >= 0.8 ? "#22C55E" : null
        }

    }

    ResourcesPopup {
        hoverTarget: root
    }
}
