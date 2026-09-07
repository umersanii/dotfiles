import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.models.quickToggles
import QtQuick
import QtQuick.Layouts
import Quickshell

WindowDialog {
    id: root
    backgroundHeight: 420

    TailscaleToggle {
        id: tsModel
    }

    WindowDialogTitle {
        text: Translation.tr("Tailscale VPN")
    }
    WindowDialogSeparator {}

    WindowDialogParagraph {
        text: !tsModel.available
            ? Translation.tr("Tailscale status unavailable.")
            : tsModel.toggled
                ? Translation.tr("Connected as %1").arg(
                    (tsModel.currentIndex >= 0 && tsModel.currentIndex < tsModel.accountList.length)
                        ? tsModel.accountList[tsModel.currentIndex].account
                        : Translation.tr("current account"))
                : Translation.tr("Disconnected")
    }

    ListView {
        Layout.fillHeight: true
        Layout.fillWidth: true
        Layout.topMargin: -15
        Layout.bottomMargin: -16
        Layout.leftMargin: -Appearance.rounding.large
        Layout.rightMargin: -Appearance.rounding.large

        clip: true
        spacing: 0

        model: ScriptModel {
            values: tsModel.accountList
        }
        delegate: TailscaleAccountItem {
            required property var modelData
            required property int index
            account: modelData
            current: index === tsModel.currentIndex
            width: ListView.view.width
            onSwitchRequested: tsModel.switchToAccount(modelData.id)
        }
    }

    WindowDialogSeparator {}
    WindowDialogButtonRow {
        DialogButton {
            buttonText: tsModel.toggled ? Translation.tr("Disconnect") : Translation.tr("Connect")
            onClicked: tsModel.mainAction()
        }

        Item {
            Layout.fillWidth: true
        }

        DialogButton {
            buttonText: Translation.tr("Admin console")
            onClicked: {
                Quickshell.execDetached(["xdg-open", "https://login.tailscale.com/admin/machines"]);
                GlobalStates.sidebarRightOpen = false;
            }
        }

        DialogButton {
            buttonText: Translation.tr("Done")
            onClicked: root.dismiss()
        }
    }
}
