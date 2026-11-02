"""Real Qt tests for the local Caelestia SearchBar overlay.

Installed base controls and the real Caelestia.Config Tokens plugin are used.
Only Colours/Motion service providers are inert stubs: loading real Colours would
change live compositor layer rules. No full Caelestia shell is launched.
"""
import hashlib
import json
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT/'caelestia/components/controls/SearchBar.qml'
BASE = Path(os.environ.get('CAELESTIA_TEST_BASE', str(Path.home()/'.config/quickshell/caelestia')))
RUNNER = next((p for p in [os.environ.get('QT6_QMLTESTRUNNER'),'/usr/lib/qt6/bin/qmltestrunner',shutil.which('qmltestrunner6')] if p and Path(p).is_file()), '')


def stage_components(stage):
    components=stage/'qs/components';controls=components/'controls';controls.mkdir(parents=True)
    names=['Anim','CAnim','StyledRect','StyledText','MaterialIcon','StateLayer']
    for name in names:
        override=ROOT/'caelestia/components'/(name+'.qml')
        shutil.copy2(override if override.is_file() else BASE/'components'/(name+'.qml'),components/(name+'.qml'))
    (components/'qmldir').write_text('module qs.components\n'+''.join(f'{name} 1.0 {name}.qml\n' for name in names))
    for name in ['TextFieldBase','ButtonBase','IconButton']: shutil.copy2(BASE/'components/controls'/(name+'.qml'),controls/(name+'.qml'))
    shutil.copy2(SOURCE,controls/'SearchBar.qml')
    services=stage/'qs/services';services.mkdir()
    (services/'qmldir').write_text('module qs.services\nsingleton Colours 1.0 Colours.qml\nsingleton Motion 1.0 Motion.qml\n')
    (services/'Colours.qml').write_text('''pragma Singleton
import QtQuick
QtObject {
 property bool light:false
 property QtObject palette:QtObject {
  property color m3surfaceContainer:"#1a1a1a";property color m3onSurface:"#baa092";property color m3onSurfaceVariant:"#cec3cc"
  property color m3primary:"#97717a";property color m3onPrimary:"#ffffff";property color m3secondary:"#97717a"
  property color m3secondaryContainer:"#3b3035";property color m3onSecondary:"#ffffff";property color m3onSecondaryContainer:"#cec3cc"
 }
 property QtObject tPalette:QtObject {property color m3surfaceContainer:Qt.rgba(0.19,0.17,0.18,0.65)}
}''')
    (services/'Motion.qml').write_text('''pragma Singleton
import QtQuick
QtObject {property bool reducedMotion:false;property int micro:90;property int standard:170;property int expressive:240;property int easeStandard:Easing.OutCubic;property int easeExpressive:Easing.OutBack;property real springOvershoot:1.08}''')
    return controls


@unittest.skipUnless(Path(RUNNER).is_file() and (BASE/'components/controls/TextFieldBase.qml').is_file(), 'Qt Quick Test and installed Caelestia base components required')
class SearchBarPolishTests(unittest.TestCase):
    def save_evidence(self,name,data,log):
        destination=os.environ.get('DAEMONOS_SEARCHBAR_TEST_EVIDENCE')
        if destination:
            folder=Path(destination);folder.mkdir(parents=True,exist_ok=True)
            data=dict(data,sourceSha256=hashlib.sha256(SOURCE.read_bytes()).hexdigest(),stateLayerSha256=hashlib.sha256((ROOT/'caelestia/components/StateLayer.qml').read_bytes()).hexdigest())
            (folder/(name+'.json')).write_text(json.dumps(data,indent=2)+'\n')
            (folder/(name+'.log')).write_text(log)

    def test_real_control_interaction_focus_and_reduced_motion(self):
        with tempfile.TemporaryDirectory(prefix='searchbar-qt-test-') as folder:
            stage=Path(folder);stage_components(stage)
            (stage/'tst_searchbar.qml').write_text(TEST_QML)
            env=dict(os.environ,QT_QPA_PLATFORM='offscreen',QT_QUICK_BACKEND='software',QT_FORCE_STDERR_LOGGING='1')
            env.pop('QML_IMPORT_PATH',None)
            result_log=stage/'qtest.txt'
            run=subprocess.run([RUNNER,'-input',str(stage/'tst_searchbar.qml'),'-import',str(stage),'-o',str(result_log)+',txt'],env=env,capture_output=True,text=True,timeout=25)
            log=(result_log.read_text() if result_log.exists() else '')+run.stdout+run.stderr
            self.save_evidence('interaction',{'ok':run.returncode==0,'method':'Qt Quick Test; exact SearchBar/base controls; inert service providers'},log)
            self.assertEqual(run.returncode,0,log)
            self.assertNotIn('FAIL!',log)
            self.assertNotIn('ReferenceError',log)
            self.assertNotIn('TypeError',log)

    @unittest.skipUnless(shutil.which('quickshell') and os.environ.get('WAYLAND_DISPLAY'),'Hidden native type check needs Quickshell/Wayland')
    def test_native_hidden_component_compile(self):
        with tempfile.TemporaryDirectory(prefix='searchbar-native-test-') as folder:
            stage=Path(folder);stage_components(stage)
            (stage/'shell.qml').write_text('''import QtQuick
import QtQuick.Window
import Quickshell
import "qs/components/controls" as Controls
ShellRoot {Window {visible:false;Controls.SearchBar {width:600;placeholderText:"Search"}} Timer {interval:300;running:true;onTriggered:{console.log("SEARCHBAR-NATIVE-PASS");Qt.quit()}}}''')
            env=dict(os.environ,QT_QPA_PLATFORM='wayland',QML_IMPORT_PATH=str(stage))
            run=subprocess.run(['quickshell','-p',str(stage),'--no-color'],env=env,capture_output=True,text=True,timeout=8)
            log=run.stdout+run.stderr
            self.save_evidence('native-compile',{'ok':run.returncode==0 and 'SEARCHBAR-NATIVE-PASS' in log,'visible':False,'method':'Exact SearchBar/base controls, real Tokens, inert Colours/Motion'},log)
            self.assertEqual(run.returncode,0,log)
            self.assertIn('SEARCHBAR-NATIVE-PASS',log)
            self.assertNotIn('Failed to load configuration',log)
            self.assertNotIn('ReferenceError',log)
            self.assertNotIn('TypeError',log)


