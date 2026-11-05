# Spotify live palette and native background glass

Version 1.6 removes the embedded wallpaper canvas. The real desktop shows through Spotify's native transparent window with a 72% dark theme tint. Artwork, icons, text and functional masks keep their normal opacity. The compositor supplies gentle blur.

The extension covers navigation, playlist tables, the music panel and cinema/fullscreen playback. It removes decorative album-color gradients while retaining image URL layers. Raw Spicetify color tokens stay opaque because Spotify also uses them in text/icon masks. A transparent native fullscreen backdrop and cinema visibility tracking prevent opaque transitions and overlapping normal navigation.

## Opt-in setup

1. Install Spotify and Spicetify. Retain recovery copies of the extension, theme CSS and launcher.
2. Copy daemon-spotify-sync.js to ~/.config/spicetify/Extensions/ and enable that extension. Review/merge user.css for the current theme.
3. Copy daemon-glass/ to ~/.config/spicetify/daemon-glass/ and build locally:

   ```sh
   cd "$HOME/.config/spicetify/daemon-glass"
   cc -std=c11 -O2 -Wall -Wextra -fPIC -shared -Wl,-z,relro,-z,now -o spotify-alpha.so spotify-alpha.c
   ```

4. Review spotify-launcher before copying it to ~/.local/bin/spotify. It retains the validated AMD Mesa/XWayland launch guard; adjust GPU-specific settings on a different system. Native alpha is enabled only for the pinned Spotify/CEF ELF build IDs. Unknown package updates fall back to opaque native content until revalidated.
5. Refresh without automatic restart (spicetify -n -e refresh), then launch through the user wrapper when convenient. Native alpha needs a new process; later palette updates do not require a restart.
6. Merge the [shared compositor reference](../shared-glass/README.md). Whole-window opacity remains 100%.

The MIT-derived helper changes process memory only; installed binaries are untouched. Its source attribution and license are retained in daemon-glass/. No compiled helper or Spotify files are shipped. Tested base: Spotify 1.3.4.258; new builds require revalidation.

## Live palette bridge

The existing bridge, theme adapter, management CLI and user service distribute colors over loopback SSE (http://127.0.0.1:8974/events). /theme, /notify and /status support palette/status operations. The legacy /wallpaper endpoint remains for protocol compatibility, but the new extension does not fetch or display it. Cached colors stabilize cold starts and SSE reconnects after service interruption.

Repeated windowed/fullscreen transitions were checked on the configured desktop. This does not establish compatibility with every Spotify/Spicetify version. Historical changelog and showcase material describe earlier implementations.
