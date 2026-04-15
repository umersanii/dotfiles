import qs.modules.ii.bar.weather
import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.UPower
import Quickshell.Services.Notifications
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions

Item { // Bar content region
    id: root

    property var screen: root.QsWindow.window?.screen
    property var brightnessMonitor: Brightness.getMonitorForScreen(screen)
    property real useShortenedForm: (Appearance.sizes.barHellaShortenScreenWidthThreshold >= screen?.width) ? 2 : (Appearance.sizes.barShortenScreenWidthThreshold >= screen?.width) ? 1 : 0
    readonly property int centerSideModuleWidth: (useShortenedForm == 2) ? Appearance.sizes.barCenterSideModuleWidthHellaShortened : (useShortenedForm == 1) ? Appearance.sizes.barCenterSideModuleWidthShortened : Appearance.sizes.barCenterSideModuleWidth

    readonly property bool notifVisible: Notifications.popupList.length > 0 && !GlobalStates.screenLocked

    component VerticalBarSeparator: Rectangle {
        Layout.topMargin: Appearance.sizes.baseBarHeight / 3
        Layout.bottomMargin: Appearance.sizes.baseBarHeight / 3
        Layout.fillHeight: true
        implicitWidth: 1
        color: Appearance.colors.colOutlineVariant
    }

    component AnimatedBarLogo: Item {
        id: logoRoot
        implicitWidth: 28
        implicitHeight: 28
        property bool updatesAvailable: Updates.anyUpdates
        property real glowOpacity: 0

        onUpdatesAvailableChanged: {
            if (!updatesAvailable) {
                glowOpacity = 0;
            }
        }

        Rectangle {
            anchors.fill: parent
            radius: Appearance.rounding.full
            color: updatesAvailable ? ColorUtils.transparentize(Appearance.colors.colSecondaryContainer, 0.15) : ColorUtils.transparentize(Appearance.colors.colLayer1Hover, 0.35)
            border.width: 1
            border.color: updatesAvailable ? Appearance.colors.colSecondary : Appearance.colors.colLayer0Border
        }

        MouseArea {
            id: logoMouseArea
            anchors.fill: parent
            hoverEnabled: true
            z: 1
            onPressed: event => event.accepted = true
            onClicked: {
                Quickshell.execDetached(["sh", "-c", Config.options.apps.update]);
            }

            IconImage {
                id: logoIcon
                anchors.centerIn: parent
                width: 18
                height: 18
                source: Quickshell.iconPath(SystemInfo.logo)
            }

            Glow {
                anchors.fill: logoIcon
                source: logoIcon
                radius: 12
                samples: 25
                color: Appearance.colors.colSecondary
                opacity: logoRoot.glowOpacity
                visible: updatesAvailable
            }

            StyledToolTip {
                text: Translation.tr("%1 updates available").arg(Updates.count)
                extraVisibleCondition: updatesAvailable && logoMouseArea.containsMouse
            }
        }

        SequentialAnimation on glowOpacity {
            loops: Animation.Infinite
            running: logoRoot.updatesAvailable
            NumberAnimation { to: 1.0; duration: 1500; easing.type: Easing.InOutQuad }
            NumberAnimation { to: 0.1; duration: 1500; easing.type: Easing.InOutQuad }
        }
    }

    // Background shadow
    Loader {
        active: Config.options.bar.showBackground && Config.options.bar.cornerStyle === 1 && Config.options.bar.floatStyleShadow
        anchors.fill: barBackground
        sourceComponent: StyledRectangularShadow {
            anchors.fill: undefined // The loader's anchors act on this, and this should not have any anchor
            target: barBackground
        }
    }
    // Background
    Rectangle {
        id: barBackground
        anchors {
            fill: parent
            margins: Config.options.bar.cornerStyle === 1 ? (Appearance.sizes.hyprlandGapsOut) : 0 // idk why but +1 is needed
        }
        color: Config.options.bar.showBackground ? Appearance.colors.colLayer0 : "transparent"
        radius: Config.options.bar.cornerStyle === 1 ? Appearance.rounding.windowRounding : 0
        border.width: Config.options.bar.cornerStyle === 1 ? 1 : 0
        border.color: Appearance.colors.colLayer0Border
    }

    FocusedScrollMouseArea { // Left side | scroll to change brightness
        id: barLeftSideMouseArea

        anchors {
            top: parent.top
            bottom: parent.bottom
            left: parent.left
            right: leftCenterGroup.left
        }
        implicitWidth: leftSectionRowLayout.implicitWidth
        implicitHeight: Appearance.sizes.baseBarHeight
        opacity: root.notifVisible ? 0 : 1
        Behavior on opacity { NumberAnimation { duration: Appearance.animation.elementMoveFast.duration; easing.type: Appearance.animation.elementMoveFast.type } }

        onScrollDown: root.brightnessMonitor.setBrightness(root.brightnessMonitor.brightness - 0.05)
        onScrollUp: root.brightnessMonitor.setBrightness(root.brightnessMonitor.brightness + 0.05)
        onMovedAway: GlobalStates.osdBrightnessOpen = false
        onPressed: event => {
            if (event.button === Qt.LeftButton)
                GlobalStates.sidebarLeftOpen = !GlobalStates.sidebarLeftOpen;
        }

        // Visual content
        ScrollHint {
            reveal: barLeftSideMouseArea.hovered
            icon: "light_mode"
            tooltipText: Translation.tr("Scroll to change brightness")
            side: "left"
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
        }

        RowLayout {
            id: leftSectionRowLayout
            anchors.fill: parent
            spacing: 0

            LeftSidebarButton { // Left sidebar button
                id: leftSidebarButton
                Layout.alignment: Qt.AlignVCenter
                Layout.leftMargin: Appearance.rounding.screenRounding
                colBackground: barLeftSideMouseArea.hovered ? Appearance.colors.colLayer1Hover : ColorUtils.transparentize(Appearance.colors.colLayer1Hover, 1)
            }

            BarGroup {
                id: workspacesGroup
                Layout.leftMargin: 10 + (leftSidebarButton.visible ? 0 : Appearance.rounding.screenRounding)
                Layout.rightMargin: Appearance.rounding.screenRounding
                Layout.fillHeight: true
                Workspaces {
                    id: workspacesWidget
                    Layout.fillHeight: true
                    Layout.fillWidth: true
                }
            }

        }
    }

    Item { // Middle section
        id: middleSection
        anchors {
            top: parent.top
            bottom: parent.bottom
            left: parent.left
            right: parent.right
        }
        opacity: root.notifVisible ? 0 : 1
        Behavior on opacity { NumberAnimation { duration: Appearance.animation.elementMoveFast.duration; easing.type: Appearance.animation.elementMoveFast.type } }

        BarGroup {
            id: leftCenterGroup
            anchors.right: leftSeparator.left
            anchors.rightMargin: 4
            anchors.verticalCenter: parent.verticalCenter
            readonly property bool isExpanded: (mediaWidget.isActive || root.useShortenedForm >= 1)
            implicitWidth: isExpanded ? root.centerSideModuleWidth : calculatedImplicitWidth

            Behavior on implicitWidth {
                animation: Appearance.animation.elementResize.numberAnimation.createObject(leftCenterGroup)
            }

            Resources {
                alwaysShowAllResources: root.useShortenedForm === 2
                Layout.fillWidth: root.useShortenedForm === 2
            }

            Media {
                id: mediaWidget
                visible: root.useShortenedForm < 2
                Layout.fillWidth: mediaWidget.isActive
            }
        }

        Rectangle {
            id: leftSeparator
            anchors.right: middleCenterGroup.left
            anchors.rightMargin: 4
            anchors.verticalCenter: parent.verticalCenter
            height: parent.height - Appearance.sizes.baseBarHeight / 3 * 2
            width: 1
            color: Appearance.colors.colOutlineVariant
        }

        BarGroup {
            id: middleCenterGroup
            showBackground: false
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.verticalCenter: parent.verticalCenter
            ActiveWindow {
                id: activeWindowWidget
                Layout.fillWidth: true
                Layout.fillHeight: true
                visible: root.useShortenedForm === 0
            }
        }

        Rectangle {
            id: rightSeparator
            anchors.left: middleCenterGroup.right
            anchors.leftMargin: 4
            anchors.verticalCenter: parent.verticalCenter
            height: parent.height - Appearance.sizes.baseBarHeight / 3 * 2
            width: 1
            color: Appearance.colors.colOutlineVariant
        }

        MouseArea {
            id: rightCenterGroup
            anchors.left: rightSeparator.right
            anchors.leftMargin: 4
            anchors.verticalCenter: parent.verticalCenter
            implicitWidth: root.centerSideModuleWidth
            implicitHeight: rightCenterGroupContent.implicitHeight

            onPressed: {
                GlobalStates.sidebarRightOpen = !GlobalStates.sidebarRightOpen;
            }

            Connections {
                target: TimerService
                function onStopwatchRunningChanged() {
                    if (TimerService.stopwatchRunning) {
                        rightCenterGroupContent.prefersClock = false;
                    }
                }
            }

            BarGroup {
                id: rightCenterGroupContent
                anchors.fill: parent

                property bool prefersClock: false

                StackLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    currentIndex: ((TimerService.stopwatchRunning || TimerService.stopwatchTime > 0) && !rightCenterGroupContent.prefersClock) ? 0 : 1
                    
                    TimerWidget {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        
                        MouseArea {
                            anchors.fill: parent
                            onClicked: rightCenterGroupContent.prefersClock = true
                        }
                    }

                    ClockWidget {
                        showDate: (Config.options.bar.verbose && root.useShortenedForm < 2)
                        Layout.fillWidth: true
                        Layout.fillHeight: true

                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                if (TimerService.stopwatchRunning || TimerService.stopwatchTime > 0) {
                                    rightCenterGroupContent.prefersClock = false;
                                }
                            }
                        }
                    }
                }

                VerticalBarSeparator {
                    visible: Config.options.bar.weather.enable || Config.options.bar.prayerTimes.enable
                }

                // Weather / Prayer Times — cycling
                Item {
                    id: weatherPrayerCycler
                    readonly property bool showWeather: Config.options.bar.weather.enable
                    readonly property bool showPrayer: Config.options.bar.prayerTimes.enable
                    readonly property bool bothActive: showWeather && showPrayer
                    property bool showingWeather: showWeather

                    visible: showWeather || showPrayer
                    Layout.alignment: Qt.AlignVCenter
                    implicitWidth: cyclerStack.implicitWidth
                    implicitHeight: cyclerStack.implicitHeight

                    Timer {
                        id: cycleTimer
                        interval: 30000
                        running: weatherPrayerCycler.bothActive
                        repeat: true
                        onTriggered: weatherPrayerCycler.showingWeather = !weatherPrayerCycler.showingWeather
                    }

                    function cycle() {
                        showingWeather = !showingWeather;
                        cycleTimer.restart();
                    }

                    StackLayout {
                        id: cyclerStack
                        anchors.centerIn: parent
                        currentIndex: (!weatherPrayerCycler.showWeather || (weatherPrayerCycler.bothActive && !weatherPrayerCycler.showingWeather)) ? 1 : 0

                        Loader {
                            active: weatherPrayerCycler.showWeather
                            sourceComponent: WeatherBar {
                                onPressed: if (weatherPrayerCycler.bothActive) weatherPrayerCycler.cycle()
                            }
                        }

                        Loader {
                            active: weatherPrayerCycler.showPrayer
                            sourceComponent: PrayerTimesBar {
                                onPressed: if (weatherPrayerCycler.bothActive) weatherPrayerCycler.cycle()
                            }
                        }
                    }
                }


                UtilButtons {
                    visible: (Config.options.bar.verbose && root.useShortenedForm === 0)
                    Layout.alignment: Qt.AlignVCenter
                }
            }
        }
    }

    FocusedScrollMouseArea { // Right side | scroll to change volume
        id: barRightSideMouseArea

        anchors {
            top: parent.top
            bottom: parent.bottom
            left: rightCenterGroup.right
            right: parent.right
        }
        implicitWidth: rightSectionRowLayout.implicitWidth
        implicitHeight: Appearance.sizes.baseBarHeight
        opacity: root.notifVisible ? 0 : 1
        Behavior on opacity { NumberAnimation { duration: Appearance.animation.elementMoveFast.duration; easing.type: Appearance.animation.elementMoveFast.type } }

        onScrollDown: Audio.decrementVolume();
        onScrollUp: Audio.incrementVolume();
        onMovedAway: GlobalStates.osdVolumeOpen = false;
        onPressed: event => {
            if (event.button === Qt.LeftButton) {
                GlobalStates.sidebarRightOpen = !GlobalStates.sidebarRightOpen;
            }
        }

        // Visual content
        ScrollHint {
            reveal: barRightSideMouseArea.hovered
            icon: "volume_up"
            tooltipText: Translation.tr("Scroll to change volume")
            side: "right"
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
        }

        RowLayout {
            id: rightSectionRowLayout
            anchors.fill: parent
            spacing: 5
            layoutDirection: Qt.RightToLeft

            AnimatedBarLogo {
                Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
                Layout.rightMargin: Appearance.rounding.screenRounding
            }

            RippleButton { // Right sidebar button
                id: rightSidebarButton

                Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
                Layout.rightMargin: 0
                Layout.fillWidth: false

                implicitWidth: indicatorsRowLayout.implicitWidth + 12 * 2
                implicitHeight: indicatorsRowLayout.implicitHeight + 6 * 2

                buttonRadius: Appearance.rounding.full
                colBackground: barRightSideMouseArea.hovered ? Appearance.colors.colLayer1Hover : ColorUtils.transparentize(Appearance.colors.colLayer1Hover, 1)
                colBackgroundHover: Appearance.colors.colLayer1Hover
                colRipple: Appearance.colors.colLayer1Active
                colBackgroundToggled: Appearance.colors.colSecondaryContainer
                colBackgroundToggledHover: Appearance.colors.colSecondaryContainerHover
                colRippleToggled: Appearance.colors.colSecondaryContainerActive
                toggled: GlobalStates.sidebarRightOpen
                property color colText: toggled ? Appearance.m3colors.m3onSecondaryContainer : Appearance.colors.colOnLayer0

                Behavior on colText {
                    animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
                }

                onPressed: {
                    GlobalStates.sidebarRightOpen = !GlobalStates.sidebarRightOpen;
                }

                RowLayout {
                    id: indicatorsRowLayout
                    anchors.centerIn: parent
                    spacing: 12

                    Revealer {
                        reveal: Audio.sink?.audio?.muted ?? false
                        Layout.fillHeight: true
                        MaterialSymbol {
                            text: "volume_off"
                            iconSize: Appearance.font.pixelSize.larger
                            color: rightSidebarButton.colText
                        }
                    }
                    Revealer {
                        reveal: Audio.source?.audio?.muted ?? false
                        Layout.fillHeight: true
                        MaterialSymbol {
                            text: "mic_off"
                            iconSize: Appearance.font.pixelSize.larger
                            color: rightSidebarButton.colText
                        }
                    }
                    HyprlandXkbIndicator {
                        Layout.alignment: Qt.AlignVCenter
                        color: rightSidebarButton.colText
                    }
                    Revealer {
                        reveal: Notifications.silent || Notifications.unread > 0
                        Layout.fillHeight: true
                        NotificationUnreadCount {
                            id: notificationUnreadCount
                        }
                    }
                    MaterialSymbol {
                        text: Network.materialSymbol
                        iconSize: Appearance.font.pixelSize.larger
                        color: rightSidebarButton.colText
                    }
                    MaterialSymbol {
                        visible: BluetoothStatus.available
                        text: BluetoothStatus.connected ? "bluetooth_connected" : BluetoothStatus.enabled ? "bluetooth" : "bluetooth_disabled"
                        iconSize: Appearance.font.pixelSize.larger
                        color: rightSidebarButton.colText
                    }
                }
            }

            // Battery (Moved to far right and wrapped in BarGroup)
            BarGroup {
                visible: (root.useShortenedForm < 2 && Battery.available)
                Layout.alignment: Qt.AlignVCenter
                Layout.leftMargin: 4
                BatteryIndicator {
                    Layout.alignment: Qt.AlignVCenter
                }
            }

            SysTray {
                visible: root.useShortenedForm === 0
                Layout.fillWidth: false
                Layout.fillHeight: true
                invertSide: Config?.options.bar.bottom
            }

            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true
            }
        }
    }

    // Notification overlay — replaces the whole bar when popups are active
    Item {
        id: notifOverlay
        anchors.fill: parent
        opacity: root.notifVisible ? 1 : 0
        visible: opacity > 0

        Behavior on opacity {
            NumberAnimation {
                duration: Appearance.animation.elementMoveFast.duration
                easing.type: Appearance.animation.elementMoveFast.type
            }
        }

        property var firstGroup: Notifications.popupAppNameList.length > 0
            ? Notifications.popupGroupsByAppName[Notifications.popupAppNameList[0]]
            : null
        property var firstNotif: notifOverlay.firstGroup?.notifications[
            (notifOverlay.firstGroup?.notifications.length ?? 1) - 1
        ] ?? null
        property int extraCount: Math.max(0, Notifications.popupList.length - 1)

        // Inverted background — flat rectangle matching the hug bar shape
        Rectangle {
            anchors.fill: parent
            radius: 0
            color: Appearance.colors.colOnLayer0
        }

        // Dismiss + count pinned to the right edge
        RowLayout {
            anchors.right: parent.right
            anchors.rightMargin: Appearance.rounding.screenRounding + 8
            anchors.verticalCenter: parent.verticalCenter
            spacing: 6

            Revealer {
                reveal: notifOverlay.extraCount > 0
                StyledText {
                    font.pixelSize: Appearance.font.pixelSize.smaller
                    color: ColorUtils.transparentize(Appearance.colors.colLayer0Base, 0.35)
                    text: `+${notifOverlay.extraCount}`
                }
            }

            RippleButton {
                implicitWidth: 22
                implicitHeight: 22
                buttonRadius: Appearance.rounding.full
                colBackground: "transparent"
                colBackgroundHover: ColorUtils.transparentize(Appearance.colors.colLayer0Base, 0.85)
                colRipple: ColorUtils.transparentize(Appearance.colors.colLayer0Base, 0.75)
                onClicked: {
                    Notifications.popupList.forEach(n => {
                        Notifications.discardNotification(n.notificationId);
                    });
                }
                MaterialSymbol {
                    anchors.centerIn: parent
                    text: "close"
                    iconSize: Appearance.font.pixelSize.normal
                    color: Appearance.colors.colLayer0Base
                }
            }
        }

        // Centered content: icon + two-line text (mirrors active window layout)
        Item {
            anchors.fill: parent
            anchors.leftMargin: 50
            anchors.rightMargin: 50

            RowLayout {
                anchors.centerIn: parent
                spacing: 8

                NotificationAppIcon {
                    Layout.alignment: Qt.AlignVCenter
                    implicitSize: 20
                    image: notifOverlay.firstNotif?.image ?? ""
                    appIcon: notifOverlay.firstGroup?.appIcon ?? ""
                    summary: notifOverlay.firstNotif?.summary ?? ""
                    urgency: notifOverlay.firstNotif?.urgency ?? NotificationUrgency.Normal
                }

                ColumnLayout {
                    Layout.alignment: Qt.AlignVCenter
                    spacing: -4

                    StyledText {
                        Layout.fillWidth: true
                        font.pixelSize: Appearance.font.pixelSize.smaller
                        color: ColorUtils.transparentize(Appearance.colors.colLayer0Base, 0.35)
                        horizontalAlignment: Text.AlignHCenter
                        elide: Text.ElideRight
                        text: notifOverlay.firstNotif?.appName ?? notifOverlay.firstGroup?.appName ?? ""
                    }

                    StyledText {
                        Layout.fillWidth: true
                        font.pixelSize: Appearance.font.pixelSize.small
                        color: Appearance.colors.colLayer0Base
                        horizontalAlignment: Text.AlignHCenter
                        elide: Text.ElideRight
                        text: notifOverlay.firstNotif?.summary ?? ""
                    }
                }
            }
        }
    }
}