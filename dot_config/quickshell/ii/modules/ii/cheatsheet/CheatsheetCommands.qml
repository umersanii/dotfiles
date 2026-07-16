pragma ComponentBehavior: Bound

import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import QtQuick.Layouts
import Quickshell

Item {
    id: root
    property real sectionSpacing: 16
    property real commandSpacing: 6
    implicitWidth: row.implicitWidth
    implicitHeight: row.implicitHeight

    property var sections: [
        {
            name: "System",
            commands: [
                { label: "Full system info", cmd: "inxi -Fazy" },
            ]
        },
        {
            name: "Ollama",
            commands: [
                { label: "Run coder model", cmd: "ollama run qwen2.5-coder:14b" },
            ]
        },
        {
            name: "CC line (Windows)",
            commands: [
                { label: "Install Bun", cmd: "irm bun.sh/install.ps1 | iex" },
                { label: "Run ccstatusline", cmd: "bunx -y ccstatusline@latest" },
            ]
        },
        {
            name: "Markitdown",
            commands: [
                { label: "Convert PDF to Markdown", cmd: "markitdown path-to-file.pdf -o smth.md" },
            ]
        },
        {
            name: "Quickshell",
            commands: [
                { label: "Launch panel", cmd: "quickshell -c ~/.config/quickshell/ii/ &" },
            ]
        },
        {
            name: "Prompter",
            commands: [
                { label: "Interactive mode", cmd: "enhance" },
                { label: "Pipe mode", cmd: "echo \"my rough prompt\" | enhance" },
                { label: "From a file", cmd: "enhance < myprompt.txt" },
            ]
        },
        {
            name: "Downloading",
            commands: [
                { label: "aria2c multi-connection", cmd: "aria2c -x 16 -s 16 -c \"<URL>\"" },
            ]
        },
    ]

    // Split sections into two columns
    property var leftSections: {
        var result = [];
        for (var i = 0; i < sections.length; i += 2) result.push(sections[i]);
        return result;
    }
    property var rightSections: {
        var result = [];
        for (var i = 1; i < sections.length; i += 2) result.push(sections[i]);
        return result;
    }

    Row {
        id: row
        anchors.centerIn: parent
        spacing: 32

        // Left column
        Column {
            spacing: root.sectionSpacing
            Repeater {
                model: root.leftSections
                delegate: SectionBlock {
                    required property var modelData
                    section: modelData
                    commandSpacing: root.commandSpacing
                }
            }
        }

        // Right column
        Column {
            spacing: root.sectionSpacing
            Repeater {
                model: root.rightSections
                delegate: SectionBlock {
                    required property var modelData
                    section: modelData
                    commandSpacing: root.commandSpacing
                }
            }
        }
    }

    component SectionBlock: Column {
        id: sectionBlock
        required property var section
        property real commandSpacing: 6
        spacing: 7

        StyledText {
            font {
                family: Appearance.font.family.title
                pixelSize: Appearance.font.pixelSize.title
                variableAxes: Appearance.font.variableAxes.title
            }
            color: Appearance.colors.colOnLayer0
            text: sectionBlock.section.name
        }

        Column {
            spacing: sectionBlock.commandSpacing
            Repeater {
                model: sectionBlock.section.commands
                delegate: CommandRow {
                    required property var modelData
                    cmdLabel: modelData.label
                    cmdText: modelData.cmd
                }
            }
        }
    }

    component CommandRow: Rectangle {
        id: cmdRow
        required property string cmdLabel
        required property string cmdText
        property bool copied: false

        implicitWidth: cmdRowLayout.implicitWidth + 10 * 2
        implicitHeight: cmdRowLayout.implicitHeight + 7 * 2
        radius: Appearance.rounding.small
        color: Appearance.colors.colLayer2

        RowLayout {
            id: cmdRowLayout
            anchors {
                verticalCenter: parent.verticalCenter
                left: parent.left
                right: parent.right
                leftMargin: 10
                rightMargin: 6
            }
            spacing: 10

            Column {
                Layout.fillWidth: true
                spacing: 2

                StyledText {
                    font.pixelSize: Appearance.font.pixelSize.tiny
                    color: Appearance.colors.colSubtext
                    text: cmdRow.cmdLabel
                }

                StyledText {
                    font.family: Appearance.font.family.monospace
                    font.pixelSize: Appearance.font.pixelSize.small
                    color: Appearance.colors.colOnLayer1
                    text: cmdRow.cmdText
                    elide: Text.ElideRight
                    width: 280
                }
            }

            RippleButton {
                id: copyBtn
                implicitWidth: 30
                implicitHeight: 30
                buttonRadius: Appearance.rounding.full

                onClicked: {
                    Quickshell.clipboardText = cmdRow.cmdText
                    cmdRow.copied = true
                    copyResetTimer.restart()
                }

                Timer {
                    id: copyResetTimer
                    interval: 1500
                    repeat: false
                    onTriggered: cmdRow.copied = false
                }

                contentItem: MaterialSymbol {
                    anchors.centerIn: parent
                    horizontalAlignment: Text.AlignHCenter
                    iconSize: Appearance.font.pixelSize.normal
                    text: cmdRow.copied ? "check" : "content_copy"
                    color: cmdRow.copied ? Appearance.colors.colPrimary : Appearance.colors.colSubtext

                    Behavior on color {
                        animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
                    }
                }
            }
        }
    }
}