TEST_QML = r'''import QtQuick
import QtTest
import "qs/components/controls" as Controls
import qs.components
import qs.services
Item {
 id: host
 width:800;height:240
 property var current:null
 Item {id:other; x:20;y:160;width:100;height:30;activeFocusOnTab:true}
 Component {id:feedbackFactory;StateLayer {x:20;y:110;width:650;height:50}}
 Component {id:barFactory;Controls.SearchBar {x:20;y:30;width:650;placeholderText:"Search apps, files and actions"}}
 SignalSpy {id:acceptSpy;target:host.current;signalName:"accepted"}
 TestCase {
  id:tests
  name:"SearchBarPolish"
  when:windowShown
  function createBar() {var b=createTemporaryObject(barFactory,host);verify(b!==null);host.current=b;wait(30);return b}
  function near(a,b) {verify(Math.abs(a-b)<0.012,"expected "+a+" near "+b)}
  function init() {Motion.reducedMotion=false;Motion.micro=90;Motion.standard=170;Colours.tPalette.m3surfaceContainer=Qt.rgba(.19,.17,.18,.65);other.forceActiveFocus();acceptSpy.clear()}
  function cleanup() {host.current=null}
  function test_surface_and_focus_endpoint() {
   var b=createBar();near(b.surfaceOpacity,.94);compare(b.Accessible.name,b.placeholderText)
   var h=b.height,w=b.width; b.forceActiveFocus();tryVerify(function(){return b.activeFocus});near(b.surfaceOpacity,.98)
   var outline=findChild(b,"search-focus-outline");verify(outline!==null);tryVerify(function(){return Math.abs(outline.opacity-.85)<.01})
   compare(b.width,w);compare(b.height,h);tryCompare(b.searchIcon,"color",Colours.palette.m3primary)
   other.forceActiveFocus();tryVerify(function(){return !b.activeFocus});tryVerify(function(){return outline.opacity<.01});near(b.surfaceOpacity,.94)
  }
  function test_keyboard_edit_selection_enter_and_clear() {
   var b=createBar();b.forceActiveFocus();for (var c of "terminal") keyClick(c.toUpperCase().charCodeAt(0));compare(b.text,"terminal")
   keyClick(Qt.Key_Left);compare(b.cursorPosition,7);b.selectAll();compare(b.selectedText,"terminal")
   keyClick(Qt.Key_Return);compare(acceptSpy.count,1)
   b.clearIcon.clicked();compare(b.text,"");verify(!b.clearIcon.enabled);compare(b.clearIcon.Accessible.name,"Clear search")
   b.text="again";b.forceActiveFocus();b.selectAll();keyClick(Qt.Key_Backspace);compare(b.text,"")
  }
  function test_mouse_focus_and_clear_preserved() {
   var b=createBar();other.forceActiveFocus();mouseClick(b,40,b.height/2);tryVerify(function(){return b.activeFocus})
   b.text="clear me";wait(200);mouseClick(b.clearIcon,b.clearIcon.width/2,b.clearIcon.height/2);compare(b.text,"")
  }
  function test_opacity_bounds_and_user_override() {
   var b=createBar();b.minimumSurfaceOpacity=2;near(b.surfaceOpacity,1)
   b.minimumSurfaceOpacity=-2;near(b.surfaceOpacity,.65)
   b.minimumSurfaceOpacity=NaN;near(b.surfaceOpacity,.94)
   b.surfaceColor=Qt.rgba(.1,.12,.14,.4);b.minimumSurfaceOpacity=.8;near(b.surfaceOpacity,.8)
   b.focusedMinimumSurfaceOpacity=.9;b.forceActiveFocus();near(b.surfaceOpacity,.9)
   tryVerify(function(){return Math.abs(b.bg.color.g-.12)<.012 && Math.abs(b.bg.color.b-.14)<.012});near(b.bg.color.r,.1);near(b.bg.color.g,.12);near(b.bg.color.b,.14)
  }
  function test_preset_timing_and_reduced_geometry() {
   var b=createBar();Motion.micro=55;compare(b.focusDuration,55);Motion.micro=140;compare(b.focusDuration,140);Motion.micro=300;compare(b.focusDuration,160)
   Motion.reducedMotion=true;compare(b.focusDuration,0)
   var feedback=findChild(b,"search-background-feedback");verify(feedback!==null);verify(!feedback.disabled)
   b.forceActiveFocus();near(findChild(b,"search-focus-outline").opacity,.85)
   other.forceActiveFocus();compare(findChild(b,"search-focus-outline").opacity,0)
   other.forceActiveFocus();mouseClick(b,40,b.height/2);near(feedback.circleRadius,0)
   b.text="clear reduced";wait(50);mousePress(b.clearIcon,b.clearIcon.width/2,b.clearIcon.height/2);wait(20);near(b.clearIcon.stateLayer.circleRadius,0);mouseRelease(b.clearIcon,b.clearIcon.width/2,b.clearIcon.height/2);compare(b.text,"")
  }
  function test_hidden_feedback_stays_quiet() {
   var b=createBar();b.visible=false;b.forceActiveFocus();wait(10);compare(findChild(b,"search-focus-outline").opacity,b.activeFocus ? .85 : 0);var settled=findChild(b,"search-focus-outline").opacity;wait(180);compare(findChild(b,"search-focus-outline").opacity,settled)
  }
  function test_tab_traversal_and_disabled_editing() {
   var b=createBar();b.forceActiveFocus();keyClick(Qt.Key_Tab);tryVerify(function(){return other.activeFocus});keyClick(Qt.Key_Backtab);tryVerify(function(){return b.activeFocus})
   b.text="preserved";b.enabled=false;keyClick(Qt.Key_Z);compare(b.text,"preserved")
  }
  function test_native_ripple_click_cleanup_and_reduced_toggle() {
   var feedback=createTemporaryObject(feedbackFactory,host);verify(feedback!==null)
   var ripple=findChild(feedback,"state-layer-ripple-animation"),fade=findChild(feedback,"state-layer-fade-animation"),circle=findChild(feedback,"state-layer-ripple")
   verify(ripple!==null && fade!==null && circle!==null)
   feedback.press(20,20);verify(ripple.running);wait(20);verify(circle.opacity>0)
   Motion.reducedMotion=true;verify(!ripple.running && !fade.running);compare(circle.opacity,0);compare(feedback.circleRadius,0)
   var clickSpy=createTemporaryQmlObject('import QtTest; SignalSpy {}',host);clickSpy.target=feedback;clickSpy.signalName="clicked"
   mouseClick(feedback,20,20);compare(clickSpy.count,1);compare(circle.opacity,0);verify(!ripple.running)
   Motion.reducedMotion=false;feedback.press(20,20);verify(ripple.running);feedback.visible=false;verify(!ripple.running && !fade.running);compare(circle.opacity,0)
   feedback.visible=true;feedback.press(20,20);tryVerify(function(){return !ripple.running && !fade.running && circle.opacity===0},3000)
  }
  function test_theme_and_existing_bg_override() {
   var b=createBar();b.bg.color="#403c3c";tryCompare(b.bg,"color",Qt.color("#403c3c"))
   b.surfaceColor=Qt.rgba(.9,.88,.87,.65);Colours.palette.m3onSurface="#262222";Colours.palette.m3primary="#76525c";b.forceActiveFocus();tryCompare(b.searchIcon,"color",Colours.palette.m3primary)
  }
 }
}'''

if __name__=='__main__':unittest.main(verbosity=2)
