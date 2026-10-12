# omarchy-shell-polish 1.1.1

Restore the narrow DaemonOS power drawer with its original large icons and no permanent title/action labels. Both desktops share a tested action state machine, visible confirmation and command errors. Power actions run through a tracked process; remaining-window refusal retains explicit force controls. DaemonOS keeps an in-flight action alive when its drawer closes and reopens it on failure.

Replace the music and power-panel decorations with a local transparent wireframe animation at faster bounded playback speed (about 2×), tinted with the current theme. The 200 × 200, 20-frame asset is about 399 KiB and pauses when hidden or reduced motion is selected. See caelestia/assets/CREDITS.md for the source and CC BY-SA 4.0 attribution.

Validation: both native action panels passed confirmation, exact command dispatch, duplicate suppression, unsaved-window refusal, explicit force and failure visibility tests using safe substitute commands. DaemonOS drawer lifetime was tested while a delayed command ran. Shared state and native compile checks passed. The unlocked DaemonOS shell was reloaded without ending the compositor or applications. Real logout/shutdown was not triggered during testing.

Current payload privacy scan passed; old public history is preserved and new commits/tags use GitHub noreply metadata.
