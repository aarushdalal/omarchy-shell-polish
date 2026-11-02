from pathlib import Path
import tempfile,shutil,subprocess,os,json,sys
source=Path(__file__).resolve().parents[1]/'reference/modern-lock';evidence=Path(sys.argv[1] if len(sys.argv)>1 else '/tmp/lock-stats-evidence');evidence.mkdir(parents=True,exist_ok=True)
with tempfile.TemporaryDirectory(prefix='lock-stats-test-') as name:
 p=Path(name)
 for file in ['LockTelemetry.qml','LockStats.js']:shutil.copy2(source/file,p/file)
 (p/'shell.qml').write_text('''import QtQuick
import Quickshell
import "LockStats.js" as Stats
ShellRoot {
 LockTelemetry {id:stats}
 Timer {interval:5500;running:true;onTriggered:{
  var tests=[Stats.cpuSnapshot("garbage")===null,Stats.cpuUsage(null,{total:1,idle:0})===null,
   Stats.cpuUsage({total:10,idle:5},{total:20,idle:15})===0,
   Stats.cpuUsage({total:10,idle:5},{total:20,idle:5})===100,
   Stats.cpuUsage({total:20,idle:5},{total:10,idle:5})===null,
   Stats.memoryUsage("MemTotal: 100 kB\\nMemAvailable: 100 kB")===0,
   Stats.memoryUsage("MemTotal: 100 kB\\nMemAvailable: 0 kB")===100,
   Stats.memoryUsage("MemTotal: 100 kB")===null,
   Stats.memoryUsage("MemTotal: 100 kB\\nMemAvailable: 101 kB")===null,
   Stats.percent(0)==="0%",Stats.percent(null)==="—",
   stats.cpuPercent!==null && stats.cpuPercent>=0 && stats.cpuPercent<=100,
   stats.memoryPercent!==null && stats.memoryPercent>=0 && stats.memoryPercent<=100,
   stats.pollCount>=4,stats.cpuSamples>=5,stats.memorySamples>=5]
  if(tests.some(function(ok){return !ok}))console.error("STATS-FAIL",JSON.stringify(tests))
  else console.log("STATS-PASS",JSON.stringify({checks:tests.length,cpu:stats.cpuPercent,ram:stats.memoryPercent,battery:stats.batteryPercent,summary:stats.summary}))
  stats.enabled=false;hold.count=stats.pollCount;hold.start()
 }}
 Timer {id:hold;property int count:0;interval:1200;onTriggered:{if(count!==stats.pollCount)console.error("STATS-FAIL hidden poll");else console.log("PAUSE-PASS");Qt.quit()}}
}''')
 r=subprocess.run(['quickshell','--no-color','--path',str(p)],capture_output=True,text=True,timeout=10)
 log=r.stdout+r.stderr;(evidence/'collector.log').write_text(log)
 assert r.returncode==0 and 'STATS-PASS' in log and 'ERROR' not in log and 'STATS-FAIL' not in log and 'PAUSE-PASS' in log,log
 print(log)
