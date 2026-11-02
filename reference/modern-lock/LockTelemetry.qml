// Read-only lock-view telemetry. No shell command, network call, service or privileged probe.
import QtQuick
import Quickshell.Io
import Quickshell.Services.UPower
import "LockStats.js" as Stats
Item {
    id: root
    property var cpuPercent: null
    property var memoryPercent: null
    property var previousCpu: null
    property int cpuSamples: 0
    property int memorySamples: 0
    property int pollCount: 0
    readonly property var batteryPercent: UPower.displayDevice && UPower.displayDevice.isPresent && isFinite(UPower.displayDevice.percentage)
        ? Math.round(100 * UPower.displayDevice.percentage) : null
    readonly property string batteryLabel: UPower.displayDevice && UPower.displayDevice.isPresent
        ? (UPower.onBattery ? "Battery" : "Plugged in") : "AC power"
    readonly property string summary: "CPU " + Stats.percent(cpuPercent) + "   ·   RAM " + Stats.percent(memoryPercent)
        + "   ·   " + batteryLabel + (batteryPercent === null ? "" : " " + Stats.percent(batteryPercent))
    FileView {
        id: cpu
        path: "/proc/stat"; watchChanges: false; printErrors: false
        onLoaded: {
            root.cpuSamples++
            var current = Stats.cpuSnapshot(text())
            root.cpuPercent = Stats.cpuUsage(root.previousCpu, current)
            root.previousCpu = current
        }
        onLoadFailed: { root.cpuPercent = null; root.previousCpu = null }
    }
    FileView {
        id: memory
        path: "/proc/meminfo"; watchChanges: false; printErrors: false
        onLoaded: {root.memorySamples++; root.memoryPercent = Stats.memoryUsage(text())}
        onLoadFailed: root.memoryPercent = null
    }
    Timer {
        // Visible-only one-second sampling keeps the status line responsive without a subprocess.
        interval: 1000
        running: root.visible && root.enabled; repeat: true
        onTriggered: {root.pollCount++; cpu.reload(); memory.reload()}
    }
}
