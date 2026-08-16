import qs.modules.common
import qs.modules.common.widgets
import qs.services
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

StyledPopup {
    id: root
    property string formattedDate: Qt.locale().toString(DateTime.clock.date, "dddd, MMMM dd, yyyy")
    property string formattedTime: DateTime.time
    property string formattedUptime: DateTime.uptime
    property string todosSection: getUpcomingTodos()
    property var timerUnits: []
    property string timersSection: getTimersSection()

    function formatCountdown(nextUs) {
        if (!nextUs)
            return "-";
        const diffSeconds = Math.round(nextUs / 1000000 - Date.now() / 1000);
        if (diffSeconds <= 0)
            return "due";

        const days = Math.floor(diffSeconds / 86400);
        const hours = Math.floor((diffSeconds % 86400) / 3600);
        const minutes = Math.floor((diffSeconds % 3600) / 60);

        if (days > 0)
            return `${days}d ${hours}h`;
        if (hours > 0)
            return `${hours}h ${minutes}m`;
        if (minutes > 0)
            return `${minutes}m`;
        return "<1m";
    }

    function getTimersSection() {
        if (root.timerUnits.length === 0)
            return Translation.tr("No user timers");

        return root.timerUnits.map(function (t, index) {
            return `  ${index + 1}. ${t.unit} — ${root.formatCountdown(t.next)}`;
        }).join('\n');
    }

    function getUpcomingTodos() {
        const unfinishedTodos = Todo.list.filter(function (item) {
            return !item.done;
        });
        if (unfinishedTodos.length === 0) {
            return Translation.tr("No pending tasks");
        }

        // Limit to first 5 todos to keep popup manageable
        const limitedTodos = unfinishedTodos.slice(0, 5);
        let todoText = limitedTodos.map(function (item, index) {
            return `  ${index + 1}. ${item.content}`;
        }).join('\n');

        if (unfinishedTodos.length > 5) {
            todoText += `\n  ${Translation.tr("... and %1 more").arg(unfinishedTodos.length - 5)}`;
        }

        return todoText;
    }

    ColumnLayout {
        id: columnLayout
        anchors.centerIn: parent
        spacing: 4

        Process {
            id: listTimersProc
            command: ["systemctl", "--user", "list-timers", "--no-legend", "--all", "-o", "json"]
            running: true
            stdout: StdioCollector {
                onStreamFinished: {
                    try {
                        root.timerUnits = JSON.parse(text);
                    } catch (e) {
                        root.timerUnits = [];
                    }
                }
            }
        }

        StyledPopupHeaderRow {
            icon: "calendar_month"
            label: root.formattedDate
        }

        StyledPopupValueRow {
            icon: "timelapse"
            label: Translation.tr("System uptime:")
            value: root.formattedUptime
        }

        // Tasks
        Column {
            spacing: 0
            Layout.fillWidth: true

            StyledPopupValueRow {
                icon: "checklist"
                label: Translation.tr("To Do:")
                value: ""
            }

            StyledText {
                horizontalAlignment: Text.AlignLeft
                wrapMode: Text.Wrap
                color: Appearance.colors.colOnSurfaceVariant
                text: root.todosSection
            }
        }

        // Systemd user timers
        Column {
            spacing: 0
            Layout.fillWidth: true

            StyledPopupValueRow {
                icon: "schedule"
                label: Translation.tr("Timers:")
                value: ""
            }

            StyledText {
                horizontalAlignment: Text.AlignLeft
                wrapMode: Text.Wrap
                color: Appearance.colors.colOnSurfaceVariant
                text: root.timersSection
            }
        }
    }
}
