// ==============================================================================
// PROJECT DAEMON — SPOTIFY LIVE THEME SYNCHRONIZATION
// Spicetify Runtime Extension: daemon-spotify-sync.js
// ==============================================================================

(function DaemonSpotifySync() {
  const STORAGE_KEY = "daemon-spotify-sync:palette";
  const BRIDGE_URL = "http://127.0.0.1:8974";
  const EVENTS_URL = `${BRIDGE_URL}/events`;
  const THEME_URL = `${BRIDGE_URL}/theme`;

  let eventSource = null;
  let currentPaletteHash = "";
  let reconnectTimeout = null;

  // Helper: Simple string hash to prevent redundant DOM updates
  function computeHash(obj) {
    const str = typeof obj === "string" ? obj : JSON.stringify(obj);
    let hash = 0;
    for (let i = 0; i < str.length; i++) {
      hash = (hash << 5) - hash + str.charCodeAt(i);
      hash |= 0;
    }
    return String(hash);
  }

  // Ensure style container tags exist in head
  function getOrCreateStyle(id) {
    let el = document.getElementById(id);
    if (!el) {
      el = document.createElement("style");
      el.id = id;
      document.head.appendChild(el);
    }
    return el;
  }

  // Generate dynamic CSS rules mapping the semantic palette to Spotify UI
  function generateCss(vars, rgb, colors) {
    const bgPrimary = colors.backgroundPrimary || "#000000";
    const bgSecondary = colors.backgroundSecondary || "#0a0a0a";
    const bgElevated = colors.backgroundElevated || "#141414";
    const bgHover = colors.backgroundHover || "#1c1c1c";
    const bgSelected = colors.backgroundSelected || "#222222";
    const fgPrimary = colors.foregroundPrimary || "#d7d7d7";
    const fgSecondary = colors.foregroundSecondary || "#8f8f8f";
    const fgMuted = colors.foregroundMuted || "#666666";
    const accent = colors.accentPrimary || "#7d7d7d";
    const borderSubtle = colors.borderSubtle || "#1a1a1a";
    const tint = (base, overlay, weight) => {
      const parse = (hex) => hex.replace("#", "").match(/.{2}/g).map((n) => parseInt(n, 16));
      const a = parse(base), b = parse(overlay);
      return "#" + a.map((v, i) => Math.round(v * (1 - weight) + b[i] * weight).toString(16).padStart(2, "0")).join("");
    };
    const glass = tint(bgPrimary, accent, 0.07);
    const raised = tint(bgElevated, accent, 0.08);
    const accentInk = (() => {
      const c = accent.replace("#", "").match(/.{2}/g).map((n) => parseInt(n, 16) / 255);
      const l = c.map((v) => v <= 0.04045 ? v / 12.92 : ((v + 0.055) / 1.055) ** 2.4);
      return (0.2126 * l[0] + 0.7152 * l[1] + 0.0722 * l[2]) > 0.179 ? "#090909" : "#ffffff";
    })();

    let css = `
/* DaemonOS Spotify Live Theme Variables */
:root {
`;

    // Keep raw colors opaque: Spotify also uses these in text/icon alpha masks.
    // Surface transparency belongs in background properties only.
    // 1. Spicetify --spice-* variables
    if (vars) {
      for (const [k, v] of Object.entries(vars)) {
        css += `  --spice-${k}: ${v} !important;\n`;
      }
    }

    // 2. Spicetify --spice-rgb-* variables
    if (rgb) {
      for (const [k, v] of Object.entries(rgb)) {
        css += `  --spice-rgb-${k}: ${v} !important;\n`;
      }
    }

    // 3. Spotify Native Design Tokens
    css += `
  --background-base: ${bgPrimary} !important;
  --background-highlight: ${bgElevated} !important;
  --background-press: ${bgSelected} !important;
  --background-elevated-base: ${raised} !important;
  --background-elevated-highlight: ${bgHover} !important;
  --background-tinted-base: ${bgSecondary} !important;
  --background-tinted-highlight: ${bgElevated} !important;
  --background-tinted-press: ${bgSelected} !important;

  --text-base: ${fgPrimary} !important;
  --text-subdued: ${fgSecondary} !important;
  --text-bright-accent: ${accent} !important;
  --essential-base: ${accent} !important;
  --essential-subdued: ${fgMuted} !important;
  --essential-bright-accent: ${accent} !important;
  --essential-positive: ${accent} !important;
  --decorative-base: ${borderSubtle} !important;
  --decorative-subdued: ${borderSubtle} !important;

  --daemon-sync-accent: ${accent};
  --daemon-sync-bg: ${bgPrimary};
  --daemon-sync-border: ${borderSubtle};
  --daemon-sync-hover: ${bgHover};
}

/* The compositor reveals the real desktop. One quiet, theme-tinted canvas
   keeps nested panels from building up dark/opaque layers. */
html, body {
  background: transparent !important;
  color: ${fgPrimary} !important;
}
body { background: ${glass}b8 !important; }
:fullscreen::backdrop { background: transparent !important; }
#daemon-spotify-wallpaper { display: none !important; }

/* Native scopes redefine Encore tokens; apply the palette within each scope. */
:root, .encore-dark-theme, .encore-light-theme,
.encore-base-set, .encore-tinted-set, .encore-elevated-set {
  --background-base: transparent !important;
  --background-highlight: ${raised} !important;
  --background-press: ${bgSelected} !important;
  --background-elevated-base: ${raised} !important;
  --background-elevated-highlight: ${bgHover} !important;
  --background-tinted-base: transparent !important;
  --background-tinted-highlight: ${raised} !important;
  --background-tinted-press: ${bgSelected} !important;
  --background-base-min-contrast: transparent !important;
  --background-base-high-contrast: transparent !important;
  --text-base: ${fgPrimary} !important;
  --text-subdued: ${fgSecondary} !important;
  --text-bright-accent: ${accent} !important;
  --essential-base: ${fgPrimary} !important;
  --essential-subdued: ${fgMuted} !important;
  --essential-bright-accent: ${accent} !important;
  --essential-positive: ${accent} !important;
  --decorative-base: ${borderSubtle} !important;
}

/* Main layout, library, playlist table, queue, lyrics and both player panels. */
#main, .Root, .Root__top-container, .Root__main-view,
.Root__nav-bar, .Root__globalNav, .Root__now-playing-bar,
[class*="Root__right-sidebar"],
.main-view-container, .main-view-container__scroll-node,
.main-view-container__scroll-node-child, .under-main-view,
.main-home-content, .main-home-contentContainer,
[data-testid="home-page"], main, aside, footer, nav,
.main-rootlist-rootlist, .main-yourLibraryX-libraryContainer,
.main-yourLibraryX-entryPoints, [data-testid="your-library"],
.playlist-playlist-playlist, .playlist-playlist-content,
.main-trackList-trackList, .main-trackList-trackListHeader,
.main-trackList-trackListHeaderRow, [role="grid"], [role="treegrid"],
[role="rowgroup"], [data-testid="playlist-tracklist"],
.main-nowPlayingBar-container, .main-nowPlayingBar-nowPlayingBar,
.main-nowPlayingView-container, .main-nowPlayingView-content,
.main-nowPlayingView-section, .main-nowPlayingView-nowPlayingWidget,
.main-nowPlayingView-contextItemInfo, .main-nowPlayingView-queue,
.main-queue-queue, .lyrics-lyrics-container,
.main-topBar-container, header[data-testid="topbar"],
.main-entityHeader-backgroundColor, .main-entityHeader-overlay,
.main-entityHeader-gradient, .main-actionBarBackground-background,
.main-topBar-background, .main-topBar-overlay,
.main-home-filterChipsContainer, .main-home-filterChipsSection,
.main-heroCard-card, [data-testid="hero-card"],
.dqwQhIudKoD98eWJzj5E,
.main-nowPlayingView-section > div,
.main-shelf-shelf, section[data-testid="component-shelf"] {
  background: transparent !important;
  background-image: none !important;
  backdrop-filter: none !important;
  box-shadow: none !important;
}

/* Keep artwork URL layers when a decorative pseudo-element also has a gradient. */
[data-daemon-flat-before]::before {
  background-image: var(--daemon-before-image, none) !important;
  background-color: transparent !important;
}
[data-daemon-flat-after]::after {
  background-image: var(--daemon-after-image, none) !important;
  background-color: transparent !important;
}

/* Decorative header pseudo-elements can carry a second gradient layer. */
.main-topBar-background::before, .main-topBar-background::after,
.main-entityHeader-backgroundColor::before, .main-entityHeader-backgroundColor::after,
.main-entityHeader-overlay::before, .main-entityHeader-overlay::after,
.main-view-container::before, .main-view-container::after {
  background: transparent !important;
  background-image: none !important;
}

/* Full-screen player: suppress track-derived colors through track/mode changes. */
[style*="--cinema-mode-bg-color-from"],
[style*="--cinema-mode-bg-color-from"] > div:first-child,
.WCfsW4a6JVlKYVF34a1A,
.StXaJR8ueLDRsntBN79Y, .Root__lyrics-cinema,
.Root__lyrics-cinema > div {
  --cinema-mode-bg-color-from: transparent !important;
  --cinema-mode-bg-color-to: transparent !important;
  --background-base: transparent !important;
  --background-highlight: ${raised} !important;
  --background-press: ${bgSelected} !important;
  --background-elevated-base: ${raised} !important;
  --background-elevated-highlight: ${bgHover} !important;
  --background-tinted-base: transparent !important;
  --background-tinted-highlight: ${raised} !important;
  --background-tinted-press: ${bgSelected} !important;
  --text-base: ${fgPrimary} !important;
  --text-subdued: ${fgSecondary} !important;
  --essential-base: ${fgPrimary} !important;
  background: transparent !important;
  background-image: none !important;
}

/* A transparent cinema overlay must not reveal the normal app navigation below it. */
html[data-daemon-cinema-fullscreen] .Root__globalNav,
html[data-daemon-cinema-fullscreen] .Root__nav-bar,
html[data-daemon-cinema-fullscreen] .Root__main-view,
html[data-daemon-cinema-fullscreen] [class*="Root__right-sidebar"] {
  visibility: hidden !important;
}

/* Neutralize nested layout fills without touching artwork or button states. */
.Root__main-view, [class*="Root__right-sidebar"], .Root__nav-bar,
.Root__now-playing-bar {
  --background-base: transparent !important;
  --background-tinted-base: transparent !important;
}
.main-trackList-trackListRow {
  background: transparent !important;
}
.main-trackList-trackListRow:hover,
.main-trackList-trackListRow:focus-within {
  background: ${accent}18 !important;
}
.main-trackList-trackListRow.main-trackList-selected,
.main-trackList-trackListRow[aria-selected="true"] {
  background: ${accent}28 !important;
}
.main-trackList-active .main-trackList-rowTitle,
.main-trackList-active .main-trackList-rowNumber,
button[aria-checked="true"], button[aria-pressed="true"] {
  color: ${accent} !important;
}
.Root__nav-bar { border-right: 1px solid ${accent}20 !important; }
.Root__now-playing-bar { border-top: 1px solid ${accent}20 !important; }

/* Controls and small raised surfaces retain contrast and follow the theme. */
.main-card-card { background: ${raised}70 !important; border-radius: 8px !important; }
.main-card-card:hover { background: ${accent}20 !important; }
.main-contextMenu-menu, #context-menu, [role="dialog"],
[data-testid="user-widget-dropdown"], #recent-searches-dropdown > div {
  background: ${raised}f0 !important;
  border: 1px solid ${accent}35 !important;
  border-radius: 8px !important;
  box-shadow: 0 8px 24px #00000040 !important;
}
.main-contextMenu-menuItemButton:hover {
  background: ${accent}22 !important;
  color: ${fgPrimary} !important;
}
.main-topBar-searchBar, .main-topBar-searchBar input,
input[data-testid="search-input"] {
  background: ${raised}90 !important;
  color: ${fgPrimary} !important;
}
input:focus-visible, button:focus-visible, a:focus-visible {
  outline-color: ${accent} !important;
}
.encore-bright-accent-set, .encore-inverted-light-set,
button[data-testid="control-button-playpause"],
.main-playButton-PrimaryButton, .main-playButton-playButton {
  --background-base: ${accent} !important;
  --background-highlight: ${accent} !important;
  --text-base: ${accentInk} !important;
  --essential-base: ${accentInk} !important;
  background-color: ${accent} !important;
  color: ${accentInk} !important;
}
.x-progressBar-fillColor, .playback-bar .x-progressBar-fillColor,
.volume-bar .x-progressBar-fillColor { background: ${accent} !important; }
.x-progressBar-progressBarBackground { background: ${accent}30 !important; }
::-webkit-scrollbar { width: 8px; height: 8px; }
::-webkit-scrollbar-track { background: transparent; }
::-webkit-scrollbar-thumb { background: ${accent}55; border-radius: 4px; }
::-webkit-scrollbar-thumb:hover { background: ${accent}88; }
@media (prefers-reduced-motion: no-preference) {
  button, .main-card-card, .main-trackList-trackListRow {
    transition: background-color 180ms ease, color 180ms ease;
  }
}

`;
    return css;
  }

  // Apply the desktop palette; wallpaper is supplied only by the compositor.
  function applyPalette(palette, notify = false) {
    if (!palette || !palette.colors) return;

    const hash = computeHash(palette);
    if (hash === currentPaletteHash) {
      return; // Palette is already applied, zero reflow
    }
    currentPaletteHash = hash;

    // Cache locally for instant next startup
    try {
      localStorage.setItem(STORAGE_KEY, JSON.stringify(palette));
    } catch (e) {}

    const vars = palette.spicetify?.vars || {};
    const rgb = palette.spicetify?.rgb || {};
    const colors = palette.colors || {};

    // 1. Direct inline CSS variables on document.documentElement
    const rootStyle = document.documentElement.style;
    for (const [k, v] of Object.entries(vars)) {
      rootStyle.setProperty(`--spice-${k}`, v);
    }
    for (const [k, v] of Object.entries(rgb)) {
      rootStyle.setProperty(`--spice-rgb-${k}`, v);
    }
    rootStyle.setProperty("--background-base", colors.backgroundPrimary || "#000000");
    rootStyle.setProperty("--text-base", colors.foregroundPrimary || "#d7d7d7");
    rootStyle.setProperty("--essential-base", colors.accentPrimary || "#7d7d7d");

    // Remove the retired embedded image, including on a live extension reload.
    document.getElementById("daemon-spotify-wallpaper")?.remove();

    // 3. Inject comprehensive stylesheet
    const styleEl = getOrCreateStyle("daemon-spotify-sync-styles");
    styleEl.textContent = generateCss(vars, rgb, colors);

    // 4. Dispatch custom event for other extensions / marketplace modules
    window.dispatchEvent(
      new CustomEvent("daemon-theme-changed", { detail: palette })
    );

    if (notify && window.Spicetify && Spicetify.showNotification) {
      Spicetify.showNotification(`DaemonOS: ${palette.name}`);
    }

  }

  // Keep daemon-spotify-sync-styles at the very end of <head> to win cascade against all other plugins
  function ensureStylesheetPrecedence() {
    const head = document.head;
    const styleEl = document.getElementById("daemon-spotify-sync-styles");
    if (styleEl && head.lastElementChild !== styleEl) {
      head.appendChild(styleEl);
    }
  }

  // Native fullscreen creates its own browser backdrop. Keep it transparent and
  // hide underlying navigation only while the cinema surface is actually present.
  function syncFullscreenGlass() {
    const cinema = document.querySelector('[style*="--cinema-mode-bg-color-from"]') || document.querySelector(".StXaJR8ueLDRsntBN79Y");
    const active = Boolean(document.fullscreenElement && cinema && cinema.getBoundingClientRect().height > 0);
    document.documentElement.toggleAttribute("data-daemon-cinema-fullscreen", active);
  }

  // Remove decorative gradients as routes and Now Playing content change.
  // Split only at top-level commas, preserving artwork URL layers verbatim.
  function withoutGradients(value) {
    let depth = 0, quote = "", start = 0;
    const layers = [];
    for (let i = 0; i < value.length; i++) {
      const c = value[i];
      if (quote) { if (c === quote && value[i - 1] !== "\\") quote = ""; }
      else if (c === '"' || c === "'") quote = c;
      else if (c === "(") depth++;
      else if (c === ")") depth--;
      else if (c === "," && depth === 0) { layers.push(value.slice(start, i)); start = i + 1; }
    }
    layers.push(value.slice(start));
    return layers.filter((s) => !/^\s*(?:repeating-)?(?:linear|radial|conic)-gradient\(/i.test(s)).join(",") || "none";
  }

  function setupStyleEnforcer() {
    ensureStylesheetPrecedence();
    new MutationObserver(ensureStylesheetPrecedence).observe(document.head, { childList: true });
    const selector = "*";
    const pending = new Set();
    let scheduled = false;
    const clean = (el) => {
      if (el instanceof SVGElement) return;
      for (const pseudo of [null, "::before", "::after"]) {
        const image = getComputedStyle(el, pseudo).backgroundImage;
        if (!image.includes("gradient(")) continue;
        const filtered = withoutGradients(image);
        if (filtered === image) continue;
        if (pseudo) {
          const side = pseudo.slice(2);
          el.style.setProperty(`--daemon-${side}-image`, filtered);
          el.setAttribute(`data-daemon-flat-${side}`, "");
        } else {
          el.style.setProperty("background-image", filtered, "important");
          el.style.setProperty("background-color", "transparent", "important");
        }
      }
    };
    const schedule = (node, subtree = false) => {
      if (!(node instanceof Element)) return;
      if (node.matches(selector)) pending.add(node);
      if (subtree) for (const el of node.querySelectorAll(selector)) pending.add(el);
      if (scheduled) return;
      scheduled = true;
      requestAnimationFrame(() => {
        scheduled = false;
        const batch = [...pending]; pending.clear();
        for (const el of batch) if (el.isConnected) clean(el);
        syncFullscreenGlass();
      });
    };
    const refreshFullscreen = () => {
      ensureStylesheetPrecedence();
      syncFullscreenGlass();
      schedule(document.body, true);
    };
    document.addEventListener("fullscreenchange", refreshFullscreen);
    document.addEventListener("webkitfullscreenchange", refreshFullscreen);
    window.addEventListener("resize", syncFullscreenGlass);
    schedule(document.body, true);
    new MutationObserver((records) => {
      for (const record of records) {
        if (record.type === "attributes") schedule(record.target);
        else for (const node of record.addedNodes) schedule(node, true);
      }
    }).observe(document.body, { childList: true, subtree: true, attributes: true, attributeFilter: ["style", "class"] });
  }

  // Connect to local SSE event stream with auto-reconnection
  function connectEventStream() {
    if (eventSource) {
      try {
        eventSource.close();
      } catch (e) {}
      eventSource = null;
    }

    try {
      eventSource = new EventSource(EVENTS_URL);

      eventSource.addEventListener("theme", (e) => {
        try {
          const data = JSON.parse(e.data);
          applyPalette(data, false);
        } catch (err) {
          console.error("[DaemonSpotifySync] Error parsing theme event:", err);
        }
      });

      eventSource.onopen = () => {
        if (reconnectTimeout) {
          clearTimeout(reconnectTimeout);
          reconnectTimeout = null;
        }
      };

      eventSource.onerror = () => {
        if (eventSource) {
          try {
            eventSource.close();
          } catch (e) {}
          eventSource = null;
        }
        if (!reconnectTimeout) {
          reconnectTimeout = setTimeout(() => {
            reconnectTimeout = null;
            connectEventStream();
          }, 3500);
        }
      };
    } catch (err) {
      if (!reconnectTimeout) {
        reconnectTimeout = setTimeout(() => {
          reconnectTimeout = null;
          connectEventStream();
        }, 5000);
      }
    }
  }

  // Initial fetch as an immediate guarantee before SSE handshake
  async function fetchInitialTheme() {
    try {
      const res = await fetch(THEME_URL, { cache: "no-store" });
      if (res.ok) {
        const data = await res.json();
        applyPalette(data, false);
      }
    } catch (e) {
      // Bridge may not be up yet; cached palette remains active
    }
  }

  function getActivePalette() {
    try {
      const cached = localStorage.getItem(STORAGE_KEY);
      if (cached) return JSON.parse(cached);
    } catch (e) {}
    return null;
  }

  // 1. Immediately apply cached palette for zero-flash startup
  const initialCache = getActivePalette();
  if (initialCache) {
    applyPalette(initialCache, false);
  }

  // 2. Fetch current active theme from bridge
  fetchInitialTheme();

  // 3. Open real-time SSE listener
  connectEventStream();

  // 4. Keep theme styles last and remove decorative gradients on navigation
  setupStyleEnforcer();

  // Expose global debug / testing API
  window.DaemonSpotifySync = {
    applyPalette: (p) => applyPalette(p, true),
    getPalette: getActivePalette,
    refresh: fetchInitialTheme,
    reconnect: connectEventStream,
  };
})();
