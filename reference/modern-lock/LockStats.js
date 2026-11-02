.pragma library
function cpuSnapshot(text) {
    var line = String(text).split("\n")[0].trim().split(/\s+/)
    if (line[0] !== "cpu" || line.length < 5) return null
    var values = line.slice(1, 9).map(Number)
    if (values.some(function(n) {return !isFinite(n) || n < 0})) return null
    return {total: values.reduce(function(a,b) {return a+b},0), idle: values[3] + (values[4] || 0)}
}
function cpuUsage(previous, current) {
    if (!previous || !current) return null
    var total = current.total - previous.total, idle = current.idle - previous.idle
    if (total <= 0 || idle < 0 || idle > total) return null
    return Math.max(0, Math.min(100, Math.round(100 * (1 - idle / total))))
}
function memoryUsage(text) {
    var total = null, available = null
    String(text).split("\n").forEach(function(line) {
        var match = /^(MemTotal|MemAvailable):\s+(\d+)\s+kB$/.exec(line.trim())
        if (match) {if (match[1] === "MemTotal") total = Number(match[2]); else available = Number(match[2])}
    })
    if (total === null || available === null || total <= 0 || available > total) return null
    return Math.max(0, Math.min(100, Math.round(100 * (1 - available / total))))
}
function percent(value) {return value === null || value === undefined || !isFinite(Number(value)) ? "—" : Math.round(Number(value)) + "%"}
