import importlib.util
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch

SOURCE = Path(__file__).resolve().parents[1]/'reference/background-glass/universal/daemon-glass.py'


class UniversalGlass(unittest.TestCase):
    def setUp(self):
        spec = importlib.util.spec_from_file_location('universal_glass', SOURCE)
        self.module = importlib.util.module_from_spec(spec); spec.loader.exec_module(self.module)
        self.temp = tempfile.TemporaryDirectory();self.addCleanup(self.temp.cleanup)
        self.home = Path(self.temp.name)
        self.module.HOME = self.home;self.module.BASE = self.home/'config'
        self.module.STATE = self.home/'state'
        binaries = patch.object(self.module.shutil, 'which', return_value=None)
        binaries.start();self.addCleanup(binaries.stop)

    def test_opaque_terminal_background_is_changed_without_other_settings(self):
        p = self.home/'.config/foot/foot.ini';p.parent.mkdir(parents=True)
        p.write_text('[main]\nfont=Example Font\n[colors-dark]\nalpha=1.0\n[colors-light]\nalpha=1.0\n')
        self.module.native_recipe('foot', True)
        self.assertIn('font=Example Font', p.read_text())
        self.assertEqual(p.read_text().count('alpha=.62'), 2)
        self.assertTrue(list((self.module.STATE/'before').glob('*')))

    def test_existing_user_transparency_is_retained(self):
        p = self.home/'.config/kitty/kitty.conf';p.parent.mkdir(parents=True)
        p.write_text('font_size 12\nbackground_opacity 0.52\n')
        original=p.read_bytes();self.module.native_recipe('kitty',True)
        self.assertEqual(p.read_bytes(),original)

    def test_existing_files_theme_is_retained_and_import_added(self):
        p = self.home/'.config/gtk-4.0/nautilus-glass.css';p.parent.mkdir(parents=True)
        p.write_text('window.nautilus-window { background: rgba(0,0,0,.51); }\n')
        original=p.read_bytes();self.module.native_recipe('nautilus',True)
        self.assertEqual(p.read_bytes(),original)
        self.assertIn('nautilus-glass.css',(p.parent/'gtk.css').read_text())

    def test_dry_run_writes_nothing_and_does_not_claim_application(self):
        status, _ = self.module.native_recipe('foot', False)
        self.assertEqual(status,'would-configure')
        self.assertFalse((self.home/'.config').exists())
        self.assertFalse(self.module.STATE.exists())

    def test_unknown_app_is_not_modified(self):
        before=list(self.home.rglob('*'))
        self.assertEqual(self.module.native_recipe(None,True)[0],'needs-theme')
        self.assertEqual(list(self.home.rglob('*')),before)

    def test_initial_notifications_are_batched_and_new_apps_notify_once(self):
        apps = {'first':{'name':'First','kind':None,'class':''},'second':{'name':'Second','kind':None,'class':''}}
        with patch.object(self.module,'desktop_apps',return_value=apps),patch.object(self.module,'clients',return_value=[]),patch.object(self.module,'notify',return_value=True) as notify:
            self.module.scan(True,True);self.module.scan(True,True)
            self.assertEqual(notify.call_count,1)
            apps['third']={'name':'Third','kind':None,'class':''}
            self.module.scan(True,True);self.module.scan(True,True)
            self.assertEqual(notify.call_count,2)
            self.assertEqual(notify.call_args.args[0],['Third'])

    def test_excluded_app_does_not_generate_notification(self):
        self.module.BASE.mkdir();(self.module.BASE/'universal-glass.json').write_text('{"ignored_apps":["example-ide"]}')
        with patch.object(self.module,'desktop_apps',return_value={'example-ide':{'name':'Example IDE','kind':None,'class':''}}),patch.object(self.module,'clients',return_value=[]),patch.object(self.module,'notify') as notify:
            report=self.module.scan(True,True)
            self.assertEqual(report['apps']['example-ide']['status'],'ignored');notify.assert_not_called()

    def test_incompatible_native_app_gets_a_theme_notification_status(self):
        for relative in ('.local/bin/chatgpt','.config/omarchy/glass-apps/chatgpt/build-runtime.py'):
            p=self.home/relative;p.parent.mkdir(parents=True,exist_ok=True);p.touch()
        with patch.object(self.module,'compatible',return_value=False):
            self.assertEqual(self.module.native_recipe('chatgpt',True)[0],'needs-theme')
