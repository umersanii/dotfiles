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
    backgroundHeight: 600

    readonly property var countryNames: ({
        "NL": "Netherlands", "US": "United States", "JP": "Japan", "SG": "Singapore",
        "CA": "Canada", "RO": "Romania", "MX": "Mexico", "CH": "Switzerland",
        "PL": "Poland", "NO": "Norway"
    })

    ProtonVpnToggle {
        id: pvModel
    }

    WindowDialogTitle {
        text: Translation.tr("Proton VPN")
    }
    WindowDialogSeparator {}

    WindowDialogParagraph {
        text: pvModel.busy
            ? pvModel.statusText
            : pvModel.toggled
                ? Translation.tr("Connected to %1").arg(pvModel.server)
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
        enabled: !pvModel.busy

        header: ProtonVpnCountryItem {
            width: ListView.view.width
            symbol: "bolt"
            title: Translation.tr("Fastest server")
            subtitle: Translation.tr("Lowest-load free server anywhere")
            onConnectRequested: pvModel.connectTo("")
        }

        model: ScriptModel {
            values: pvModel.freeCountries
        }
        delegate: ProtonVpnCountryItem {
            required property var modelData
            width: ListView.view.width
            title: root.countryNames[modelData.code] ?? modelData.code
            subtitle: modelData.cities + " · " + Translation.tr("%1 servers").arg(modelData.count)
            current: pvModel.toggled && pvModel.currentCountry === modelData.code
            onConnectRequested: pvModel.connectTo(modelData.code)
        }
    }

    WindowDialogSeparator {}
    WindowDialogButtonRow {
        DialogButton {
            buttonText: pvModel.toggled ? Translation.tr("Disconnect") : Translation.tr("Connect")
            enabled: !pvModel.busy
            onClicked: pvModel.mainAction()
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
