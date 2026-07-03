import qs.modules.common
import qs.modules.common.widgets
import qs.services
import QtQuick
import QtQuick.Layouts
import Quickshell

StyledPopup {
    id: root

    function formatPercent(v) {
        return Math.round(v * 100) + "%"
    }

    Row {
        anchors.centerIn: parent
        spacing: 12

        Column {
            anchors.top: parent.top
            spacing: 8

            StyledPopupHeaderRow {
                icon: ""
                iconSource: Quickshell.shellPath("assets/icons/claude-symbolic.svg")
                label: "Claude 5h"
            }
            Column {
                spacing: 4
                StyledPopupValueRow {
                    icon: "clock_loader_60"
                    label: Translation.tr("Used:")
                    value: root.formatPercent(ClaudeUsage.fiveHourUsedPercentage)
                    valueColor: ClaudeUsage.fiveHourUsedPercentage >= 0.85 ? Appearance.colors.colError : (ClaudeUsage.fiveHourUsedPercentage >= 0.70 ? "#FBBC04" : Appearance.colors.colOnSurfaceVariant)
                }
                StyledPopupValueRow {
                    icon: "timer"
                    label: Translation.tr("Resets at:")
                    value: ClaudeUsage.formatResetAt(ClaudeUsage.fiveHourResetsAt)
                }
            }
        }

        Column {
            anchors.top: parent.top
            spacing: 8

            StyledPopupHeaderRow {
                icon: ""
                iconSource: Quickshell.shellPath("assets/icons/claude-symbolic.svg")
                label: "Claude 7d"
            }
            Column {
                spacing: 4
                StyledPopupValueRow {
                    icon: "clock_loader_60"
                    label: Translation.tr("Used:")
                    value: root.formatPercent(ClaudeUsage.sevenDayUsedPercentage)
                    valueColor: ClaudeUsage.sevenDayUsedPercentage >= 0.85 ? Appearance.colors.colError : (ClaudeUsage.sevenDayUsedPercentage >= 0.70 ? "#FBBC04" : Appearance.colors.colOnSurfaceVariant)
                }
                StyledPopupValueRow {
                    icon: "timer"
                    label: Translation.tr("Resets at:")
                    value: ClaudeUsage.formatResetAt(ClaudeUsage.sevenDayResetsAt)
                }
                StyledPopupValueRow {
                    icon: "event"
                    label: Translation.tr("Reset date:")
                    readonly property string _resetDate: ClaudeUsage.formatResetDate(ClaudeUsage.sevenDayResetsAt)
                    value: _resetDate
                    visible: _resetDate !== ""
                }
            }
        }

        Column {
            anchors.top: parent.top
            spacing: 8

            StyledPopupHeaderRow {
                icon: ""
                iconSource: Quickshell.shellPath("assets/icons/copilot-symbolic.svg")
                label: "Copilot"
            }
            Column {
                spacing: 4
                StyledPopupValueRow {
                    icon: "clock_loader_60"
                    label: Translation.tr("Used:")
                    value: root.formatPercent(CopilotUsage.premiumUsedPercentage)
                    valueColor: CopilotUsage.premiumUsedPercentage >= 0.85 ? Appearance.colors.colError : (CopilotUsage.premiumUsedPercentage >= 0.70 ? "#FBBC04" : Appearance.colors.colOnSurfaceVariant)
                }
                StyledPopupValueRow {
                    icon: "check_circle"
                    label: Translation.tr("Remaining:")
                    value: CopilotUsage.premiumRemaining + " / " + CopilotUsage.premiumEntitlement
                }
                StyledPopupValueRow {
                    icon: "event"
                    label: Translation.tr("Resets:")
                    value: CopilotUsage.resetDate !== "" ? CopilotUsage.resetDate : "—"
                }
            }
        }
    }
}
