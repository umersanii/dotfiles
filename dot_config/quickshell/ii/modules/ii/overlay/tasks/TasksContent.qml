import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.ii.overlay

/**
 * Overlay task list backed by the WorkTodo service, so it stays in sync
 * with the Work Todo window.
 */
OverlayBackground {
    id: root

    property bool isClickthrough: false
    readonly property var indexedTasks: WorkTodo.list.map((item, i) => Object.assign({}, item, { originalIndex: i }))
    readonly property var pendingTasks: indexedTasks.filter(t => !t.done)
    readonly property var doneTasks: indexedTasks.filter(t => t.done)

    function addTask() {
        const text = taskInput.text.trim();
        if (text.length === 0)
            return;
        WorkTodo.addTask(text);
        taskInput.text = "";
    }

    implicitWidth: 350
    implicitHeight: 400

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        // Add task row
        Rectangle {
            Layout.fillWidth: true
            Layout.margins: 10
            implicitHeight: 40
            radius: Appearance.rounding.small
            color: Appearance.colors.colLayer2
            visible: !root.isClickthrough

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 12
                anchors.rightMargin: 4
                spacing: 6

                MaterialSymbol {
                    text: "add_task"
                    iconSize: 18
                    color: Appearance.colors.colSubtext
                }

                TextField {
                    id: taskInput
                    Layout.fillWidth: true
                    background: null
                    color: Appearance.colors.colOnLayer1
                    renderType: Text.NativeRendering
                    selectedTextColor: Appearance.m3colors.m3onSecondaryContainer
                    selectionColor: Appearance.colors.colSecondaryContainer
                    placeholderText: Translation.tr("Add a task, press Enter")
                    placeholderTextColor: Appearance.m3colors.m3outline
                    font.family: Appearance.font.family.main
                    font.pixelSize: Appearance.font.pixelSize.normal
                    onAccepted: root.addTask()
                }
            }
        }

        ScrollView {
            id: taskScrollView
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            ScrollBar.vertical.policy: ScrollBar.AsNeeded

            ColumnLayout {
                width: taskScrollView.availableWidth
                spacing: 2

                Repeater {
                    model: ScriptModel {
                        values: showDone.checked ? root.pendingTasks.concat(root.doneTasks) : root.pendingTasks
                    }
                    delegate: RippleButton {
                        id: taskButton
                        required property var modelData
                        Layout.fillWidth: true
                        Layout.leftMargin: 6
                        Layout.rightMargin: 6
                        implicitHeight: taskRow.implicitHeight + 12
                        buttonRadius: Appearance.rounding.small

                        onClicked: {
                            if (modelData.done)
                                WorkTodo.markUnfinished(modelData.originalIndex);
                            else
                                WorkTodo.markDone(modelData.originalIndex);
                        }

                        contentItem: RowLayout {
                            id: taskRow
                            anchors {
                                left: parent.left
                                right: parent.right
                                leftMargin: 10
                                rightMargin: 6
                            }
                            spacing: 10

                            MaterialSymbol {
                                text: taskButton.modelData.done ? "check_circle" : "radio_button_unchecked"
                                fill: taskButton.modelData.done ? 1 : 0
                                iconSize: 20
                                color: taskButton.modelData.done ? Appearance.colors.colPrimary : Appearance.colors.colOnLayer1
                                Layout.alignment: Qt.AlignVCenter
                            }

                            StyledText {
                                Layout.fillWidth: true
                                text: taskButton.modelData.content
                                wrapMode: Text.Wrap
                                font.strikeout: taskButton.modelData.done
                                color: taskButton.modelData.done ? Appearance.colors.colSubtext : Appearance.colors.colOnLayer1
                            }

                            RippleButton {
                                id: deleteButton
                                visible: taskButton.hovered && !root.isClickthrough
                                implicitWidth: 28
                                implicitHeight: 28
                                buttonRadius: 14
                                Layout.alignment: Qt.AlignVCenter
                                onClicked: WorkTodo.deleteItem(taskButton.modelData.originalIndex)

                                contentItem: MaterialSymbol {
                                    anchors.centerIn: parent
                                    text: "delete"
                                    iconSize: 16
                                    color: Appearance.colors.colOnLayer1
                                }
                            }
                        }
                    }
                }

                // Empty state
                StyledText {
                    Layout.fillWidth: true
                    Layout.topMargin: 40
                    visible: root.pendingTasks.length === 0 && !showDone.checked
                    text: Translation.tr("All clear!")
                    color: Appearance.colors.colSubtext
                    horizontalAlignment: Text.AlignHCenter
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
                Layout.leftMargin: 8
                text: Translation.tr("%1 left · %2 done").arg(root.pendingTasks.length).arg(root.doneTasks.length)
                color: Appearance.colors.colSubtext
            }

            RippleButton {
                id: showDone
                checkable: true
                implicitWidth: 32
                implicitHeight: 32
                buttonRadius: 16

                colBackgroundToggled: Appearance.colors.colSecondaryContainer
                colBackgroundToggledHover: Appearance.colors.colSecondaryContainerHover
                colRippleToggled: Appearance.colors.colSecondaryContainerActive

                contentItem: MaterialSymbol {
                    anchors.centerIn: parent
                    text: "done_all"
                    iconSize: 18
                    color: showDone.checked ? Appearance.colors.colOnSecondaryContainer : Appearance.colors.colOnLayer1
                }

                StyledToolTip {
                    text: showDone.checked ? Translation.tr("Hide done") : Translation.tr("Show done")
                }
            }
        }
    }
}
