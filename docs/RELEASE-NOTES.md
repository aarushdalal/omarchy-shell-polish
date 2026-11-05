# Shell Polish 1.6.1 — Background-only desktop glass

Patch safeguard: the automatic monitor preserves an existing Files glass CSS theme, including custom tint/alpha, and only installs its default recipe when missing.

Native background transparency replaces whole-window fading: shared blur size 4 / two passes, foreground/window opacity 100%. Spotify uses the real desktop behind a 72% dark theme tint, without the embedded wallpaper canvas. Decorative gradients, opaque cinema backdrops and fullscreen navigation overlap are addressed while functional text masks stay opaque.

An optional universal monitor scans current/future desktop apps, applies supported native recipes, preserves custom alpha and batches initial unsupported-app notifications. Unknown apps/builds request a theme patch without whole-window fading or app restarts.

Opt-in references cover Files (76%), ChatGPT and the AntiGravity app (74%), and Foot (62%). All IDEs are included in automatic monitoring; IDE-specific native patches remain app-dependent. Pet changes are excluded. Includes guarded native runtime recipes, source-only Spotify alpha helper with upstream MIT attribution, launcher examples and private recovery-kit utilities. Install instructions retain existing configurations and do not restart live apps.

Native helpers are version-specific and fall back to the installed/opaque app on unknown source layouts. No proprietary app archives, compiled runtime copies, account state, private manifests or new workstation captures are published. Existing showcase recordings predate this release.

Validation: native source syntax, offline gradient/image-mask regression checks, guarded ASAR rewrite tests and release privacy checks. Local Spotify/fullscreen, Files and AntiGravity checks and isolated ChatGPT preview results informed the recipes; future app versions need revalidation.
