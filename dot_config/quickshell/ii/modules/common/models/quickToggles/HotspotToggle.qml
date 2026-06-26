import QtQuick
import qs.services
import qs.modules.common
import qs.modules.common.widgets

QuickToggleModel {
    name: Translation.tr("Hotspot")
    statusText: Network.hotspotEnabled ? Translation.tr("On") : Translation.tr("Off")
    tooltipText: Translation.tr("Wi-Fi Hotspot | Right-click to configure")
    icon: "wifi_tethering"
    toggled: Network.hotspotEnabled
    mainAction: () => Network.toggleHotspot()
    hasMenu: true
}
