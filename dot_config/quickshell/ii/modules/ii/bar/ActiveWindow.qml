import qs.services
import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland

Item {
    id: root
    readonly property HyprlandMonitor monitor: Hyprland.monitorFor(root.QsWindow.window?.screen)
    readonly property Toplevel activeWindow: ToplevelManager.activeToplevel

    property string activeWindowAddress: `0x${activeWindow?.HyprlandToplevel?.address}`
    property bool focusingThisMonitor: HyprlandData.activeWorkspace?.monitor == monitor?.name
    property var biggestWindow: HyprlandData.biggestWindowForWorkspace(HyprlandData.monitors[root.monitor?.id]?.activeWorkspace.id)

    property var activeTodo: null
    property bool todoVisible: false

    implicitWidth: 350
    Layout.fillHeight: true
    implicitHeight: Appearance.sizes.barHeight

    function pickRandomTodo() {
        const pending = Todo.list.filter(t => !t.done)
        if (pending.length === 0) return null
        return pending[Math.floor(Math.random() * pending.length)]
    }

    function showNextTodo() {
        root.activeTodo = root.pickRandomTodo()
        if (root.activeTodo) root.todoVisible = true
    }

    Timer {
        interval: 800
        running: true
        repeat: false
        onTriggered: root.showNextTodo()
    }

    Timer {
        id: hideTimer
        interval: 20000
        running: root.todoVisible
        repeat: false
        onTriggered: {
            root.todoVisible = false
            // Schedule next todo in 20–40 minutes (avg ~30 min = ~2/hour)
            scheduleTimer.interval = 1200000 + Math.floor(Math.random() * 1200000)
            scheduleTimer.restart()
        }
    }

    Timer {
        id: scheduleTimer
        repeat: false
        onTriggered: root.showNextTodo()
    }

    // Accent-tinted light pill behind the active window info (near-white when
    // no music accent is active)
    Rectangle {
        anchors.fill: parent
        radius: Appearance.rounding.normal
        color: Qt.hsla(Appearance.colors.colPrimary.hslHue,
                       Appearance.colors.colPrimary.hslSaturation,
                       0.78, 1)
        opacity: 1

        Behavior on opacity {
            NumberAnimation {
                duration: root.todoVisible
                    ? Appearance.animation.elementMoveEnter.duration
                    : Appearance.animation.elementMoveExit.duration
                easing.type: root.todoVisible
                    ? Appearance.animation.elementMoveEnter.type
                    : Appearance.animation.elementMoveExit.type
                easing.bezierCurve: root.todoVisible
                    ? Appearance.animation.elementMoveEnter.bezierCurve
                    : Appearance.animation.elementMoveExit.bezierCurve
            }
        }
    }

    // Window info — fades out when todo shows
    ColumnLayout {
        anchors.verticalCenter: parent.verticalCenter
        anchors.left: parent.left
        anchors.right: parent.right
        spacing: -4
        opacity: root.todoVisible ? 0 : 1

        Behavior on opacity {
            NumberAnimation {
                duration: root.todoVisible
                    ? Appearance.animation.elementMoveExit.duration
                    : Appearance.animation.elementMoveEnter.duration
                easing.type: Easing.OutCubic
            }
        }

        transform: Translate {
            y: root.todoVisible ? -8 : 0
            Behavior on y {
                NumberAnimation {
                    duration: root.todoVisible
                        ? Appearance.animation.elementMoveExit.duration
                        : Appearance.animation.elementMoveEnter.duration
                    easing.type: root.todoVisible
                        ? Appearance.animation.elementMoveExit.type
                        : Appearance.animation.elementMoveEnter.type
                    easing.bezierCurve: root.todoVisible
                        ? Appearance.animation.elementMoveExit.bezierCurve
                        : Appearance.animation.elementMoveEnter.bezierCurve
                }
            }
        }

        StyledText {
            Layout.fillWidth: true
            font.pixelSize: Appearance.font.pixelSize.smaller
            color: "#B3000000"
            elide: Text.ElideRight
            horizontalAlignment: Text.AlignHCenter
            text: root.focusingThisMonitor && root.activeWindow?.activated && root.biggestWindow ?
                root.activeWindow?.appId :
                (root.biggestWindow?.class) ?? Translation.tr("Desktop")
        }

        StyledText {
            Layout.fillWidth: true
            font.pixelSize: Appearance.font.pixelSize.small
            color: "black"
            elide: Text.ElideRight
            horizontalAlignment: Text.AlignHCenter
            textFormat: Text.StyledText
            text: {
                let title = root.focusingThisMonitor && root.activeWindow?.activated && root.biggestWindow ?
                    root.activeWindow?.title :
                    (root.biggestWindow?.title) ?? `${Translation.tr("Workspace")} ${monitor?.activeWorkspace?.id ?? 1}`;

                if (title && title.lastIndexOf(" - ") !== -1) {
                    title = title.substring(0, title.lastIndexOf(" - "));
                }

                const limit = 50;
                title = title.length > limit ? title.substring(0, limit) + "..." : title;

                // Escape markup, then tint a leading symbol (e.g. ✳ / ·) in a
                // light accent hue
                title = title.replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;");
                const m = title.match(/^([^\w\s&]+)(\s*)/);
                if (m) {
                    const accent = Qt.hsla(Appearance.colors.colPrimary.hslHue,
                                           Appearance.colors.colPrimary.hslSaturation,
                                           0.55, 1);
                    title = `<font color="${accent}">${m[1]}</font>${m[2]}` + title.slice(m[0].length);
                }
                return title;
            }
        }
    }

    // Todo content — fades in from below when todo shows
    ColumnLayout {
        anchors.verticalCenter: parent.verticalCenter
        anchors.left: parent.left
        anchors.right: parent.right
        spacing: -4
        opacity: root.todoVisible ? 1 : 0
        visible: opacity > 0

        Behavior on opacity {
            NumberAnimation {
                duration: root.todoVisible
                    ? Appearance.animation.elementMoveEnter.duration
                    : Appearance.animation.elementMoveExit.duration
                easing.type: root.todoVisible
                    ? Appearance.animation.elementMoveEnter.type
                    : Appearance.animation.elementMoveExit.type
                easing.bezierCurve: root.todoVisible
                    ? Appearance.animation.elementMoveEnter.bezierCurve
                    : Appearance.animation.elementMoveExit.bezierCurve
            }
        }

        transform: Translate {
            y: root.todoVisible ? 0 : 8
            Behavior on y {
                NumberAnimation {
                    duration: root.todoVisible
                        ? Appearance.animation.elementMoveEnter.duration
                        : Appearance.animation.elementMoveExit.duration
                    easing.type: root.todoVisible
                        ? Appearance.animation.elementMoveEnter.type
                        : Appearance.animation.elementMoveExit.type
                    easing.bezierCurve: root.todoVisible
                        ? Appearance.animation.elementMoveEnter.bezierCurve
                        : Appearance.animation.elementMoveExit.bezierCurve
                }
            }
        }

        StyledText {
            Layout.fillWidth: true
            font.pixelSize: Appearance.font.pixelSize.smaller
            color: Appearance.colors.colLayer0Base
            elide: Text.ElideRight
            horizontalAlignment: Text.AlignHCenter
            text: "todo"
        }

        StyledText {
            Layout.fillWidth: true
            font.pixelSize: Appearance.font.pixelSize.small
            color: Appearance.colors.colLayer0Base
            elide: Text.ElideRight
            horizontalAlignment: Text.AlignHCenter
            text: root.activeTodo?.content ?? ""
        }
    }
}
