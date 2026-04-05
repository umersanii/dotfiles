import qs.modules.common
import qs.modules.common.widgets
import qs.services
import qs
import qs.modules.common.functions

import QtQuick
import QtQuick.Layouts
import Quickshell.Services.Mpris
import Quickshell.Hyprland
import Quickshell.Io

Item {
    id: root
    property bool borderless: Config.options.bar.borderless
    readonly property MprisPlayer activePlayer: MprisController.activePlayer
    readonly property bool isActive: (activePlayer?.playbackState === MprisPlaybackState.Playing || root.showingTitle)
    readonly property string cleanedTitle: StringUtils.cleanMusicTitle(activePlayer?.trackTitle) || Translation.tr("No media")

    property list<real> visualizerPoints: []

    Process {
        id: cavaProc
        running: activePlayer?.playbackState === MprisPlaybackState.Playing
        onRunningChanged: {
            if (!cavaProc.running) {
                root.visualizerPoints = [];
            }
        }
        command: ["cava", "-p", `${FileUtils.trimFileProtocol(Directories.scriptPath)}/cava/raw_output_config.txt`]
        stdout: SplitParser {
            onRead: data => {
                let points = data.split(";").map(p => parseFloat(p.trim())).filter(p => !isNaN(p));
                root.visualizerPoints = points;
            }
        }
    }

    Layout.fillHeight: true
    Layout.fillWidth: isActive
    implicitWidth: rowLayout.implicitWidth + rowLayout.spacing * 2
    implicitHeight: Appearance.sizes.barHeight

    Timer {
        running: activePlayer?.playbackState == MprisPlaybackState.Playing
        interval: Config.options.resources.updateInterval
        repeat: true
        onTriggered: activePlayer.positionChanged()
    }

    property bool showingTitle: false

    Timer {
        id: titleTimer
        interval: 5000
        onTriggered: root.showingTitle = false
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.MiddleButton | Qt.BackButton | Qt.ForwardButton | Qt.RightButton | Qt.LeftButton
        onPressed: (event) => {
            if (event.button === Qt.MiddleButton) {
                MprisController.togglePlaying();
            } else if (event.button === Qt.BackButton) {
                MprisController.previous();
            } else if (event.button === Qt.ForwardButton || event.button === Qt.RightButton) {
                MprisController.next();
            } else if (event.button === Qt.LeftButton) {
                root.showingTitle = !root.showingTitle;
                if (root.showingTitle) titleTimer.restart();
            }
        }
    }

    RowLayout { // Real content
        id: rowLayout

        spacing: 4
        anchors.fill: parent

        ClippedFilledCircularProgress {
            id: mediaCircProg
            Layout.alignment: Qt.AlignVCenter
            lineWidth: Appearance.rounding.unsharpen
            value: activePlayer?.position / activePlayer?.length
            implicitSize: 20
            colPrimary: "white"
            enableAnimation: true

            Item {
                anchors.centerIn: parent
                width: mediaCircProg.implicitSize
                height: mediaCircProg.implicitSize
                
                MaterialSymbol {
                    anchors.centerIn: parent
                    fill: 1
                    text: activePlayer?.playbackState === MprisPlaybackState.Playing ? "pause" : "music_note"
                    iconSize: Appearance.font.pixelSize.normal
                    color: "white"
                }
            }
        }

        Item { // Title & Visualizer container
            id: mediaTitleContainer
            visible: Config.options.bar.verbose && (root.isActive || width > 0)
            Layout.alignment: Qt.AlignVCenter
            Layout.fillWidth: root.isActive
            Layout.fillHeight: true
            Layout.rightMargin: root.isActive ? rowLayout.spacing : 0
            Layout.preferredWidth: root.isActive ? 150 : 0

            Behavior on Layout.preferredWidth {
                animation: Appearance.animation.elementResize.numberAnimation.createObject(mediaTitleContainer)
            }

            opacity: isActive ? 1 : 0
            Behavior on opacity {
                NumberAnimation { duration: 250 }
            }
            clip: true

            WaveVisualizer {
                anchors.fill: parent
                // Visualizer margins for the cava height effect
                anchors.topMargin: 4
                anchors.bottomMargin: 4
                opacity: root.showingTitle ? 0 : 1
                Behavior on opacity { NumberAnimation { duration: 250 } }

                live: root.activePlayer?.playbackState === MprisPlaybackState.Playing
                points: root.visualizerPoints
                maxVisualizerValue: 1000
                smoothing: 2
                color: "white"
                fillAlpha: 1.0
                centerBass: true
                horizontalFade: true
            }

            StyledText {
                id: mediaTitle
                anchors.fill: parent
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                elide: Text.ElideRight
                color: "white"
                text: `${cleanedTitle}${activePlayer?.trackArtist ? ' • ' + activePlayer.trackArtist : ''}`
                opacity: root.showingTitle ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: 250 } }
                font.pixelSize: Appearance.font.pixelSize.small
            }
        }

    }

}
