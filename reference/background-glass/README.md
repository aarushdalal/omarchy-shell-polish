# Background-only desktop glass

Opt-in Linux references for transparent backgrounds with solid text, icons and artwork. These are not applied by the general installer. Merge selected settings and keep recovery copies. The pet integration is excluded from this release.

## Automatic current/future app coverage

The opt-in [universal monitor](universal/README.md) applies supported native recipes and notifies once for apps needing a specific theme. It preserves existing transparency settings and leaves unknown binaries/foreground opacity alone.

## Background settings

| Surface | Background opacity | Setup |
| --- | --- | --- |
| Spotify | 72% dark theme tint | [Spotify instructions](../spotify-sync/README.md) |
| Files / Nautilus | 76% black | Import gtk4/nautilus-glass.css from ~/.config/gtk-4.0/gtk.css |
| ChatGPT desktop | 74% black | User runtime recipe below |
| AntiGravity app | 74% black | User runtime recipe below; IDEs monitored separately |
| Foot | 62% | Merge foot/opacity.ini into existing dark/light sections |
| Screensaver Studio 1.9.0 | 68% suggested | Set [display] background_opacity = 0.68 |

Use the [shared compositor reference](../shared-glass/README.md) with 100% window opacity and gentle blur size 4 / two passes. Applications supply background alpha; an opaque application remains opaque. Avoid fading its whole window as compensation. Foot 1.28 uses [colors-dark] / [colors-light]; new terminal windows load the setting. The Files CSS never changes widget/group opacity. Its companion theme-sync script retains the CSS import through palette regeneration.

## ChatGPT and AntiGravity app

These are guarded, version-specific Linux x86_64 patch recipes, not replacements for applications. Tested bases: ChatGPT desktop 26.1027.51404 under /usr/lib/chatgpt and AntiGravity 2.26.0 under /opt/Antigravity. AntiGravity IDE is not modified.

Builders create disposable user-owned runtimes under ~/.cache. Original executables and security fuses are retained; system packages, renderer isolation and account settings are not changed. Source matching or integrity failures cause the launcher to use the installed application. Unknown future versions need revalidation.

From this reference directory, install the selected authored files:

```sh
install -Dm644 chatgpt/build-runtime.py "$HOME/.config/omarchy/glass-apps/chatgpt/build-runtime.py"
install -Dm755 launchers/chatgpt "$HOME/.local/bin/chatgpt"
install -Dm644 antigravity/build-runtime.py "$HOME/.config/Antigravity/daemon-glass/build-runtime.py"
install -Dm644 antigravity/window-glass.cjs "$HOME/.config/Antigravity/daemon-glass/window-glass.cjs"
install -Dm644 antigravity/background.css "$HOME/.config/Antigravity/daemon-glass/background.css"
install -Dm755 launchers/antigravity "$HOME/.local/bin/antigravity"
```

Use the user launchers or point a personal desktop-entry override at them. Fully quit and reopen an already-running application when convenient: the existing process otherwise keeps its old window setup. Builders and tests do not close a live app. App binaries, ASAR archives, generated runtimes, libraries and preview profiles are not distributed here.

## Private recovery kits

backup/export-kit.py and backup/restore.py are optional local recovery tools. Install them under ~/.config/omarchy/glass-apps/ after setting up the corresponding references. The exporter requires every selected dependency, including an installed compatible Screensaver Studio base, and fails on missing sources. Keep its generated restore-kit private and include the configuration directory in your backup system. The restore tool verifies checksums by default; --apply writes selected files with prior-file recovery copies after the desktop base is installed.

Generated kits may contain personal configuration and must not be committed. Do not include account stores, cookies, credentials or generated caches. No private kit, machine manifest or cloud receipt is part of this source release.

## Verification scope

Spotify windowed/fullscreen transitions, Files rendering and AntiGravity background/content opacity were checked on the configured desktop. ChatGPT background glass was checked in a separate preview profile. Screensaver rendering has background/foreground pixel regressions, but its live glass appearance still needs checking on the target compositor. No universal compatibility or performance improvement is claimed. Existing showcase recordings predate this release.
