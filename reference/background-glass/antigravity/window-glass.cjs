'use strict';
const fs = require('node:fs');
const path = require('node:path');
const cssPath = path.join(__dirname, 'background.css');
module.exports = function applyBackgroundGlass(win) {
  let key;
  let pending = Promise.resolve();
  const apply = () => {
    pending = pending.then(async () => {
      if (win.isDestroyed() || win.webContents.isDestroyed()) return;
      const css = fs.readFileSync(cssPath, 'utf8');
      const next = await win.webContents.insertCSS(css, {cssOrigin: 'user'});
      if (key) await win.webContents.removeInsertedCSS(key).catch(() => {});
      key = next;
    }).catch(() => {});
  };
  win.webContents.on('did-finish-load', apply);
  const watcher = fs.watch(cssPath, {persistent: false}, apply);
  win.on('closed', () => watcher.close());
};
