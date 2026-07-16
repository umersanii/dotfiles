import qs.services
import qs.modules.common
import qs.modules.common.widgets
import QtQuick

QuickToggleButton {
    toggled: Network.hotspotEnabled
    buttonIcon: "wifi_tethering"
    onClicked: Network.toggleHotspot()
    StyledToolTip {
        text: Translation.tr("Hotspot")
    }
}
