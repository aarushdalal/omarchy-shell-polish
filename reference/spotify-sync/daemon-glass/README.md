# Spotify background-only glass

Native X11 alpha helper, locally compiled and adapted from https://github.com/fixpointer/libcef-transparency-linux (MIT).
Upstream reference commit: 273b50f2074847700f1065c82e3df42b2af936c2

The user launcher enables this only for validated Spotify/CEF ELF build IDs. Package binaries are not modified. New builds fall back to opaque native content until revalidated. The CSS uses transparent html, a 72% black/theme-tinted body, opaque artwork/text, and no decorative gradients. Hyprland uses 100% window opacity with the shared gentle blur (size 4, passes 2).

Rebuild: cc -std=c11 -O2 -Wall -Wextra -fPIC -shared -Wl,-z,relro,-z,now -o spotify-alpha.so spotify-alpha.c

Launch through ~/.local/bin/spotify. When refreshing Spicetify, use -n then relaunch through this wrapper so the alpha helper remains active.
