import QtQuick
import Quickshell
import Quickshell.Bluetooth
import qs.services
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets

QuickToggleModel {
    name: Translation.tr("Bluetooth")
    statusText: BluetoothStatus.firstActiveDevice?.name ?? Translation.tr("Not connected")
    tooltipText: Translation.tr("%1 | Right-click to configure").arg(
        (BluetoothStatus.firstActiveDevice?.name ?? Translation.tr("Bluetooth"))
        + (BluetoothStatus.activeDeviceCount > 1 ? ` +${BluetoothStatus.activeDeviceCount - 1}` : "")
    )
    icon: BluetoothStatus.connected ? "bluetooth_connected" : BluetoothStatus.enabled ? "bluetooth" : "bluetooth_disabled"

    available: BluetoothStatus.available
    toggled: BluetoothStatus.enabled
    mainAction: () => {
        if (!Bluetooth.defaultAdapter) {
            Quickshell.execDetached(["bash", "-c", `${Config.options.apps.bluetooth}`]);
            return;
        }
        if (!Bluetooth.defaultAdapter.enabled) {
            Quickshell.execDetached(["bash", "-c", "rfkill unblock bluetooth && bluetoothctl power on"]);
        } else {
            Bluetooth.defaultAdapter.enabled = false;
        }
    }
    hasMenu: true
}
