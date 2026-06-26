import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import QtQuick.Layouts
import Quickshell

WindowDialog {
    id: root

    WindowDialogTitle {
        text: Translation.tr("Wi-Fi Hotspot")
    }
    WindowDialogSeparator {}

    WindowDialogParagraph {
        text: Network.hotspotEnabled
            ? Translation.tr("Hotspot is currently active.")
            : Translation.tr("Hotspot is currently inactive.")
    }

    WindowDialogButtonRow {
        DialogButton {
            buttonText: Translation.tr("Configure")
            onClicked: {
                Quickshell.execDetached(["bash", "-c", Config.options.apps.network]);
                GlobalStates.sidebarRightOpen = false;
            }
        }

        Item {
            Layout.fillWidth: true
        }

        DialogButton {
            buttonText: Translation.tr("Done")
            onClicked: root.dismiss()
        }
    }
}
