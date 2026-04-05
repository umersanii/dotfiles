pragma Singleton
pragma ComponentBehavior: Bound

import qs.modules.common
import QtQuick
import Quickshell
import Quickshell.Io

/**
 * Simple polled resource usage service with RAM, Swap, CPU, and Network usage.
 */
Singleton {
    id: root
	property real memoryTotal: 1
	property real memoryFree: 0
	property real memoryUsed: memoryTotal - memoryFree
    property real memoryUsedPercentage: memoryUsed / memoryTotal
    property real swapTotal: 1
	property real swapFree: 0
	property real swapUsed: swapTotal - swapFree
    property real swapUsedPercentage: swapTotal > 0 ? (swapUsed / swapTotal) : 0
    property real cpuUsage: 0
    property var previousCpuStats
    property real gpuUsage: 0
    
    // Network properties
    property real networkDownloadSpeed: 0  // KB/s
    property real networkUploadSpeed: 0    // KB/s
    property var previousNetworkStats

    property string maxAvailableMemoryString: kbToGbString(ResourceUsage.memoryTotal)
    property string maxAvailableSwapString: kbToGbString(ResourceUsage.swapTotal)
    property string maxAvailableCpuString: "--"

    readonly property int historyLength: Config?.options.resources.historyLength ?? 60
    property list<real> cpuUsageHistory: []
    property list<real> memoryUsageHistory: []
    property list<real> swapUsageHistory: []
    property list<real> networkDownloadSpeedHistory: []
    property list<real> networkUploadSpeedHistory: []
    property list<real> gpuUsageHistory: []

    function kbToGbString(kb) {
        return (kb / (1024 * 1024)).toFixed(1) + " GB";
    }

    function updateMemoryUsageHistory() {
        memoryUsageHistory = [...memoryUsageHistory, memoryUsedPercentage]
        if (memoryUsageHistory.length > historyLength) {
            memoryUsageHistory.shift()
        }
    }
    function updateSwapUsageHistory() {
        swapUsageHistory = [...swapUsageHistory, swapUsedPercentage]
        if (swapUsageHistory.length > historyLength) {
            swapUsageHistory.shift()
        }
    }
    function updateCpuUsageHistory() {
        cpuUsageHistory = [...cpuUsageHistory, cpuUsage]
        if (cpuUsageHistory.length > historyLength) {
            cpuUsageHistory.shift()
        }
    }
    function updateNetworkDownloadSpeedHistory() {
        networkDownloadSpeedHistory = [...networkDownloadSpeedHistory, networkDownloadSpeed]
        if (networkDownloadSpeedHistory.length > historyLength) {
            networkDownloadSpeedHistory.shift()
        }
    }
    function updateNetworkUploadSpeedHistory() {
        networkUploadSpeedHistory = [...networkUploadSpeedHistory, networkUploadSpeed]
        if (networkUploadSpeedHistory.length > historyLength) {
            networkUploadSpeedHistory.shift()
        }
    }
    function updateGpuUsageHistory() {
        gpuUsageHistory = [...gpuUsageHistory, gpuUsage]
        if (gpuUsageHistory.length > historyLength) {
            gpuUsageHistory.shift()
        }
    }
    function updateHistories() {
        updateMemoryUsageHistory()
        updateSwapUsageHistory()
        updateCpuUsageHistory()
        updateNetworkDownloadSpeedHistory()
        updateNetworkUploadSpeedHistory()
        updateGpuUsageHistory()
    }

	Timer {
		interval: 1
        running: true 
        repeat: true
		onTriggered: {
            // Reload files
            fileMeminfo.reload()
            fileStat.reload()
            fileNetDev.reload()

            // Parse memory and swap usage
            const textMeminfo = fileMeminfo.text()
            memoryTotal = Number(textMeminfo.match(/MemTotal: *(\d+)/)?.[1] ?? 1)
            memoryFree = Number(textMeminfo.match(/MemAvailable: *(\d+)/)?.[1] ?? 0)
            swapTotal = Number(textMeminfo.match(/SwapTotal: *(\d+)/)?.[1] ?? 1)
            swapFree = Number(textMeminfo.match(/SwapFree: *(\d+)/)?.[1] ?? 0)

            // Parse CPU usage
            const textStat = fileStat.text()
            const cpuLine = textStat.match(/^cpu\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)/)
            if (cpuLine) {
                const stats = cpuLine.slice(1).map(Number)
                const total = stats.reduce((a, b) => a + b, 0)
                const idle = stats[3]

                if (previousCpuStats) {
                    const totalDiff = total - previousCpuStats.total
                    const idleDiff = idle - previousCpuStats.idle
                    cpuUsage = totalDiff > 0 ? (1 - idleDiff / totalDiff) : 0
                }

                previousCpuStats = { total, idle }
            }

            // Parse network usage from /proc/net/dev
            const textNetDev = fileNetDev.text()
            let totalRxBytes = 0
            let totalTxBytes = 0
            const lines = textNetDev.split('\n')
            
            for (const line of lines) {
                // Skip header and loopback
                if (line.includes('face') || line.includes('lo:') || line.trim() === '') continue
                
                const parts = line.trim().split(/\s+/)
                if (parts.length >= 10) {
                    // Remove trailing colon from interface name if present
                    const ifaceName = parts[0].replace(':', '')
                    // Skip loopback, virtual and docker interfaces
                    if (!ifaceName.includes('lo') && !ifaceName.includes('docker') && !ifaceName.includes('veth')) {
                        totalRxBytes += Number(parts[1]) || 0
                        totalTxBytes += Number(parts[9]) || 0
                    }
                }
            }

            if (previousNetworkStats) {
                const updateIntervalSeconds = (Config.options?.resources?.updateInterval ?? 3000) / 1000
                const rxDiff = totalRxBytes - previousNetworkStats.rx
                const txDiff = totalTxBytes - previousNetworkStats.tx
                
                networkDownloadSpeed = Math.max(0, rxDiff / updateIntervalSeconds / 1024)
                networkUploadSpeed = Math.max(0, txDiff / updateIntervalSeconds / 1024)
            }

            previousNetworkStats = { rx: totalRxBytes, tx: totalTxBytes }

            root.updateHistories()
            interval = Config.options?.resources?.updateInterval ?? 3000
        }
	}

	FileView { id: fileMeminfo; path: "/proc/meminfo" }
    FileView { id: fileStat; path: "/proc/stat" }
    FileView { id: fileNetDev; path: "/proc/net/dev" }

    // GPU usage polling — tries nvidia-smi first, falls back to AMD sysfs
    Timer {
        id: gpuPollTimer
        interval: Config.options?.resources?.updateInterval ?? 3000
        running: true
        repeat: true
        onTriggered: gpuProc.running = true
    }

    Process {
        id: gpuProc
        running: true
        command: ["bash", "-c",
            "nvidia-smi --query-gpu=utilization.gpu --format=csv,noheader,nounits 2>/dev/null | head -1 || " +
            "cat /sys/class/drm/card0/device/gpu_busy_percent 2>/dev/null || " +
            "cat /sys/class/drm/card1/device/gpu_busy_percent 2>/dev/null || echo 0"]
        stdout: StdioCollector {
            id: gpuOutput
            onStreamFinished: {
                const val = parseInt(gpuOutput.text.trim(), 10)
                root.gpuUsage = isNaN(val) ? 0 : Math.min(100, Math.max(0, val)) / 100.0
            }
        }
    }

    Process {
        id: findCpuMaxFreqProc
        environment: ({
            LANG: "C",
            LC_ALL: "C"
        })
        command: ["bash", "-c", "lscpu | grep 'CPU max MHz' | awk '{print $4}'"]
        running: true
        stdout: StdioCollector {
            id: outputCollector
            onStreamFinished: {
                root.maxAvailableCpuString = (parseFloat(outputCollector.text) / 1000).toFixed(0) + " GHz"
            }
        }
    }
}
