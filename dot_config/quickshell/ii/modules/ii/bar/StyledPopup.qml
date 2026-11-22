import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Wayland

LazyLoader {
    id: root

    property Item hoverTarget
    default property Item contentItem
    property real popupBackgroundMargin: 0

    // clickToShow: tap (press) the target to toggle, click anywhere else (GlobalFocusGrab) to dismiss.
    // Otherwise: show while hovered.
    readonly property bool clickMode: Config.options.bar.tooltips.clickToShow
    property bool open: false
    property real _dismissedAt: 0

    // `visible` guard: a MouseArea hidden while hovered (e.g. StackLayout swap in the
    // weather/prayer cycler) never gets hover-leave, so containsMouse sticks true.
    active: hoverTarget && hoverTarget.visible && (clickMode ? open : hoverTarget.containsMouse)

    onOpenChanged: GlobalStates.barPopupOpen = open

    property Connections _clickConn: Connections {
        target: root.clickMode ? root.hoverTarget : null
        ignoreUnknownSignals: true
        function onPressed(mouse) {
            if (mouse.button !== Qt.LeftButton) return;
            // the click that dismissed us (outside grab) shouldn't immediately reopen
            if (Date.now() - root._dismissedAt < 300) return;
            if (root.open) {
                root.open = false;
            } else {
                GlobalFocusGrab.dismiss(); // one popup at a time
                root.open = true;
            }
        }
        function onVisibleChanged() {
            if (!root.hoverTarget.visible) root.open = false;
        }
    }

    property Connections _dismissConn: Connections {
        target: GlobalFocusGrab
        function onDismissed() {
            if (!root.open) return;
            root.open = false;
            root._dismissedAt = Date.now();
        }
    }

    component: PanelWindow {
        id: popupWindow
        color: "transparent"

        anchors.left: !Config.options.bar.vertical || (Config.options.bar.vertical && !Config.options.bar.bottom)
        anchors.right: Config.options.bar.vertical && Config.options.bar.bottom
        anchors.top: Config.options.bar.vertical || (!Config.options.bar.vertical && !Config.options.bar.bottom)
        anchors.bottom: !Config.options.bar.vertical && Config.options.bar.bottom

        implicitWidth: popupBackground.implicitWidth + Appearance.sizes.elevationMargin * 2 + root.popupBackgroundMargin
        implicitHeight: popupBackground.implicitHeight + Appearance.sizes.elevationMargin * 2 + root.popupBackgroundMargin

        mask: Region {
            item: popupBackground
        }

        Component.onCompleted: if (root.clickMode) GlobalFocusGrab.addDismissable(popupWindow)
        Component.onDestruction: GlobalFocusGrab.removeDismissable(popupWindow)

        exclusionMode: ExclusionMode.Ignore
        exclusiveZone: 0
        margins {
            // centered on the target, clamped so the popup never runs off-screen
            left: {
                if (!Config.options.bar.vertical) {
                    const x = root.QsWindow?.mapFromItem(
                        root.hoverTarget,
                        (root.hoverTarget.width - popupBackground.implicitWidth) / 2, 0
                    ).x ?? 0;
                    const maxX = (popupWindow.screen?.width ?? 1e6) - popupWindow.implicitWidth;
                    return Math.max(0, Math.min(x, maxX));
                }
                return Appearance.sizes.verticalBarWidth
            }
            top: {
                if (!Config.options.bar.vertical) return Appearance.sizes.barHeight;
                const y = root.QsWindow?.mapFromItem(
                    root.hoverTarget,
                    (root.hoverTarget.height - popupBackground.implicitHeight) / 2, 0
                ).y ?? 0;
                const maxY = (popupWindow.screen?.height ?? 1e6) - popupWindow.implicitHeight;
                return Math.max(0, Math.min(y, maxY));
            }
            right: Appearance.sizes.verticalBarWidth
            bottom: Appearance.sizes.barHeight
        }
        WlrLayershell.namespace: "quickshell:popup"
        WlrLayershell.layer: WlrLayer.Overlay

        StyledRectangularShadow {
            target: popupBackground
        }

        Rectangle {
            id: popupBackground
            readonly property real margin: 10
            anchors {
                fill: parent
                leftMargin: Appearance.sizes.elevationMargin + root.popupBackgroundMargin * (!popupWindow.anchors.left)
                rightMargin: Appearance.sizes.elevationMargin + root.popupBackgroundMargin * (!popupWindow.anchors.right)
                topMargin: Appearance.sizes.elevationMargin + root.popupBackgroundMargin * (!popupWindow.anchors.top)
                bottomMargin: Appearance.sizes.elevationMargin + root.popupBackgroundMargin * (!popupWindow.anchors.bottom)
            }
            implicitWidth: root.contentItem.implicitWidth + margin * 2
            implicitHeight: root.contentItem.implicitHeight + margin * 2
            color: Appearance.m3colors.m3surfaceContainer
            radius: Appearance.rounding.small
            children: [root.contentItem]

            border.width: 1
            border.color: Appearance.colors.colLayer0Border
        }
    }
}
