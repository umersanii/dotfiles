import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs
import qs.services
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets
import qs.modules.common.widgets.widgetCanvas
import qs.modules.ii.background.widgets

AbstractBackgroundWidget {
    id: root

    configEntryName: "todo"
    visibleWhenLocked: false

    implicitWidth: 400
    implicitHeight: Math.min(600, Math.max(300, contentColumn.implicitHeight + 40))

    readonly property var activeList: GlobalStates.showWorkTodo ? WorkTodo.list : Todo.list
    readonly property int pendingCount: {
        let count = 0
        for (let i = 0; i < activeList.length; i++) {
            if (!activeList[i].done) count++
        }
        return count
    }

    StyledDropShadow {
        target: backgroundShape
    }

    Rectangle {
        id: backgroundShape
        anchors.fill: parent
        color: Appearance.colors.colLayer1
        radius: Appearance.rounding.large
        border.width: 1
        border.color: Appearance.colors.colLayer0Border

        ColumnLayout {
            id: contentColumn
            anchors {
                fill: parent
                margins: 20
            }
            spacing: 12

            // Header
            RowLayout {
                Layout.fillWidth: true
                spacing: 10

                MaterialSymbol {
                    text: "checklist"
                    iconSize: Appearance.font.pixelSize.larger
                    color: Appearance.colors.colPrimary
                }

                StyledText {
                    text: GlobalStates.showWorkTodo ? Translation.tr("Work Todo") : Translation.tr("To Do")
                    font.pixelSize: Appearance.font.pixelSize.large
                    font.weight: Font.Bold
                    color: needsColText ? colText : Appearance.colors.colOnLayer1
                }

                Item { Layout.fillWidth: true }

                // Summary badge
                Rectangle {
                    Layout.preferredWidth: summaryText.implicitWidth + 16
                    Layout.preferredHeight: 28
                    color: root.pendingCount > 0 ? Appearance.colors.colPrimaryContainer : Appearance.colors.colSecondaryContainer
                    radius: Appearance.rounding.full

                    StyledText {
                        id: summaryText
                        anchors.centerIn: parent
                        text: `${root.pendingCount}/${root.activeList.length}`
                        font.pixelSize: Appearance.font.pixelSize.small
                        font.weight: Font.Medium
                        color: root.pendingCount > 0 ? Appearance.colors.colOnPrimaryContainer : Appearance.colors.colOnSecondaryContainer
                    }
                }
            }

            // Divider
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 1
                color: Appearance.colors.colOutlineVariant
            }

            // Todo list
            ScrollView {
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true

                ColumnLayout {
                    width: parent.parent.width
                    spacing: 6

                    Repeater {
                        model: root.activeList

                        delegate: Rectangle {
                            required property var modelData
                            required property int index
                            Layout.fillWidth: true
                            implicitHeight: todoItemLayout.implicitHeight + 12
                            color: "transparent"
                            radius: Appearance.rounding.small

                            RowLayout {
                                id: todoItemLayout
                                anchors {
                                    fill: parent
                                    leftMargin: 12
                                    rightMargin: 12
                                    topMargin: 6
                                    bottomMargin: 6
                                }
                                spacing: 10

                                // Status indicator (view only)
                                MaterialSymbol {
                                    Layout.preferredWidth: 28
                                    Layout.preferredHeight: 28
                                    Layout.alignment: Qt.AlignTop
                                    text: parent.parent.modelData.done ? "check_circle" : "radio_button_unchecked"
                                    iconSize: Appearance.font.pixelSize.normal
                                    color: parent.parent.modelData.done ? Appearance.colors.colPrimary : root.needsColText ? root.colText : Appearance.colors.colOnSurfaceVariant
                                }

                                // Text
                                StyledText {
                                    Layout.fillWidth: true
                                    text: parent.parent.modelData.content
                                    font.pixelSize: Appearance.font.pixelSize.normal
                                    color: parent.parent.modelData.done ? Appearance.colors.colOnSurfaceVariant : root.needsColText ? root.colText : Appearance.colors.colOnSurface
                                    font.strikeout: parent.parent.modelData.done
                                    wrapMode: Text.Wrap
                                }
                            }
                        }
                    }

                    // Empty state
                    Item {
                        visible: root.activeList.length === 0
                        Layout.fillWidth: true
                        Layout.preferredHeight: 150
                        Layout.alignment: Qt.AlignCenter

                        ColumnLayout {
                            anchors.centerIn: parent
                            spacing: 10

                            MaterialSymbol {
                                Layout.alignment: Qt.AlignHCenter
                                text: "task_alt"
                                iconSize: Appearance.font.pixelSize.huge
                                color: root.needsColText ? root.colText : Appearance.colors.colOnSurfaceVariant
                                opacity: 0.5
                            }

                            StyledText {
                                Layout.alignment: Qt.AlignHCenter
                                text: Translation.tr("No tasks yet")
                                font.pixelSize: Appearance.font.pixelSize.normal
                                color: root.needsColText ? root.colText : Appearance.colors.colOnSurfaceVariant
                            }

                            StyledText {
                                Layout.alignment: Qt.AlignHCenter
                                text: Translation.tr("Use launcher to add tasks")
                                font.pixelSize: Appearance.font.pixelSize.smaller
                                color: root.needsColText ? root.colText : Appearance.colors.colOnSurfaceVariant
                                opacity: 0.7
                            }
                        }
                    }
                }
            }
        }
    }
}
