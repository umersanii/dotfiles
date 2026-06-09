pragma ComponentBehavior: Bound

import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.ii.bar
import QtQuick
import QtQuick.Layouts

StyledPopup {
    id: root

    ColumnLayout {
        anchors.centerIn: parent
        spacing: 4

        // Header
        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: 6

            MaterialSymbol {
                text: "mosque"
                iconSize: Appearance.font.pixelSize.large
                color: Appearance.colors.colOnSurfaceVariant
            }

            StyledText {
                text: "Prayer Times"
                font {
                    weight: Font.Medium
                    pixelSize: Appearance.font.pixelSize.normal
                }
                color: Appearance.colors.colOnSurfaceVariant
            }
        }

        // Divider
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 1
            color: Appearance.colors.colOutlineVariant
            Layout.topMargin: 2
            Layout.bottomMargin: 2
        }

        // Prayer rows
        Repeater {
            model: PrayerTimes.prayerNames

            delegate: Item {
                id: prayerRow
                required property string modelData
                readonly property bool isNext: PrayerTimes.nextPrayer === modelData
                readonly property bool isActive: PrayerTimes.activePrayer === modelData

                implicitWidth: rowLayout.implicitWidth
                implicitHeight: rowLayout.implicitHeight

                Rectangle {
                    anchors.fill: parent
                    anchors.margins: -4
                    radius: Appearance.rounding.small
                    color: "transparent"
                }

                RowLayout {
                    id: rowLayout
                    spacing: 8

                    MaterialSymbol {
                        text: PrayerTimes.prayerIcons[prayerRow.modelData] ?? "schedule"
                        iconSize: Appearance.font.pixelSize.normal
                        color: prayerRow.isActive
                            ? "white"
                            : prayerRow.isNext
                                ? Appearance.colors.colPrimary
                                : Appearance.colors.colOnSurfaceVariant
                    }

                    StyledText {
                        Layout.minimumWidth: 60
                        text: prayerRow.modelData
                        font.pixelSize: Appearance.font.pixelSize.small
                        font.weight: (prayerRow.isNext || prayerRow.isActive) ? Font.Medium : Font.Normal
                        color: prayerRow.isActive
                            ? "white"
                            : prayerRow.isNext
                                ? Appearance.colors.colPrimary
                                : Appearance.colors.colOnLayer1
                    }

                    StyledText {
                        text: PrayerTimes.to12h(PrayerTimes.timings[prayerRow.modelData] ?? "--:--")
                        font.pixelSize: Appearance.font.pixelSize.small
                        font.weight: (prayerRow.isNext || prayerRow.isActive) ? Font.Medium : Font.Normal
                        color: prayerRow.isActive
                            ? "white"
                            : prayerRow.isNext
                                ? Appearance.colors.colPrimary
                                : Appearance.colors.colOnLayer1
                        horizontalAlignment: Text.AlignRight
                    }

                    StyledText {
                        text: "→ " + PrayerTimes.to12h(PrayerTimes.prayerEndTimes[prayerRow.modelData] ?? "--:--")
                        font.pixelSize: Appearance.font.pixelSize.small
                        font.weight: Font.Normal
                        color: prayerRow.isActive
                            ? "white"
                            : prayerRow.isNext
                                ? Appearance.colors.colPrimary
                                : Appearance.colors.colOnSurfaceVariant
                        horizontalAlignment: Text.AlignRight
                    }
                }
            }
        }
    }
}
