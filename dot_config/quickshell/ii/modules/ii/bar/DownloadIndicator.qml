import qs.modules.common
import qs.modules.common.widgets
import qs.services
import QtQuick
import QtQuick.Layouts

Item {
    id: root

    readonly property bool isDownloading: DownloadStatus.active
    property real pulseValue: 0

    clip: true
    implicitWidth: rowLayout.x < 0 ? 0 : rowLayout.implicitWidth + 8
    implicitHeight: Appearance.sizes.barHeight

    SequentialAnimation on pulseValue {
        running: root.isDownloading && !DownloadStatus.hasProgress
        loops: Animation.Infinite
        NumberAnimation { to: 1.0; duration: 1500; easing.type: Easing.InOutSine }
        NumberAnimation { to: 0.1; duration: 1500; easing.type: Easing.InOutSine }
    }

    RowLayout {
        id: rowLayout
        spacing: 0
        x: root.isDownloading ? 4 : -(rowLayout.width + 4)
        anchors.verticalCenter: parent.verticalCenter

        Behavior on x {
            animation: Appearance.animation.elementMove.numberAnimation.createObject(this)
        }

        ClippedFilledCircularProgress {
            id: circProg
            Layout.alignment: Qt.AlignVCenter
            lineWidth: Appearance.rounding.unsharpen
            value: DownloadStatus.hasProgress ? DownloadStatus.progress : root.pulseValue
            implicitSize: 21
            colPrimary: "black"
            colSecondary: Appearance.colors.colOnLayer1
            enableAnimation: DownloadStatus.hasProgress

            Item {
                anchors.centerIn: parent
                width: circProg.implicitSize - 8
                height: circProg.implicitSize - 8

                MaterialSymbol {
                    anchors.fill: parent
                    font.weight: Font.DemiBold
                    fill: 1
                    text: Network.materialSymbol
                    iconSize: parent.height
                    antialiasing: true
                    renderType: Text.QtRendering
                    color: "black"
                }
            }
        }
    }

    Behavior on implicitWidth {
        NumberAnimation {
            duration: Appearance.animation.elementMove.duration
            easing.type: Appearance.animation.elementMove.type
            easing.bezierCurve: Appearance.animation.elementMove.bezierCurve
        }
    }

    HoverHandler { id: hh }

    StyledToolTip {
        text: {
            const spd = ResourceUsage.networkDownloadSpeed
            const spdStr = spd >= 1024
                ? (spd / 1024).toFixed(1) + " MB/s"
                : spd.toFixed(0) + " KB/s"
            if (DownloadStatus.hasProgress) {
                const pct = (DownloadStatus.progress * 100).toFixed(1)
                return DownloadStatus.name + "\n\u2193 " + spdStr + "  " + pct + "%"
            }
            const mb = (DownloadStatus.downloadedBytes / (1024 * 1024)).toFixed(1)
            return DownloadStatus.name + "\n\u2193 " + spdStr + "  " + mb + " MB"
        }
        extraVisibleCondition: hh.hovered
    }
}
