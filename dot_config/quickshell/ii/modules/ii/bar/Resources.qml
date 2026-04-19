import qs.modules.common
import qs.services
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

MouseArea {
    id: root
    property bool borderless: Config.options.bar.borderless
    property bool alwaysShowAllResources: false
    implicitWidth: rowLayout.implicitWidth + rowLayout.anchors.leftMargin + rowLayout.anchors.rightMargin
    implicitHeight: Appearance.sizes.barHeight
    hoverEnabled: !Config.options.bar.tooltips.clickToShow

    property string gpuMode: "hybrid"

    Process {
        id: gpuModeProc
        command: ["bash", "-c",
            "if command -v envycontrol &>/dev/null; then envycontrol --query; " +
            "elif lsmod | grep -q '^nvidia '; then " +
            "  lsmod | grep -q '^amdgpu ' && echo hybrid || echo nvidia; " +
            "else echo integrated; fi"]
        running: true
        stdout: SplitParser {
            onRead: data => root.gpuMode = data.trim()
        }
    }

    readonly property string gpuIconSource: {
        if (gpuMode === "nvidia") return Quickshell.shellPath("assets/icons/nvidia-symbolic.svg")
        if (gpuMode === "integrated") return Quickshell.shellPath("assets/icons/amd-symbolic.svg")
        return Quickshell.shellPath("assets/icons/hybrid-symbolic.svg")
    }

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
        }

        Resource {
            iconName: "planner_review"
            percentage: ResourceUsage.cpuUsage
            shown: Config.options.bar.resources.alwaysShowCpu ||
                !(MprisController.activePlayer?.trackTitle?.length > 0) ||
                root.alwaysShowAllResources
            Layout.leftMargin: shown ? 3 : 0
            warningThreshold: Config.options.bar.resources.cpuWarningThreshold
        }

        Resource {
            iconName: ""
            iconSource: root.gpuIconSource
            percentage: ResourceUsage.gpuUsage
            shown: true
            Layout.leftMargin: 3
            warningThreshold: Config.options.bar.resources.cpuWarningThreshold
        }

        Resource {
            iconName: "cloud_download"
            percentage: Math.min(1, (ResourceUsage.networkDownloadSpeed + ResourceUsage.networkUploadSpeed) / 2 / 12800)
            shown: (ResourceUsage.networkDownloadSpeed > 0 || ResourceUsage.networkUploadSpeed > 0) ||
                root.alwaysShowAllResources
            Layout.leftMargin: shown ? 3 : 0
            warningThreshold: Config.options.bar.resources.cpuWarningThreshold
        }

    }

    ResourcesPopup {
        hoverTarget: root
    }
}
