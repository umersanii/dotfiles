import QtQuick
import Quickshell
import Quickshell.Io

pragma Singleton
pragma ComponentBehavior: Bound

Singleton {
    id: whatsapp

    property bool isRunning: false

    Process {
        id: launchProcess
        running: false
        command: ["/opt/WhatsApp Desktop/whatsapp-linux-desktop"]
        
        onStarted: {
            whatsapp.isRunning = true
        }
        
        onExited: {
            whatsapp.isRunning = false
        }
    }

    function launchWhatsApp(): void {
        if (!isRunning) {
            launchProcess.running = true
        }
    }

    function closeWhatsApp(): void {
        Quickshell.run(["pkill", "-f", "whatsapp-linux-desktop"], {})
        launchProcess.running = false
        isRunning = false
    }

    function toggleWhatsApp(): void {
        if (isRunning) closeWhatsApp()
        else launchWhatsApp()
    }
}
