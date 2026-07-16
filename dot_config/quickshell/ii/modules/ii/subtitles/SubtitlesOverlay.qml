import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland

Scope {
    id: root
    property bool active: false

    // ── Transcription daemon ────────────────────────────────────────────────
    Process {
        id: subsProcess
        running: root.active
        command: ["fish", "/home/sani/.config/hypr/custom/scripts/subs-daemon.fish"]
    }

    // ── Overlay window ──────────────────────────────────────────────────────
    Loader {
        id: windowLoader
        active: root.active

        sourceComponent: PanelWindow {
            id: subsRoot
            color: "transparent"

            WlrLayershell.namespace: "quickshell:subtitles"
            WlrLayershell.layer: WlrLayer.Overlay
            exclusiveZone: 0
            exclusionMode: ExclusionMode.Ignore

            anchors { top: true; left: true; right: true }
            margins.top: Appearance.sizes.barHeight + 6
            implicitHeight: 96

            property string subtitle: ""

            FileView {
                id: subsFile
                path: "file:///tmp/subs_current.txt"
                watchChanges: true
                onFileChanged: reload()
                onLoaded: { subsRoot.subtitle = text().trim() }
            }

            Rectangle {
                id: subsContent
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: parent.top

                width: Math.min(subsRoot.width * 0.62, 900)
                height: subsRoot.implicitHeight
                opacity: subsRoot.subtitle !== "" ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: 300 } }

                color: Qt.rgba(0, 0, 0, 0.72)
                radius: Appearance.rounding.normal

                Text {
                    id: subsText
                    anchors.centerIn: parent
                    width: parent.width - 36
                    text: subsRoot.subtitle
                    color: "white"
                    font.family: Appearance.font.family.main
                    font.pixelSize: Appearance.font.pixelSize.larger
                    font.weight: Font.Medium
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.Wrap
                    renderType: Text.QtRendering
                }
            }
        }
    }

    // ── IPC + shortcut ──────────────────────────────────────────────────────
    IpcHandler {
        target: "subtitles"
        function toggle(): void { root.active = !root.active }
        function open():   void { root.active = true  }
        function close():  void { root.active = false }
    }

    GlobalShortcut {
        name: "subtitlesToggle"
        description: "Toggle live subtitle overlay"
        onPressed: root.active = !root.active
    }
}
