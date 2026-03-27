import QtQuick
import Quickshell
import Quickshell.Io
import qs.modules.common.functions

pragma Singleton
pragma ComponentBehavior: Bound

Singleton {
    id: gpu

    property bool hardwareAccelEnabled: true
    property string currentRenderer: "GPU"
    readonly property string stateFile: `${Directories.config}/gpu-state`

    function load() {
        loadState()
    }

    function loadState(): void {
        const stateData = FileUtils.readFile(stateFile)
        if (stateData.length > 0) {
            hardwareAccelEnabled = stateData.trim() === "gpu"
            currentRenderer = hardwareAccelEnabled ? "GPU" : "CPU"
        } else {
            hardwareAccelEnabled = true
            currentRenderer = "GPU"
            saveState()
        }
    }

    function saveState(): void {
        FileUtils.writeFile(stateFile, hardwareAccelEnabled ? "gpu" : "cpu")
    }

    function toggleHardwareAccel(): void {
        hardwareAccelEnabled = !hardwareAccelEnabled
        applySettings()
    }

    function applySettings(): void {
        currentRenderer = hardwareAccelEnabled ? "GPU" : "CPU"
        saveState()
        notifySettings()
    }

    function notifySettings(): void {
        const message = hardwareAccelEnabled 
            ? "GPU Hardware Acceleration: ENABLED\n(Restart applications to apply)"
            : "Hardware Acceleration: DISABLED\n(Restart applications to apply)"
        
        Notifications.notify({
            summary: "GPU Mode",
            body: message,
            iconName: hardwareAccelEnabled ? "gpu" : "computer",
            timeout: 3000
        })
    }
}
