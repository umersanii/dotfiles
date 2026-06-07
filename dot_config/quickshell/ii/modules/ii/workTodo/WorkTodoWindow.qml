import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland

Scope {
    id: root

    readonly property int windowWidth: 400
    readonly property int windowHeight: 560
    readonly property int fabSize: 48
    readonly property int fabMargins: 14
    readonly property int dialogMargins: 20

    PanelWindow {
        id: panelWindow
        visible: GlobalStates.workTodoOpen

        function hide() {
            GlobalStates.workTodoOpen = false
        }

        exclusiveZone: 0
        exclusionMode: ExclusionMode.Ignore
        implicitWidth: root.windowWidth
        implicitHeight: root.windowHeight
        color: "transparent"
        WlrLayershell.namespace: "quickshell:workTodo"
        WlrLayershell.keyboardFocus: GlobalStates.workTodoOpen ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

        // Anchor right side, offset from top to clear the bar
        anchors {
            top: true
            right: true
        }
        margins {
            top: Appearance.sizes.barHeight + Appearance.sizes.hyprlandGapsOut
            right: Appearance.sizes.hyprlandGapsOut
        }

        onVisibleChanged: {
            if (visible) {
                GlobalFocusGrab.addDismissable(panelWindow)
            } else {
                GlobalFocusGrab.removeDismissable(panelWindow)
            }
        }
        Connections {
            target: GlobalFocusGrab
            function onDismissed() {
                panelWindow.hide()
            }
        }

        Keys.onPressed: event => {
            if (event.key === Qt.Key_Escape) {
                panelWindow.hide()
            }
        }

        // Window background
        Rectangle {
            anchors.fill: parent
            color: Appearance.m3colors.m3surfaceContainer
            radius: Appearance.rounding.normal
            clip: true

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 0
                spacing: 0

                // Header
                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: headerRow.implicitHeight + 16
                    color: Appearance.m3colors.m3surfaceContainerHigh
                    radius: Appearance.rounding.normal

                    // Square off the bottom corners
                    Rectangle {
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.bottom: parent.bottom
                        height: parent.radius
                        color: parent.color
                    }

                    RowLayout {
                        id: headerRow
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.leftMargin: 16
                        anchors.rightMargin: 8
                        spacing: 10

                        MaterialSymbol {
                            text: "work"
                            iconSize: Appearance.font.pixelSize.larger
                            color: Appearance.colors.colPrimary
                        }
                        StyledText {
                            Layout.fillWidth: true
                            text: "Work Todo"
                            font.pixelSize: Appearance.font.pixelSize.large
                            font.weight: Font.Medium
                            color: Appearance.m3colors.m3onSurface
                        }
                    }
                }

                // Tab bar + content
                Item {
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    property bool showAddDialog: false

                    id: contentArea

                    Keys.onPressed: (event) => {
                        if (event.key === Qt.Key_N) {
                            contentArea.showAddDialog = true
                            event.accepted = true
                        } else if (event.key === Qt.Key_Escape && contentArea.showAddDialog) {
                            contentArea.showAddDialog = false
                            event.accepted = true
                        }
                    }

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.topMargin: 4
                        spacing: 0

                        SecondaryTabBar {
                            id: tabBar
                            currentIndex: swipeView.currentIndex

                            SecondaryTabButton {
                                buttonText: "Unfinished"
                                buttonIcon: "checklist"
                            }
                            SecondaryTabButton {
                                buttonText: "Done"
                                buttonIcon: "check_circle"
                            }
                        }

                        SwipeView {
                            id: swipeView
                            Layout.topMargin: 10
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            Layout.leftMargin: 8
                            Layout.rightMargin: 8
                            spacing: 10
                            clip: true
                            currentIndex: tabBar.currentIndex

                            WorkTodoTaskList {
                                listBottomPadding: root.fabSize + root.fabMargins * 2
                                emptyPlaceholderIcon: "check_circle"
                                emptyPlaceholderText: "Nothing here!"
                                taskList: WorkTodo.list
                                    .map(function(item, i) { return Object.assign({}, item, {originalIndex: i}) })
                                    .filter(function(item) { return !item.done })
                            }
                            WorkTodoTaskList {
                                listBottomPadding: root.fabSize + root.fabMargins * 2
                                emptyPlaceholderIcon: "checklist"
                                emptyPlaceholderText: "Finished tasks will go here"
                                taskList: WorkTodo.list
                                    .map(function(item, i) { return Object.assign({}, item, {originalIndex: i}) })
                                    .filter(function(item) { return item.done })
                            }
                        }
                    }

                    // FAB
                    StyledRectangularShadow {
                        target: fabButton
                        radius: fabButton.buttonRadius
                        blur: 0.6 * Appearance.sizes.elevationMargin
                    }
                    FloatingActionButton {
                        id: fabButton
                        anchors.right: parent.right
                        anchors.bottom: parent.bottom
                        anchors.rightMargin: root.fabMargins
                        anchors.bottomMargin: root.fabMargins
                        onClicked: contentArea.showAddDialog = true
                        iconText: "add"
                    }

                    // Add task dialog
                    Item {
                        anchors.fill: parent
                        z: 9999

                        visible: opacity > 0
                        opacity: contentArea.showAddDialog ? 1 : 0
                        Behavior on opacity {
                            NumberAnimation {
                                duration: Appearance.animation.elementMoveFast.duration
                                easing.type: Appearance.animation.elementMoveFast.type
                                easing.bezierCurve: Appearance.animation.elementMoveFast.bezierCurve
                            }
                        }

                        onVisibleChanged: {
                            if (!visible) {
                                todoInput.text = ""
                                fabButton.focus = true
                            }
                        }

                        Rectangle {
                            anchors.fill: parent
                            radius: Appearance.rounding.small
                            color: Appearance.colors.colScrim
                            MouseArea {
                                hoverEnabled: true
                                anchors.fill: parent
                                preventStealing: true
                                propagateComposedEvents: false
                            }
                        }

                        Rectangle {
                            id: dialog
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.margins: root.dialogMargins
                            implicitHeight: dialogColumnLayout.implicitHeight
                            color: Appearance.m3colors.m3surfaceContainerHigh
                            radius: Appearance.rounding.normal

                            function addTask() {
                                if (todoInput.text.length > 0) {
                                    WorkTodo.addTask(todoInput.text)
                                    todoInput.text = ""
                                    contentArea.showAddDialog = false
                                    tabBar.setCurrentIndex(0)
                                }
                            }

                            ColumnLayout {
                                id: dialogColumnLayout
                                anchors.fill: parent
                                spacing: 16

                                StyledText {
                                    Layout.topMargin: 16
                                    Layout.leftMargin: 16
                                    Layout.rightMargin: 16
                                    Layout.alignment: Qt.AlignLeft
                                    color: Appearance.m3colors.m3onSurface
                                    font.pixelSize: Appearance.font.pixelSize.larger
                                    text: "Add work task"
                                }

                                TextField {
                                    id: todoInput
                                    Layout.fillWidth: true
                                    Layout.leftMargin: 16
                                    Layout.rightMargin: 16
                                    padding: 10
                                    color: activeFocus ? Appearance.m3colors.m3onSurface : Appearance.m3colors.m3onSurfaceVariant
                                    renderType: Text.NativeRendering
                                    selectedTextColor: Appearance.m3colors.m3onSecondaryContainer
                                    selectionColor: Appearance.colors.colSecondaryContainer
                                    placeholderText: "Task description"
                                    placeholderTextColor: Appearance.m3colors.m3outline
                                    focus: contentArea.showAddDialog
                                    onAccepted: dialog.addTask()

                                    background: Rectangle {
                                        anchors.fill: parent
                                        radius: Appearance.rounding.verysmall
                                        border.width: 2
                                        border.color: todoInput.activeFocus ? Appearance.colors.colPrimary : Appearance.m3colors.m3outline
                                        color: "transparent"
                                    }

                                    cursorDelegate: Rectangle {
                                        width: 1
                                        color: todoInput.activeFocus ? Appearance.colors.colPrimary : "transparent"
                                        radius: 1
                                    }
                                }

                                RowLayout {
                                    Layout.bottomMargin: 16
                                    Layout.leftMargin: 16
                                    Layout.rightMargin: 16
                                    Layout.alignment: Qt.AlignRight
                                    spacing: 5

                                    DialogButton {
                                        buttonText: "Cancel"
                                        onClicked: contentArea.showAddDialog = false
                                    }
                                    DialogButton {
                                        buttonText: "Add"
                                        enabled: todoInput.text.length > 0
                                        onClicked: dialog.addTask()
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    GlobalShortcut {
        name: "workTodoToggle"
        description: "Toggle work todo window and desktop todo widget"
        onPressed: {
            GlobalStates.workTodoOpen = !GlobalStates.workTodoOpen
            GlobalStates.desktopTodoVisible = !GlobalStates.desktopTodoVisible
        }
    }

    IpcHandler {
        target: "workTodo"
        function toggle(): void {
            GlobalStates.workTodoOpen = !GlobalStates.workTodoOpen
            GlobalStates.desktopTodoVisible = !GlobalStates.desktopTodoVisible
        }
        function open(): void {
            GlobalStates.workTodoOpen = true
            GlobalStates.desktopTodoVisible = true
        }
        function close(): void {
            GlobalStates.workTodoOpen = false
            GlobalStates.desktopTodoVisible = false
        }
    }
}
