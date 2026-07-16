import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.ii.overlay

OverlayBackground {
    id: root

    property alias content: textInput.text
    property bool isClickthrough: false

    Component.onCompleted: {
        linksFile.reload();
    }

    function saveContent() {
        if (!textInput)
            return;
        linksFile.setText(root.content);
    }

    function focusAtEnd() {
        if (!textInput)
            return;
        textInput.forceActiveFocus();
        textInput.cursorPosition = root.content.length;
    }

    function parseLinks(text) {
        if (!text || text.length === 0)
            return [];
        const lines = text.split("\n");
        const entries = [];
        for (let i = 0; i < lines.length; i++) {
            const line = lines[i].trim();
            if (line.length === 0)
                continue;

            // Format: "Label | URL" or just "URL"
            const pipeIndex = line.indexOf("|");
            if (pipeIndex !== -1) {
                const label = line.substring(0, pipeIndex).trim();
                const url = line.substring(pipeIndex + 1).trim();
                if (url.length > 0)
                    entries.push({ label: label || url, url: url });
            } else {
                // Check if the line itself is a URL
                if (line.match(/^https?:\/\//))
                    entries.push({ label: line, url: line });
                else
                    entries.push({ label: line, url: "" });
            }
        }
        return entries;
    }

    implicitWidth: 350
    implicitHeight: 300

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        // Link list view
        ScrollView {
            id: linkListView
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            visible: !editMode.checked
            ScrollBar.vertical.policy: ScrollBar.AsNeeded

            ColumnLayout {
                width: linkListView.availableWidth
                spacing: 2

                Repeater {
                    model: ScriptModel {
                        values: root.parseLinks(root.content)
                    }
                    delegate: RippleButton {
                        id: linkButton
                        required property var modelData
                        required property int index
                        Layout.fillWidth: true
                        implicitHeight: linkRow.implicitHeight + 12
                        buttonRadius: 8
                        enabled: modelData.url.length > 0

                        onClicked: {
                            if (modelData.url.length > 0)
                                Quickshell.execDetached(["xdg-open", modelData.url]);
                        }

                        contentItem: RowLayout {
                            id: linkRow
                            anchors {
                                left: parent.left
                                right: parent.right
                                leftMargin: 16
                                rightMargin: 16
                            }
                            spacing: 10

                            MaterialSymbol {
                                text: linkButton.modelData.url.length > 0 ? "link" : "label"
                                iconSize: 18
                                color: Appearance.colors.colOnLayer1
                                Layout.alignment: Qt.AlignVCenter
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 0

                                StyledText {
                                    Layout.fillWidth: true
                                    text: linkButton.modelData.label
                                    elide: Text.ElideRight
                                    color: Appearance.colors.colOnLayer1
                                    font.pixelSize: Appearance.font.pixelSize.normal
                                }

                                StyledText {
                                    Layout.fillWidth: true
                                    text: linkButton.modelData.url
                                    elide: Text.ElideMiddle
                                    color: Appearance.colors.colSubtext
                                    font.pixelSize: Appearance.font.pixelSize.smaller
                                    visible: linkButton.modelData.url.length > 0 && linkButton.modelData.url !== linkButton.modelData.label
                                }
                            }

                            RippleButton {
                                id: copyUrlButton
                                visible: linkButton.modelData.url.length > 0
                                implicitWidth: 28
                                implicitHeight: 28
                                buttonRadius: 14
                                property bool justCopied: false
                                Layout.alignment: Qt.AlignVCenter

                                Timer {
                                    id: resetCopy
                                    interval: 700
                                    onTriggered: copyUrlButton.justCopied = false
                                }

                                onClicked: {
                                    Quickshell.clipboardText = linkButton.modelData.url;
                                    justCopied = true;
                                    resetCopy.start();
                                }

                                contentItem: MaterialSymbol {
                                    anchors.centerIn: parent
                                    text: copyUrlButton.justCopied ? "check" : "content_copy"
                                    iconSize: 16
                                    color: Appearance.colors.colOnLayer1
                                }
                            }
                        }
                    }
                }

                // Empty state
                Item {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    visible: root.content.trim().length === 0

                    StyledText {
                        anchors.centerIn: parent
                        text: Translation.tr("No links yet.\nSwitch to edit mode to add some.")
                        color: Appearance.colors.colSubtext
                        horizontalAlignment: Text.AlignHCenter
                    }
                }
            }
        }

        // Editor view
        ScrollView {
            id: editorScrollView
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            visible: editMode.checked
            ScrollBar.vertical.policy: ScrollBar.AsNeeded

            StyledTextArea {
                id: textInput
                anchors {
                    left: parent.left
                    right: parent.right
                }
                wrapMode: TextEdit.Wrap
                placeholderText: Translation.tr("Add links, one per line:\n\nLabel | https://url.com\nhttps://bare-url.com\nJust a label (no link)\n\nExamples:\nGitHub | https://github.com\nArch Wiki | https://wiki.archlinux.org\nhttps://reddit.com")
                selectByMouse: true
                persistentSelection: true
                textFormat: TextEdit.PlainText
                background: null
                padding: 16

                onTextChanged: {
                    if (textInput.activeFocus) {
                        saveDebounce.restart();
                    }
                }
            }
        }

        // Bottom bar
        RowLayout {
            Layout.fillWidth: true
            Layout.margins: 8
            spacing: 4

            StyledText {
                Layout.fillWidth: true
                text: {
                    if (editMode.checked) {
                        return saveDebounce.running ? Translation.tr("Saving...") : Translation.tr("Saved    ");
                    }
                    const links = root.parseLinks(root.content);
                    const count = links.filter(l => l.url.length > 0).length;
                    return count + (count === 1 ? " link" : " links");
                }
                color: Appearance.colors.colSubtext
                horizontalAlignment: editMode.checked ? Text.AlignRight : Text.AlignLeft
                Layout.leftMargin: 8
            }

            RippleButton {
                id: editMode
                checkable: true
                implicitWidth: 32
                implicitHeight: 32
                buttonRadius: 16

                colBackgroundToggled: Appearance.colors.colSecondaryContainer
                colBackgroundToggledHover: Appearance.colors.colSecondaryContainerHover
                colRippleToggled: Appearance.colors.colSecondaryContainerActive

                contentItem: MaterialSymbol {
                    anchors.centerIn: parent
                    text: editMode.checked ? "visibility" : "edit"
                    iconSize: 18
                    color: editMode.checked ? Appearance.colors.colOnSecondaryContainer : Appearance.colors.colOnLayer1
                }

                StyledToolTip {
                    text: editMode.checked ? Translation.tr("View links") : Translation.tr("Edit links")
                }
            }
        }
    }

    Timer {
        id: saveDebounce
        interval: 500
        repeat: false
        onTriggered: saveContent()
    }

    FileView {
        id: linksFile
        path: Qt.resolvedUrl(Directories.linksPath)
        onLoaded: {
            root.content = linksFile.text();
        }
        onLoadFailed: error => {
            if (error === FileViewError.FileNotFound) {
                root.content = "";
                linksFile.setText(root.content);
            } else {
                console.log("[Overlay LinkBoard] Error loading file: " + error);
            }
        }
    }
}
