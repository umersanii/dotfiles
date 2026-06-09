pragma ComponentBehavior: Bound

import qs.modules.common
import qs.modules.common.widgets
import qs.services
import QtQuick
import QtQuick.Layouts

MouseArea {
    id: root
    implicitWidth: rowLayout.implicitWidth + 10 * 2
    implicitHeight: Appearance.sizes.barHeight

    hoverEnabled: !Config.options.bar.tooltips.clickToShow
    acceptedButtons: Qt.LeftButton | Qt.RightButton

    onPressed: mouse => {
        if (mouse.button === Qt.RightButton) {
            PrayerTimes.getData();
            mouse.accepted = false;
        }
    }

    readonly property color urgentColor: "#F44336"
    readonly property color activeColor: "#4CAF50"
    readonly property color defaultColor: Appearance.colors.colOnLayer1

    readonly property color widgetColor: PrayerTimes.isUrgent
        ? urgentColor
        : PrayerTimes.activePrayer !== "" ? activeColor : defaultColor

    RowLayout {
        id: rowLayout
        anchors.centerIn: parent
        spacing: 4

        MaterialSymbol {
            text: PrayerTimes.prayerIcons[PrayerTimes.nextPrayer] ?? "schedule"
            iconSize: Appearance.font.pixelSize.normal
            color: root.widgetColor
            Layout.alignment: Qt.AlignVCenter
        }

        StyledText {
            font.pixelSize: Appearance.font.pixelSize.smaller
            color: root.widgetColor
            text: PrayerTimes.remainingTimeStr
            Layout.alignment: Qt.AlignVCenter
            visible: PrayerTimes.remainingTimeStr !== "" && PrayerTimes.nextPrayerTime !== "--:--"
        }
    }

    PrayerTimesPopup {
        hoverTarget: root
    }
}
