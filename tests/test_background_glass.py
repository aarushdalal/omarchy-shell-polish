import hashlib
import json
from pathlib import Path
import re
import runpy
import struct
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]

class BackgroundGlass(unittest.TestCase):
    def test_gradient_filter_preserves_url_layers_with_commas(self):
        source = (ROOT/'reference/spotify-sync/daemon-spotify-sync.js').read_text()
        function = re.search(r'(function withoutGradients\(value\) \{.*?\n  \})\n\n  function setupStyleEnforcer', source, re.S).group(1)
        checks = function + r"""
const assert = require('node:assert/strict');
assert.equal(withoutGradients('linear-gradient(red, blue)'), 'none');
assert.equal(withoutGradients('url("data:image/svg+xml,a,b"), radial-gradient(black, transparent)'), 'url("data:image/svg+xml,a,b")');
assert.equal(withoutGradients('repeating-conic-gradient(red 0deg, blue 30deg),url("cover.png")'), 'url("cover.png")');
assert.equal(withoutGradients('url("cover.png")'), 'url("cover.png")');
"""
        subprocess.run(['node','-e',checks],check=True,capture_output=True,text=True)

    def test_asar_patch_updates_only_bootstrap_and_keeps_file_integrity(self):
        namespace = runpy.run_path(str(ROOT/'reference/background-glass/chatgpt/build-runtime.py'))
        marker = 'return("win32"!==process.platform||"enabled"===ea.app.getGPUFeatureStatus().gpu_compositing)&&ea.BrowserWindow.isSystemBackdropSupported()'
        option = 'return{titleBarStyle:"hidden",titleBarOverlay:eRR(n)}'
        code = (marker+';'+option+';'+option+';let j=F.webContents;').encode()
        other = b'UNCHANGED PAYLOAD'
        entry = {'offset':'0','size':len(code),'integrity':{'algorithm':'SHA256','hash':hashlib.sha256(code).hexdigest(),'blockSize':4194304,'blocks':[hashlib.sha256(code).hexdigest()]}}
        header = {'files':{'.vite':{'files':{'build':{'files':{'early-bootstrap-fixture.js':entry}}}},'untouched':{'offset':str(len(code)),'size':len(other)}}}
        metadata=json.dumps(header,separators=(',',':')).encode();padded=metadata+b'\0'*(-len(metadata)%4);pickle=struct.pack('<II',4+len(padded),len(metadata))+padded
        with tempfile.TemporaryDirectory() as folder:
            archive=Path(folder)/'app.asar';archive.write_bytes(struct.pack('<II',4,len(pickle))+pickle+code+other)
            namespace['patch_archive'](archive)
            sizes,_,changed=namespace['inspect_archive'](archive)
            actual_entry=changed['files']['.vite']['files']['build']['files']['early-bootstrap-fixture.js']
            raw=archive.read_bytes();start=8+sizes[1];replacement=raw[start+int(actual_entry['offset']):start+int(actual_entry['offset'])+actual_entry['size']]
            self.assertEqual(hashlib.sha256(replacement).hexdigest(),actual_entry['integrity']['hash'])
            untouched=changed['files']['untouched'];self.assertEqual(raw[start+int(untouched['offset']):start+int(untouched['offset'])+untouched['size']],other)
            self.assertIn(b'transparent:"linux"===r',replacement)
            self.assertNotIn(b'pet-input',replacement)

    def test_unknown_asar_layout_fails_before_rewrite(self):
        namespace=runpy.run_path(str(ROOT/'reference/background-glass/chatgpt/build-runtime.py'))
        data=b'changed upstream code';header={'files':{'.vite':{'files':{'build':{'files':{'early-bootstrap-fixture.js':{'offset':'0','size':len(data)}}}}}}}
        metadata=json.dumps(header).encode();padded=metadata+b'\0'*(-len(metadata)%4);pickle=struct.pack('<II',4+len(padded),len(metadata))+padded
        with tempfile.TemporaryDirectory() as folder:
            archive=Path(folder)/'app.asar';original=struct.pack('<II',4,len(pickle))+pickle+data;archive.write_bytes(original)
            with self.assertRaises(RuntimeError):namespace['patch_archive'](archive)
            self.assertEqual(archive.read_bytes(),original)
