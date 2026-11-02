"""Test only the visual lock view with inert signals; never invokes PAM or locks a session."""
from pathlib import Path
import os, shutil, subprocess, tempfile, unittest

ROOT=Path(__file__).resolve().parents[1]
SOURCE=ROOT/'reference/modern-lock/LockView.qml'
RUNNER='/usr/lib/qt6/bin/qmltestrunner'

@unittest.skipUnless(Path(RUNNER).is_file(), 'Qt Quick Test is required')
class MinimalLockView(unittest.TestCase):
    def test_masked_input_focus_busy_feedback_and_reduced_motion(self):
        with tempfile.TemporaryDirectory(prefix='minimal-lock-view-') as name:
            folder=Path(name);shutil.copy2(SOURCE,folder/'LockView.qml')
            commons=folder/'qs/Commons';commons.mkdir(parents=True)
            (commons/'qmldir').write_text('module qs.Commons\nsingleton Color 1.0 Color.qml\n')
            (commons/'Color.qml').write_text('''pragma Singleton
import QtQuick
QtObject {property color background:"#0b0c0f";property color foreground:"#dddddf";property var lock:({text:"#dddddf",placeholder:"#99999e",selection:"#606069",border:"#3a3a40",borderActive:"#b4b4bf",borderError:"#b77c7c",textError:"#d7a7a7"})}''')
            qml='''import QtQuick
import QtTest
Item {
 id:host;width:1200;height:760
 property var current:null
 Component {id:factory;LockView {id:view;anchors.fill:parent;loadBackground:false;loadSystemStats:false;statsOverride:"CPU 7%   ·   RAM 42%   ·   Battery 80%";onPasswordTextEdited:function(value){view.passwordText=value}}}
 SignalSpy {id:submit;target:host.current;signalName:"submitPassword"}
 TestCase {
  name:"MinimalLockView";when:windowShown
  function test_visual_input_contract() {
   var view=createTemporaryObject(factory,host);verify(view!==null);host.current=view
   var field=findChild(view,"passwordField");verify(field!==null)
   var stats=findChild(view,"lock-system-stats");verify(stats!==null);verify(stats.text.indexOf("RAM 42%")>=0);verify(findChild(view,"lock-date").text.length>0)
   tryVerify(function(){return field.activeFocus});compare(field.echoMode,TextInput.Password);compare(field.maximumLength,1024)
   verify(field.passwordCharacter!=="");verify(field.Accessible.name.length>0)
   for(var c of "test")keyClick(c.toUpperCase().charCodeAt(0));compare(view.passwordText.length,4)
   keyClick(Qt.Key_Return);compare(submit.count,1)
   view.authenticatingPassword=true;verify(field.readOnly);keyClick(Qt.Key_Z);compare(view.passwordText.length,4);keyClick(Qt.Key_Return);compare(submit.count,1)
   view.authenticatingPassword=false;keyClick(Qt.Key_Escape);compare(view.passwordText,"")
   view.inputEnabled=false;verify(field.readOnly);keyClick(Qt.Key_Return);compare(submit.count,1)
   view.inputEnabled=true;view.forcePasswordFocus();tryVerify(function(){return field.activeFocus})
   view.failureMessage="Try again";wait(140);compare(field.background.border.color,Qt.color("#b77c7c"))
   view.failureMessage="";view.reducedMotion=true;compare(view.presentationProgress,1)
   view.visible=false;view.visible=true;compare(view.presentationProgress,1);tryVerify(function(){return field.activeFocus})
   host.width=480;host.height=360;wait(30);var p=field.mapToItem(host,0,0)
   verify(p.x>=0 && p.y>=0 && p.x+field.width<=host.width && p.y+field.height<=host.height)
   view.passwordText="";compare(field.text,"")
  }
 }
}'''
            (folder/'tst_lock.qml').write_text(qml)
            env=dict(os.environ,QT_QPA_PLATFORM='offscreen',QT_QUICK_BACKEND='software')
            result=subprocess.run([RUNNER,'-input',str(folder/'tst_lock.qml'),'-import',str(folder)],env=env,capture_output=True,text=True,timeout=15)
            evidence=os.environ.get('DAEMONOS_LOCK_TEST_LOG')
            if evidence:Path(evidence).write_text(result.stdout+result.stderr)
            self.assertEqual(result.returncode,0,result.stdout+result.stderr)
            self.assertNotIn('TypeError',result.stdout+result.stderr)
            self.assertNotIn('ReferenceError',result.stdout+result.stderr)

if __name__=='__main__':unittest.main()
