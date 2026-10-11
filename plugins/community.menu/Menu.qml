import "components/polish" as Polish
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.Mpris
import QtQuick
import qs.Commons
import qs.Ui
import "MenuModel.js" as MenuModel

Item {
  id: root

  // Injected by omarchy-shell when this plugin is summoned.
  property string omarchyPath: Quickshell.env("OMARCHY_PATH")
  property var shell: null
  property var manifest: null

  // Plugin lifecycle hooks. The host calls open(payloadJson) after
  // `omarchy-shell shell summon omarchy.menu ...` and close() when hidden.
  property string pendingInitialMenu: "root"

  function open(payloadJson) {
    var payload = ({})
    try { payload = JSON.parse(payloadJson || "{}") } catch (e) { payload = ({}) }

    if (payload.fontFamily) root.fontFamily = payload.fontFamily

    if (payload.mode === "select" || payload.mode === "input") {
      root.openDmenu(payload)
    } else {
      root.openRoute(payload.initialMenu || payload.menu || "root")
    }
  }

  function close() {
    root.cancel()
  }

  function refresh() {
    defaultMenuFile.reload()
    userMenuFile.reload()
    return "ok"
  }

  function ping() { return "ok" }

  property string fontFamily: Style.font.menuFamily
  // JSONC menu definitions. The shell parses both at startup and merges
  // the user file on top of the defaults, so the keybind → IPC → visible
  // path doesn't have to shell out to bash + jq on every open.
  property string defaultMenuPath: omarchyPath + "/default/omarchy/omarchy-menu.jsonc"
  property string userMenuPath: Quickshell.env("HOME") + "/.config/omarchy/extensions/omarchy-menu.jsonc"
  property var defaultMenuItems: []
  property var userMenuItems: []
  property bool opened: false
  property string mode: "menu"
  readonly property bool dmenuActive: mode === "select" || mode === "input"
  property string dmenuPrompt: ""
  property var dmenuOptions: []
  property string selectionFile: ""
  property string doneFile: ""
  property int dmenuWidth: 300
  property int dmenuMaxHeight: 0
  property bool requestActive: false
  property bool rowsLoaded: false
  property string activeMenu: "root"
  property string filterText: ""
  property int selectedIndex: 0
  property bool cursorActive: false
  property int requestSerial: 0
  property int applySerial: 0
  property var items: ({})
  property var itemOrder: []
  property var navStack: []
  property var providersLoaded: ({})
  property var providerQueue: []
  property int providerRevision: 0

  // Shared application engine (entries, hidden filters, icons, launch,
  // removal), owned by the shell and also used by the standalone launcher.
  readonly property var appLibrary: root.shell ? root.shell.appLibrary : null
  property bool deleteConfirmOpen: false
  property var deleteTarget: null
  property bool isPresented: root.opened && (root.dmenuActive || root.rowsLoaded)

  onOpenedChanged: {
    if (!opened) {
      deleteConfirmOpen = false
      deleteTarget = null
    }
  }

  onIsPresentedChanged: {
    if (isPresented) {
      exitAnim.stop()
      entryAnim.restart()
      sweepAnim.restart()
    } else {
      entryAnim.stop()
      exitAnim.restart()
    }
  }

  onActiveMenuChanged: {
    if (typeof searchIconBounce !== "undefined" && searchIconBounce) searchIconBounce.restart()
    if (typeof badgeBounceAnim !== "undefined" && badgeBounceAnim) badgeBounceAnim.restart()
  }

  // Dynamic Animation Engine Integration (Universal Motion Engine Singleton)
  readonly property string currentAnimationStyle: Motion.activePreset
  readonly property int animDuration: Motion.entryDuration
  readonly property var animEasingType: Motion.easeExpressive
  readonly property real animOvershoot: Motion.springOvershoot

  property real entryProgress: 0.0
  property real sweepProgress: 0.0
  property real navSlideOffset: 0.0
  property real navOpacity: 1.0

  NumberAnimation {
    id: entryAnim
    target: root
    property: "entryProgress"
    to: 1.0
    duration: root.animDuration
    easing.type: root.animEasingType
    easing.overshoot: root.animOvershoot
  }

  NumberAnimation {
    id: exitAnim
    target: root; property: "entryProgress"; to: 0
    duration: Polish.MotionAdapter.exitDuration; easing.type: Easing.InQuad
  }

  NumberAnimation {
    id: sweepAnim
    target: root
    property: "sweepProgress"
    from: 0.0
    to: 1.0
    duration: Math.max(1, Math.round(root.animDuration * 2.2))
    easing.type: Motion.easeStandard
  }

  ParallelAnimation {
    id: navAnim
    NumberAnimation {
      target: root
      property: "navSlideOffset"
      to: 0.0
      duration: Motion.standard
      easing.type: Motion.easeStandard
    }
    NumberAnimation {
      target: root
      property: "navOpacity"
      to: 1.0
      duration: Motion.standard
      easing.type: Motion.easeStandard
    }
  }
  // Semantic tokens from universal adaptive Theme
  property color background: Theme.surface
  property color foreground: Theme.textPrimary
  property color border: Theme.borderSubtle
  property var borderSpec: Border.surfaceSpec("menu", "border", border, Math.max(1, Style.space(2)))
  property color scrim: Theme.scrim
  property color selectedBackground: Theme.surfaceSelected
  property color selectedText: Theme.textOnAccent
  property color selectedBorder: Theme.borderFocus
  property var selectedBorderSpec: Border.surfaceSpec("menu", "selected-border", selectedBorder, 0)
  readonly property real rowReservedBorderLeft: Border.left(selectedBorderSpec)
  readonly property real rowReservedBorderRight: Border.right(selectedBorderSpec)
  readonly property int cornerRadius: Theme.radiusLarge
  property int contentMargin: Style.spacing.panelPadding
  property int headerHeight: Math.max(Style.space(42), Style.font.title + Style.spacing.controlPaddingY * 2)
  property int footerHeight: Style.space(26)
  property int contentSpacing: Style.spacing.md
  property int baseRowHeight: Math.max(Style.space(48), Style.font.body + Style.spacing.rowPaddingX * 2)
  property int detailRowHeight: Math.max(Style.space(56), Style.font.body + Style.font.caption + Style.spacing.rowPaddingX * 2)
  // How much of the first hidden row stays visible at the fold — enough to
  // read as a cut-off row rather than a bottom border.
  property int rowPeek: Math.round(baseRowHeight * 0.55)
  property int rowSpacing: Style.spacing.xs
  property int dividerHeight: Style.space(17)
  property bool searchDivider: false
  property int layoutSerial: 0

  readonly property bool showContextDeck: !root.dmenuActive && root.activeMenu === "root" && root.filterText === ""
  readonly property int contextDeckContentHeight: (root.hasMedia ? Style.space(52) + Style.space(8) : 0) + Style.space(34) + Style.space(8) + (Style.space(38) * 2 + Style.space(6))
  readonly property int contextDeckHeight: showContextDeck ? (contextDeckContentHeight + root.contentSpacing) : 0

  property int cardWidth: Math.min(
    root.dmenuActive ? Style.space(Math.max(540, root.dmenuWidth)) : Style.space(580),
    panel.width - Style.gapsOut * 2
  )
  property int visibleRowsHeight: root.dmenuActive ? dmenuRowListHeight(layoutSerial, displayModel.count, filterText) : rowListHeight(layoutSerial, displayModel.count, filterText, searchDivider)
  property int cardHeight: root.dmenuActive
    ? Math.min(contentMargin * 2 + headerHeight + (mode === "input" ? 0 : contentSpacing + visibleRowsHeight) + (mode === "input" ? 0 : footerHeight + Style.space(4)), panel.height - Style.gapsOut * 2)
    : Math.min(contentMargin * 2 + headerHeight + contextDeckHeight + contentSpacing + visibleRowsHeight + footerHeight + Style.space(4), panel.height - Style.gapsOut * 2)

  function finishRequest(selection) {
    if (!root.requestActive || !root.doneFile) {
      root.opened = false
      return
    }

    var activeSelectionFile = root.selectionFile
    var activeDoneFile = root.doneFile
    root.requestActive = false
    root.selectionFile = ""
    root.doneFile = ""

    if (selection === null || selection === undefined) {
      resultProc.command = ["bash", "-c", ": > " + Util.shellQuote(activeDoneFile)]
    } else {
      resultProc.command = ["bash", "-c", "printf '%s\\n' " + Util.shellQuote(selection) + " > " + Util.shellQuote(activeSelectionFile) + "; : > " + Util.shellQuote(activeDoneFile)]
    }
    resultProc.running = true
  }

  function runAction(action) {
    var command = String(action || "")
    if (!command) return

    Util.execDetached(command)
  }

  // Menu rows only surface their detail while a search is narrowing them;
  // dmenu rows carry caller-supplied subtext that must always be visible.
  function rowHeightForDetail(detail) {
    return (root.filterText || root.dmenuActive || root.activeMenu === "bookmarks" || (detail && detail.length > 0)) ? root.detailRowHeight : root.baseRowHeight
  }

  // Height the card can devote to rows before running off the screen — or
  // past the frozen top edge once a search has pinned the card in place.
  // Uses panel.cardTop rather than effectiveCardTop: the centered top is
  // derived from the card height, which this value feeds.
  function availableRowsHeight() {
    var top = panel.cardTop >= 0 ? panel.cardTop : Style.gapsOut
    var available = panel.height - top - Style.gapsOut - root.contentMargin * 2 - root.headerHeight - root.contextDeckHeight - root.contentSpacing - root.footerHeight - Style.space(4)
    // The starting menu sets the ceiling along with the offset: drilling into
    // a longer submenu scrolls behind the fold instead of growing the card.
    if (panel.maxRowsHeight >= 0) available = Math.min(available, panel.maxRowsHeight)
    // A card that swallows the whole screen reads as a page, not a menu.
    return Math.min(available, Math.round(panel.height * (root.showContextDeck ? 0.42 : 0.72)))
  }

  // When every row fits, the list gets its full height. When they don't,
  // the card must end mid-row: a clipped row is what tells the eye there is
  // more below the fold, so never come out even on a row boundary.
  function foldedListHeight(totals, available) {
    var count = totals.length
    if (count === 0) return root.baseRowHeight
    if (totals[count - 1] <= available) return totals[count - 1]

    var peek = root.rowPeek
    var full = 0
    while (full < count && totals[full] <= available) full++
    while (full > 1 && totals[full - 1] + root.rowSpacing + peek > available) full--
    if (full < 1) return Math.max(available, root.baseRowHeight)

    return totals[full - 1] + root.rowSpacing + peek
  }

  function rowListHeight(_serial, _count, _filter, _divider) {
    if (displayModel.count === 0) return root.baseRowHeight

    var totals = []
    var total = 0
    var previousSection = ""

    for (var i = 0; i < displayModel.count; i++) {
      var row = displayModel.get(i)
      if (i > 0) total += root.rowSpacing
      if (row.section === "drilldown" && previousSection !== "drilldown") total += root.dividerHeight
      total += root.rowHeightForDetail(row.detail)
      previousSection = row.section
      totals.push(total)
    }

    return foldedListHeight(totals, availableRowsHeight())
  }

  function dmenuRowListHeight(_serial, _count, _filter) {
    if (root.mode === "input") return 0
    if (displayModel.count === 0) return root.baseRowHeight

    var available = availableRowsHeight()
    if (root.dmenuMaxHeight > 0) available = Math.min(available, Style.space(root.dmenuMaxHeight))

    var totals = []
    var total = 0
    for (var i = 0; i < displayModel.count; i++) {
      if (i > 0) total += root.rowSpacing
      total += root.rowHeightForDetail(displayModel.get(i).detail)
      totals.push(total)
    }

    return foldedListHeight(totals, available)
  }

  function item(id) {
    return root.items[id] || null
  }

  // ------------------------------------------------------------------
  // JSONC → normalized item array. Mirrors the bash bin's jq pipeline so
  // the on-disk authoring format stays untouched.
  // ------------------------------------------------------------------

  function stripJsonc(raw) {
    return MenuModel.stripJsonc(raw)
  }

  function normalizeAliases(value) {
    return MenuModel.normalizeAliases(value)
  }

  function normalizeItem(id, raw) {
    return MenuModel.normalizeItem(id, raw)
  }

  function parseMenuJsonc(raw) {
    return MenuModel.parseMenuJsonc(raw)
  }

  // Merge defaults + user extension. Later entries override earlier ones
  // on a per-key basis (so the user can tweak label/icon/action without
  // re-declaring the whole row).
  function rebuildItemsFromSources() {
    var mergedMenu = MenuModel.mergeMenuSources(root.defaultMenuItems, root.userMenuItems)
    root.providerRevision += 1
    root.providersLoaded = ({})
    root.providerQueue = []
    root.items = mergedMenu.items
    root.itemOrder = mergedMenu.itemOrder
    root.rowsLoaded = true
    root.evaluateGuards()
    if (root.opened) {
      root.rebuildDisplay()
      if (!root.dmenuActive) {
        if (root.filterText.trim()) root.loadProvidersForSearch()
        else root.loadProviderForMenu(root.activeMenu)
      }
    }
  }

  // Each known provider is a tiny bash one-liner that enumerates a list and
  // emits one tab-delimited row per item: `label\tvalue\tcurrent`. The shell
  // turns those into menu items children of `menuId`. A `volatile` provider
  // re-runs every time its submenu is entered, so a font installed since the
  // shell started shows up without restarting it.
  readonly property var providers: ({
    "fonts": {
      script: "current=$(omarchy-font-current 2>/dev/null); omarchy-font-list 2>/dev/null | while read -r f; do [[ -z $f ]] && continue; printf '%s\\t%s\\t%s\\n' \"$f\" \"$f\" \"$current\"; done",
      icon: "",
      volatile: true,
      actionFor: function(value) { return "omarchy-font-set " + Util.shellQuote(value) }
    },
    "power-profiles": {
      script: "current=$(powerprofilesctl get 2>/dev/null); omarchy-powerprofiles-list 2>/dev/null | while read -r p; do [[ -z $p ]] && continue; printf '%s\\t%s\\t%s\\n' \"$p\" \"$p\" \"$current\"; done",
      icon: "\udb81\udc0b",
      actionFor: function(value) { return "omarchy-powerprofiles-set autodetect " + Util.shellQuote(value) }
    },
    "bookmarks": {
      script: "omarchy-menu-bookmarks-list 2>/dev/null",
      icon: "󰃃",
      volatile: true,
      actionFor: function(value) { return "omarchy-launch-browser " + Util.shellQuote(value) }
    }
  })

  function slugify(value) {
    return MenuModel.slugify(value)
  }

  // The apps provider is QML-native: rows come from the shared AppLibrary
  // (DesktopEntries) instead of a bash enumeration, so they carry image
  // icons, launch feedback, and uninstall support like the launcher.
  function mergeAppRows() {
    if (!root.appLibrary) return

    var rows = root.appLibrary.sortedEntries("")
    var appRows = []
    for (var j = 0; j < rows.length; j++) {
      var entry = rows[j].entry
      var appId = String(entry.id || "")
      if (!appId) continue
      var subtext = root.appLibrary.entrySubtext(entry)
      var aliases = subtext ? [subtext] : []
      try {
        if (entry.keywords && typeof entry.keywords.join === "function") aliases = aliases.concat(entry.keywords)
      } catch (e) { }
      appRows.push({
        id: "apps." + appId,
        parent: "apps",
        kind: "app",
        icon: "",
        appIcon: String(entry.icon || ""),
        appId: appId,
        label: root.appLibrary.entryName(entry),
        title: "",
        target: "",
        description: subtext,
        action: "",
        provider: "",
        aliases: aliases,
        when: "",
        checked: "",
        order: 0
      })
    }

    var merged = MenuModel.mergeAppRows(root.items, root.itemOrder, appRows)
    root.items = merged.items
    root.itemOrder = merged.itemOrder
    if (root.opened) root.rebuildDisplay()
  }

  function startProviderForMenu(id) {
    var entry = root.item(id)
    if (!entry || !entry.provider || root.providersLoaded[id]) return
    if (entry.provider === "apps") {
      root.providersLoaded[id] = true
      root.mergeAppRows()
      return
    }
    var spec = root.providers[entry.provider]
    if (!spec) return

    root.providersLoaded[id] = true
    providerProc.menuId = id
    providerProc.providerKey = entry.provider
    providerProc.revision = root.providerRevision
    providerProc.collected = ""
    providerProc.command = ["bash", "-lc", spec.script]
    providerProc.running = true
  }

  function mergeProviderRows(rows, menuId, providerKey) {
    var spec = root.providers[providerKey]
    if (!spec) return
    var lines = String(rows || "").split("\n")
    var providerRows = []
    var takenIds = ({})
    for (var i = 0; i < lines.length; i++) {
      var line = lines[i].trim()
      if (!line) continue
      var parts = line.split("\t")
      var label = parts[0] || ""
      var value = parts[1] || parts[0] || ""
      var current = parts[2] || ""
      var detail = parts[3] || ""
      if (!label) continue
      // Distinct values can slugify alike — Fira Code and Fira-Code both give
      // fira-code — and a repeated id is dropped, which would silently lose a
      // row from the list. Nudge it until it is the row's own.
      var rowId = menuId + "." + root.slugify(value || label)
      while (takenIds[rowId]) rowId += "-"
      takenIds[rowId] = true

      var aliases = []
      if (detail) aliases.push(detail)
      if (value && value !== label) aliases.push(value)

      providerRows.push({
        id: rowId,
        parent: menuId,
        kind: "action",
        icon: (value === current && current) ? "✓" : (spec.icon || ""),
        label: label,
        title: "",
        target: "",
        description: detail || (value.indexOf("http") === 0 ? value : ""),
        action: spec.actionFor(value),
        provider: "",
        aliases: aliases,
        when: "",
        checked: "",
        order: 0
      })
    }
    var merged = MenuModel.swapProviderRows(root.items, root.itemOrder, menuId, providerRows)
    root.items = merged.items
    root.itemOrder = merged.itemOrder
    if (root.opened) root.rebuildDisplay()
  }

  function startNextProvider() {
    if (providerProc.running) return

    while (root.providerQueue.length > 0) {
      var id = root.providerQueue.shift()
      var entry = root.item(id)
      if (!entry || !entry.provider || root.providersLoaded[id]) continue

      root.startProviderForMenu(id)
      return
    }
  }

  // Entering a submenu is the one moment a volatile list is worth paying for
  // again: it may have been reshaped by the last pick from it. Search doesn't
  // invalidate, or every keystroke would restart the same enumeration.
  function invalidateVolatileProvider(id) {
    var entry = root.item(id)
    var spec = entry && entry.provider ? root.providers[entry.provider] : null
    if (spec && spec.volatile) root.providersLoaded[id] = false
  }

  function loadProviderForMenu(id) {
    var entry = root.item(id)
    if (!entry || !entry.provider || root.providersLoaded[id]) return

    // Native providers don't touch providerProc, so they never need to queue.
    if (entry.provider === "apps") {
      root.startProviderForMenu(id)
      return
    }

    if (providerProc.running) {
      if (root.providerQueue.indexOf(id) < 0) root.providerQueue = root.providerQueue.concat([id])
      return
    }

    root.startProviderForMenu(id)
  }

  function loadProvidersForSearch() {
    var active = root.item(root.activeMenu) ? root.activeMenu : "root"

    for (var i = 0; i < root.itemOrder.length; i++) {
      var entry = root.item(root.itemOrder[i])
      if (!entry || !entry.provider || root.providersLoaded[entry.id]) continue
      if (active !== "root" && entry.id !== active && !root.isDescendantOf(entry.id, active)) continue

      root.loadProviderForMenu(entry.id)
    }
  }

  function depthFor(id) {
    return MenuModel.depthFor(root.items, id)
  }

  function pathFor(id) {
    return MenuModel.pathFor(root.items, id)
  }

  function parentPathFor(id) {
    return MenuModel.parentPathFor(root.items, id)
  }

  function isDescendantOf(id, ancestorId) {
    return MenuModel.isDescendantOf(root.items, id, ancestorId)
  }

  function childCount(id) {
    return MenuModel.childCount(root.items, root.itemOrder, id)
  }

  // Guarded items are hidden when their `when:` evaluates false. Static
  // submenus are also hidden when none of their descendants are visible;
  // provider-backed menus stay visible because their rows load on demand.
  function isVisible(entry) {
    return MenuModel.isVisible(root.items, root.itemOrder, root.whenResults, entry)
  }

  // Label with the ✓ marker baked in when `checked:` evaluated truthy.
  function labelFor(entry) {
    return MenuModel.labelFor(entry, root.checkedResults)
  }

  function searchableToken(value) {
    return MenuModel.searchableToken(value)
  }

  function leafIdFor(id) {
    return MenuModel.leafIdFor(id)
  }

  function nameSearchText(entry) {
    return MenuModel.nameSearchText(entry)
  }

  function termInSearchWords(term, text) {
    return MenuModel.termInSearchWords(term, text)
  }

  function descriptionTextMatches(query, text) {
    return MenuModel.descriptionTextMatches(query, text)
  }

  function matchesQuery(entry, query) {
    return MenuModel.matchesQuery(entry, query, root.isVisible(entry))
  }

  function searchScore(entry, query) {
    return MenuModel.searchScore(root.items, entry, query)
  }

  function displayRow(entry, detail, score, section) {
    return MenuModel.displayRow(root.items, root.itemOrder, root.checkedResults, entry, detail, score, section)
  }

  function rebuildDmenuDisplay() {
    displayModel.clear()
    root.searchDivider = false

    if (root.mode === "input") {
      layoutSerial += 1
      return
    }

    var query = root.filterText.trim().toLowerCase()
    for (var i = 0; i < root.dmenuOptions.length; i++) {
      // An option is "<label>", "<glyph>\t<label>", or
      // "<glyph>\t<label>\t<subtext>". The glyph never comes back with the
      // selection; the subtext renders under the label, filters alongside it,
      // and returns with the selection as a stable key for same-named rows.
      var parts = String(root.dmenuOptions[i] || "").split("\t")
      var icon = parts.length > 1 ? parts.shift() : ""
      var label = parts.shift() || ""
      var detail = parts.join("\t")
      if (query && label.toLowerCase().indexOf(query) < 0
          && detail.toLowerCase().indexOf(query) < 0) continue
      displayModel.append({
        itemId: "dmenu." + i,
        kind: "dmenu",
        icon: icon,
        iconFont: "",
        appIcon: "",
        appId: "",
        label: label,
        target: "",
        detail: detail,
        path: "",
        childCount: 0,
        action: "",
        provider: "",
        score: i,
        section: ""
      })
    }

    layoutSerial += 1

    if (displayModel.count === 0) selectedIndex = 0
    else if (selectedIndex >= displayModel.count) selectedIndex = displayModel.count - 1
    else if (selectedIndex < 0) selectedIndex = 0

    Qt.callLater(function() {
      if (displayModel.count > 0) root.revealCursor()
    })
  }

  function rebuildDisplay() {
    if (root.dmenuActive) {
      root.rebuildDmenuDisplay()
      return
    }

    displayModel.clear()

    if (!root.rowsLoaded) return

    var active = root.item(root.activeMenu) ? root.activeMenu : "root"
    root.activeMenu = active
    var rows = []
    var query = root.filterText.trim()
    root.searchDivider = false

    if (query) {
      if (query.charAt(0) === ">") {
        var cmdQuery = query.substring(1).trim().toLowerCase()
        var builtins = [
          { id: "cmd.lock", label: "Lock Screen", detail: "hyprlock — lock workstation session", icon: "󰌾", action: "hyprlock" },
          { id: "cmd.sleep", label: "Suspend System", detail: "systemctl suspend — low power standby", icon: "󰒲", action: "systemctl suspend" },
          { id: "cmd.reboot", label: "Reboot System", detail: "systemctl reboot — clean restart", icon: "󰜉", action: "systemctl reboot" },
          { id: "cmd.shutdown", label: "Power Off", detail: "systemctl poweroff — safe shutdown", icon: "󰐥", action: "systemctl poweroff" },
          { id: "cmd.sync", label: "Run Cloud Backup Sync", detail: "omarchy-cloud-sync sync — synchronize with Google Drive", icon: "󰄲", action: "omarchy-cloud-sync sync" },
          { id: "cmd.sync_health", label: "Backup Health & Quota Report", detail: "omarchy-backup-health.sh — check integrity and space", icon: "󰋊", action: "omarchy-launch-terminal $HOME/Work/bin/omarchy-backup-health.sh" },
          { id: "cmd.study_start", label: "Start Study Focus (25m)", detail: "omarchy-study-focus start 25 — strict whitelist session", icon: "󰑋", action: "omarchy-study-focus start 25" },
          { id: "cmd.study_stop", label: "Stop Study Focus", detail: "omarchy-study-focus stop — restore full access", icon: "󰈅", action: "omarchy-study-focus stop" },
          { id: "cmd.study_menu", label: "Study & Focus Manager", detail: "omarchy-study-focus menu — manage whitelists and sessions", icon: "󰑊", action: "omarchy-study-focus menu" },
          { id: "cmd.theme", label: "Switch Theme", detail: "Browse and preview installed themes", icon: "󰏘", action: "omarchy-theme-picker", kind: "action" },
          { id: "cmd.wallpaper", label: "Live Wallpapers", detail: "Select dynamic animated video wallpapers", icon: "󰸉", target: "livewallpapers", kind: "menu" },
          { id: "cmd.terminal", label: "Open Terminal", detail: "omarchy-launch-terminal", icon: "󰞷", action: "omarchy-launch-terminal" },
          { id: "cmd.browser", label: "Launch Browser", detail: "omarchy-launch-browser", icon: "󰈹", action: "omarchy-launch-browser" },
          { id: "cmd.scratchpad", label: "Toggle Scratchpad", detail: "hypr-toggle-window scratchpad", icon: "󱂬", action: "hypr-toggle-window scratchpad" },
          { id: "cmd.ai", label: "Omarchy AI Assistant", detail: "omarchy-agent — interactive coding agent", icon: "󰚩", action: "omarchy-agent" }
        ]
        for (var c = 0; c < builtins.length; c++) {
          var b = builtins[c]
          if (!cmdQuery || b.label.toLowerCase().indexOf(cmdQuery) >= 0 || b.detail.toLowerCase().indexOf(cmdQuery) >= 0) {
            rows.push({
              itemId: b.id,
              kind: b.kind || "action",
              icon: b.icon,
              iconFont: "",
              appIcon: "",
              appId: "",
              label: b.label,
              target: b.target || "",
              detail: b.detail,
              path: "> " + b.label,
              childCount: 0,
              action: b.action || "",
              provider: "",
              score: c,
              section: "command"
            })
          }
        }
      } else {
        var currentRows = []
        var drilldownRows = []

        for (var i = 0; i < root.itemOrder.length; i++) {
          var entry = root.item(root.itemOrder[i])
          if (!entry || entry.id === "root") continue
          if (!root.isDescendantOf(entry.id, active)) continue
          if (!root.matchesQuery(entry, query)) continue

          var detail = root.parentPathFor(entry.id)
          var row = root.displayRow(entry, detail, root.searchScore(entry, query))
          if (entry.parent === active) currentRows.push(row)
          else drilldownRows.push(row)
        }

        var searchSort = function(a, b) {
          if (a.score !== b.score) return a.score - b.score
          return a.path.localeCompare(b.path)
        }

        currentRows.sort(searchSort)
        drilldownRows.sort(searchSort)
        root.searchDivider = currentRows.length > 0 && drilldownRows.length > 0
        if (root.searchDivider) {
          for (var d = 0; d < drilldownRows.length; d++) drilldownRows[d].section = "drilldown"
        }
        rows = currentRows.concat(drilldownRows)
      }
    } else {
      for (var j = 0; j < root.itemOrder.length; j++) {
        var child = root.item(root.itemOrder[j])
        if (!child || child.parent !== active) continue
        if (!root.isVisible(child)) continue
        rows.push(root.displayRow(child, child.description, child.order))
      }

      // DesktopEntries can reorder its values when an application starts.
      // Keep the Apps menu alphabetical independently of provider refreshes.
      if (active === "apps") {
        rows.sort(function(a, b) {
          var aLabel = String(a.label || "").toLowerCase()
          var bLabel = String(b.label || "").toLowerCase()
          if (aLabel < bLabel) return -1
          if (aLabel > bLabel) return 1
          var aId = String(a.itemId || "")
          var bId = String(b.itemId || "")
          if (aId < bId) return -1
          if (aId > bId) return 1
          return 0
        })
      }
    }

    for (var k = 0; k < rows.length; k++) displayModel.append(rows[k])
    layoutSerial += 1

    if (displayModel.count === 0) selectedIndex = 0
    else if (selectedIndex >= displayModel.count) selectedIndex = displayModel.count - 1
    else if (selectedIndex < 0) selectedIndex = 0

    Qt.callLater(function() {
      if (displayModel.count > 0) root.revealCursor()
    })
  }

  // Contain alone parks the cursor row flush with the viewport edge, hiding
  // the neighbor entirely and losing the fold affordance. Keep the next
  // hidden row peeking past the cursor in the direction of travel.
  function revealCursor() {
    if (displayModel.count === 0) return
    resultList.positionViewAtIndex(root.selectedIndex, ListView.Contain)

    var item = resultList.itemAtIndex(root.selectedIndex)
    if (!item) return

    var reach = root.rowPeek + root.rowSpacing
    if (root.selectedIndex < displayModel.count - 1) {
      var maxY = Math.max(resultList.originY, resultList.originY + resultList.contentHeight - resultList.height)
      var overhang = item.y + item.height + reach - (resultList.contentY + resultList.height)
      if (overhang > 0) resultList.contentY = Math.min(resultList.contentY + overhang, maxY)
    }
    if (root.selectedIndex > 0) {
      var underhang = resultList.contentY - (item.y - reach)
      if (underhang > 0) resultList.contentY = Math.max(resultList.contentY - underhang, resultList.originY)
    }
  }

  function select(delta) {
    if (displayModel.count === 0) return

    root.disarmPointer()
    if (!cursorActive) {
      cursorActive = true
      selectedIndex = delta < 0 ? displayModel.count - 1 : 0
    } else {
      selectedIndex = (selectedIndex + delta + displayModel.count) % displayModel.count
    }
    revealCursor()
  }

  function setFilter(nextFilter) {
    panel.freezeCardTop()
    root.filterText = nextFilter
    root.selectedIndex = 0
    root.cursorActive = root.mode !== "input"
    root.disarmPointer()
    if (!root.dmenuActive && root.filterText.trim()) root.loadProvidersForSearch()
    root.rebuildDisplay()
  }

  function setActiveMenu(id, pushHistory, fromPointer) {
    panel.freezeCardTop()
    if (!root.item(id)) id = "root"
    if (pushHistory && id !== root.activeMenu) root.navStack = root.navStack.concat([root.activeMenu])
    root.activeMenu = id
    root.filterText = ""
    root.selectedIndex = 0
    root.cursorActive = true
    if (fromPointer) pointerGate.allowInitialSample()
    else root.disarmPointer()
    root.rebuildDisplay()
    root.invalidateVolatileProvider(id)
    root.loadProviderForMenu(id)

    if (pushHistory) {
      root.navSlideOffset = 18
      root.navOpacity = 0.35
      navAnim.restart()
    }
  }

  function goBack() {
    if (root.activeMenu === "root") return false

    root.navSlideOffset = -18
    root.navOpacity = 0.35
    navAnim.restart()

    if (root.navStack.length > 0) {
      var previous = root.navStack[root.navStack.length - 1]
      root.navStack = root.navStack.slice(0, root.navStack.length - 1)
      root.setActiveMenu(previous, false)
      return true
    }

    var active = root.item(root.activeMenu)
    root.setActiveMenu((active && active.parent) ? active.parent : "root", false)
    return true
  }

  function activateIndex(index, fromPointer) {
    if (root.deleteConfirmOpen) return
    if (root.dmenuActive) {
      if (root.mode === "input") {
        root.applyDmenuSelection(root.filterText)
        return
      }
      if (index < 0 || index >= displayModel.count) return
      var picked = displayModel.get(index)
      root.applyDmenuSelection(picked.detail ? picked.label + "\t" + picked.detail : picked.label)
      return
    }

    if (index < 0 || index >= displayModel.count) return

    var row = displayModel.get(index)
    if (row.kind === "menu" || row.kind === "link") {
      root.setActiveMenu(row.target || row.itemId, true, fromPointer)
    } else if (row.kind === "app") {
      var appId = row.appId
      var label = row.label
      applySerial = requestSerial
      opened = false
      if (root.appLibrary) root.appLibrary.launch(appId, label)
    } else {
      root.applySelected(row.itemId, row.action)
    }
  }

  function requestDeleteSelected() {
    if (!root.cursorActive || root.selectedIndex < 0 || root.selectedIndex >= displayModel.count) return
    var row = displayModel.get(root.selectedIndex)
    if (!row || row.kind !== "app") return
    root.deleteTarget = { appId: row.appId, label: row.label }
    deleteConfirm.selectedIndex = 1
    root.deleteConfirmOpen = true
  }

  function cancelDelete() {
    root.deleteConfirmOpen = false
    root.deleteTarget = null
    deleteConfirm.selectedIndex = 1
    root.disarmPointer()
    Qt.callLater(function() { keyCatcher.forceActiveFocus() })
  }

  function confirmDelete() {
    var target = root.deleteTarget
    root.deleteConfirmOpen = false
    root.deleteTarget = null
    if (!target) return
    root.cancel()
    if (root.appLibrary) root.appLibrary.remove(target.appId, target.label)
  }

  function applyDmenuSelection(value) {
    applySerial = requestSerial
    opened = false
    root.finishRequest(value)
  }

  function applySelected(id, action) {
    if (!id) { cancel(); return }

    applySerial = requestSerial
    opened = false
    root.runAction(action)
  }

  function cancel() {
    if (root.dmenuActive) root.finishRequest(null)
    opened = false
  }

  function openExistingMenu(initialMenu) {
    requestSerial += 1
    mode = "menu"
    requestActive = false
    selectionFile = ""
    doneFile = ""
    activeMenu = root.item(initialMenu) ? initialMenu : "root"
    navStack = []
    filterText = ""
    selectedIndex = 0
    cursorActive = true
    root.disarmPointer()
    root.evaluateGuards()
    opened = true
    rebuildDisplay()
    invalidateVolatileProvider(activeMenu)
    loadProviderForMenu(activeMenu)
    // The shell may start before first-install packages have finished placing
    // their icons. Refresh here even when the desktop entry list did not change.
    if (root.appLibrary) root.appLibrary.refreshIcons()

    Qt.callLater(function() { keyCatcher.forceActiveFocus() })
  }

  function openDmenu(payload) {
    requestSerial += 1
    mode = payload.mode === "input" ? "input" : "select"
    dmenuPrompt = String(payload.prompt || (mode === "input" ? "Input" : "Select"))
    dmenuOptions = Array.isArray(payload.options) ? payload.options : []
    selectionFile = String(payload.selectionFile || "")
    doneFile = String(payload.doneFile || "")
    requestActive = !!doneFile
    dmenuWidth = Math.max(1, Number(payload.width || 300))
    dmenuMaxHeight = Math.max(0, Number(payload.maxHeight || 0))
    activeMenu = "root"
    navStack = []
    filterText = ""
    selectedIndex = 0
    cursorActive = mode !== "input"
    root.disarmPointer()
    opened = true
    rebuildDisplay()

    Qt.callLater(function() { keyCatcher.forceActiveFocus() })
  }
  ListModel { id: displayModel }

  // ----------------------------------------------------------- route surface
  //
  // The menu is opened through the standard plugin lifecycle:
  // `omarchy-shell shell summon omarchy.menu '{"menu":"system"}'`.
  // Callers may pass a real id (`system`, `setup.power`) or an alias declared
  // in JSONC (`power`, `reminder-set`). Unknown strings fall through to the
  // id-as-route behavior so misspellings still attempt to open the literal id.
  function resolveRoute(input) {
    return MenuModel.resolveRoute(root.items, root.itemOrder, input)
  }

  function openRoute(initialMenu) {
    var id = root.resolveRoute(initialMenu)
    var entry = root.items[id]
    // If the resolved id is an action (i.e. the user invoked an alias for
    // a leaf, e.g. `omarchy menu summon screenrecord-stop`), run it directly
    // instead of opening an action with no children.
    if (entry && entry.kind === "action" && entry.action) {
      root.cancel()
      root.runAction(entry.action)
      return "ok"
    }
    // If it's a link (a redirect to another menu), follow the link.
    if (entry && entry.kind === "link" && entry.target) id = entry.target
    root.pendingInitialMenu = id
    root.openExistingMenu(id)
    return "ok"
  }

  function disarmPointer() {
    pointerGate.reset()
  }

  function selectFromPointer(index, item, mouse) {
    if (!pointerGate.moved(item, mouse)) return
    root.cursorActive = true
    root.selectedIndex = index
  }

  Process {
    id: providerProc
    property string menuId: ""
    property string providerKey: ""
    property string collected: ""
    property int revision: 0
    stdout: SplitParser {
      onRead: function(data) { providerProc.collected += data + "\n" }
    }
    onExited: {
      if (providerProc.revision === root.providerRevision) {
        root.mergeProviderRows(providerProc.collected, providerProc.menuId, providerProc.providerKey)
        if (root.filterText.trim()) root.loadProvidersForSearch()
      }
      root.startNextProvider()
    }
  }

  Process {
    id: resultProc
    onExited: {
      if (root.applySerial === root.requestSerial)
        root.opened = false
    }
  }

  PointerMoveGate {
    id: pointerGate
    referenceItem: card
  }

  Connections {
    target: root.appLibrary
    function onAppsChanged() {
      if (root.providersLoaded["apps"]) root.mergeAppRows()
    }
  }

  // The JSONC sources are watched so live edits to the default file (or the
  // user extension at ~/.config/omarchy/extensions/omarchy-menu.jsonc) take
  // effect without restarting the shell.
  FileView {
    id: defaultMenuFile
    path: root.defaultMenuPath
    watchChanges: true
    printErrors: false
    onLoaded: { root.defaultMenuItems = root.parseMenuJsonc(text()); root.rebuildItemsFromSources() }
    onFileChanged: reload()
  }

  FileView {
    id: userMenuFile
    path: root.userMenuPath
    watchChanges: true
    printErrors: false
    onLoaded: { root.userMenuItems = root.parseMenuJsonc(text()); root.rebuildItemsFromSources() }
    onLoadFailed: { root.userMenuItems = []; root.rebuildItemsFromSources() }
    onFileChanged: reload()
  }

  // -------------------------------------------------------------
  // Command Deck State Subsystems (Cloud Sync, Study Focus, Media)
  // -------------------------------------------------------------
  property var cloudSyncData: null
  property var studyModeData: null

  FileView {
    id: cloudSyncStateFile
    path: Quickshell.env("XDG_RUNTIME_DIR") + "/omarchy-cloud-sync/state.json"
    watchChanges: true
    printErrors: false
    onLoaded: {
      try { root.cloudSyncData = JSON.parse(text()) } catch (e) { root.cloudSyncData = null }
    }
    onFileChanged: reload()
  }

  FileView {
    id: studyModeStateFile
    path: Quickshell.env("XDG_RUNTIME_DIR") + "/omarchy-study-mode/state.json"
    watchChanges: true
    printErrors: false
    onLoaded: {
      try { root.studyModeData = JSON.parse(text()) } catch (e) { root.studyModeData = null }
    }
    onFileChanged: reload()
  }

  Timer {
    interval: 2000
    repeat: true
    running: root.opened && root.showContextDeck
    onTriggered: {
      cloudSyncStateFile.reload()
      studyModeStateFile.reload()
    }
  }

  readonly property var mediaService: root.shell ? root.shell.firstPartyServiceFor("omarchy.media") : null
  readonly property var activePlayer: mediaService ? mediaService.activePlayer : ((typeof Mpris !== "undefined" && Mpris.players && Mpris.players.values.length > 0) ? Mpris.players.values[0] : null)
  readonly property bool hasMedia: mediaService ? mediaService.hasMedia : (activePlayer !== null && (activePlayer.trackTitle || activePlayer.trackArtist))
  readonly property bool isMediaPlaying: activePlayer ? !!activePlayer.isPlaying : false
  readonly property string mediaTitle: mediaService ? (mediaService.title || "") : (activePlayer ? (activePlayer.trackTitle || "") : "")
  readonly property string mediaArtist: mediaService ? (mediaService.artist || "") : (activePlayer ? (activePlayer.trackArtist || "") : "")
  readonly property string mediaArtUrl: mediaService ? (mediaService.artUrl || "") : (activePlayer ? (activePlayer.trackArtUrl || "") : "")

  // ---------------------------------------------------------------- guards
  //
  // `when:` (visibility) and `checked:` (✓ marker) are bash expressions the
  // shell wasn't allowed to evaluate before the perf rewrite. Now the shell
  // batches them into one bash subprocess per (re)load so the open path
  // never has to wait on them.

  property var whenResults: ({})       // id → true|false (allow visibility)
  property var checkedResults: ({})    // id → true|false (show ✓)
  property bool guardsPending: false

  function evaluateGuards() {
    // Process ignores a command change while it is running, and `collected`
    // belongs to the run in flight, so a second evaluation cannot overwrite
    // the first: it would throw away the lines already read and never start.
    // The surviving tail then lands as the whole answer, and every id lost
    // with it goes back to showing, since a `when:` only hides on an explicit
    // false. Wait for the run in flight and evaluate once it lands instead.
    if (guardProc.running) {
      root.guardsPending = true
      return
    }
    root.guardsPending = false

    var script = MenuModel.guardScript(root.items)
    if (!script) {
      root.whenResults = ({})
      root.checkedResults = ({})
      return
    }
    guardProc.collected = ""
    guardProc.command = ["bash", "-lc", script]
    guardProc.running = true
  }

  Process {
    id: guardProc
    property string collected: ""
    stdout: SplitParser {
      onRead: function(data) { guardProc.collected += data + "\n" }
    }
    onExited: function(exitCode, exitStatus) {
      // A batch that was killed rather than finished has only told us about
      // the rows it reached, and a row whose `when:` went unanswered shows.
      // Keep the last complete set rather than let a half-read one through.
      // A signal leaves the exit code at 0, so the status is what tells us.
      if (exitCode !== 0 || exitStatus !== 0) {
        if (root.guardsPending) Qt.callLater(function() { root.evaluateGuards() })
        return
      }

      var nextWhen = ({})
      var nextChecked = ({})
      var lines = guardProc.collected.split("\n")
      for (var i = 0; i < lines.length; i++) {
        var line = lines[i].trim()
        if (!line) continue
        var colon = line.lastIndexOf(":")
        if (colon < 0) continue
        var value = line.substring(colon + 1) === "1"
        var rest = line.substring(0, colon)
        var tagAt = rest.lastIndexOf(":")
        if (tagAt < 0) continue
        var id = rest.substring(0, tagAt)
        var tag = rest.substring(tagAt + 1)
        if (tag === "w") nextWhen[id] = value
        else if (tag === "c") nextChecked[id] = value
      }
      root.whenResults = nextWhen
      root.checkedResults = nextChecked
      if (root.opened) root.rebuildDisplay()
      // Run the evaluation that had to stand aside. Deferred by a turn so the
      // process is settled before its command is set again.
      if (root.guardsPending) Qt.callLater(function() { root.evaluateGuards() })
    }
  }
  PanelWindow {
    id: panel
    visible: root.isPresented || root.entryProgress > 0
    anchors { top: true; bottom: true; left: true; right: true }
    color: "transparent"
    WlrLayershell.namespace: "omarchy-menu"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: root.isPresented ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    exclusionMode: ExclusionMode.Ignore
    mask: Region { width: root.isPresented ? panel.width : 0; height: root.isPresented ? panel.height : 0 }

    // The card opens centered exactly as always. The first search keystroke
    // or submenu move freezes the top line where it currently sits — from
    // then on the card grows and shrinks downward instead of re-centering
    // on every resize, which made the menu jump around. The rows height is
    // frozen at the same moment, so the starting menu also caps how tall the
    // card may grow from there. Closing unfreezes both.
    property int cardTop: -1
    property int maxRowsHeight: -1
    readonly property int centeredTop: Math.max(Style.gapsOut, Math.round((height - root.cardHeight) / 2))
    readonly property int effectiveCardTop: cardTop >= 0 ? cardTop : centeredTop
    function freezeCardTop() {
      if (visible && cardTop < 0) {
        cardTop = effectiveCardTop
        maxRowsHeight = root.visibleRowsHeight
      }
    }
    onVisibleChanged: if (!visible) { cardTop = -1; maxRowsHeight = -1 }

    Rectangle {
      anchors.fill: parent
      color: root.scrim
      opacity: Math.max(0, Math.min(1, root.entryProgress))
    }

    MouseArea {
      anchors.fill: parent
      onClicked: root.cancel()
    }

    BorderSurface {
      id: card
      width: root.cardWidth
      height: Math.min(root.cardHeight, panel.height - Style.gapsOut - panel.effectiveCardTop)
      radius: root.cornerRadius
      x: Math.round((parent.width - width) / 2) + (1 - root.entryProgress) * Polish.MotionAdapter.entryXOffset
      transformOrigin: (Motion.activePreset === "bloom") ? Item.Center : ((Motion.activePreset === "ignition") ? Item.Bottom : Item.Top)
      y: panel.visible
        ? (panel.effectiveCardTop + Math.round((1.0 - root.entryProgress) * Polish.MotionAdapter.entryYOffset))
        : (panel.effectiveCardTop + Polish.MotionAdapter.entryYOffset)
      scale: panel.visible
        ? (Polish.MotionAdapter.entryScaleStart + (1.0 - Polish.MotionAdapter.entryScaleStart) * root.entryProgress)
        : Polish.MotionAdapter.entryScaleStart
      opacity: panel.visible ? Math.min(1.0, root.entryProgress * 1.3) : 0.0
      color: root.background
      borderSpec: root.borderSpec
      padding: root.contentMargin

      Behavior on width {
        NumberAnimation { duration: Motion.standard; easing.type: Motion.easeStandard }
      }
      Behavior on height {
        NumberAnimation { duration: Motion.standard; easing.type: Motion.easeStandard }
      }

      MouseArea { anchors.fill: parent; onClicked: {} }

      // High-Tech Accent Laser Shimmer Streak
      Rectangle {
        id: laserSweep
        height: 2
        width: Style.space(120)
        radius: 1
        anchors.top: parent.top
        anchors.topMargin: -1
        gradient: Gradient {
          orientation: Gradient.Horizontal
          GradientStop { position: 0.0; color: "transparent" }
          GradientStop { position: 0.5; color: Color.accent || root.selectedText }
          GradientStop { position: 1.0; color: "transparent" }
        }
        opacity: (1.0 - root.sweepProgress) * 0.95
        x: -width + (card.width + width * 2) * root.sweepProgress
        visible: root.isPresented && root.sweepProgress < 0.99
      }

      Item {
        id: keyCatcher
        anchors.fill: parent
        z: root.deleteConfirmOpen ? 20 : 0
        focus: true

        Keys.priority: Keys.BeforeItem
        Keys.onPressed: function(event) {
          if (root.deleteConfirmOpen) {
            if (deleteConfirm.handleKey(event)) event.accepted = true
            return
          }

          if (event.key === Qt.Key_Delete) {
            root.requestDeleteSelected()
            event.accepted = true
          } else if (event.key === Qt.Key_Escape) {
            if (root.filterText) root.setFilter("")
            else root.cancel()
            event.accepted = true
          } else if (Util.editsFilter(event, root.filterText)) {
            root.setFilter(Util.editedFilter(event, root.filterText))
            event.accepted = true
          } else if ((event.key === Qt.Key_Backspace || event.key === Qt.Key_Left) && !root.filterText) {
            root.goBack()
            event.accepted = true
          } else if (event.key === Qt.Key_Up) {
            root.select(-1)
            event.accepted = true
          } else if (event.key === Qt.Key_Down) {
            root.select(1)
            event.accepted = true
          } else if (event.key === Qt.Key_PageUp) {
            root.select(-6)
            event.accepted = true
          } else if (event.key === Qt.Key_PageDown) {
            root.select(6)
            event.accepted = true
          } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Right) {
            if (root.dmenuActive) {
              if (root.mode === "input") root.applyDmenuSelection(root.filterText)
              else if (displayModel.count > 0) root.activateIndex(root.cursorActive ? root.selectedIndex : 0)
            } else if (root.cursorActive) root.activateIndex(root.selectedIndex)
            else if (displayModel.count > 0) root.cursorActive = true
            event.accepted = true
          } else if (event.text && event.text.length === 1 && event.text.charCodeAt(0) >= 32 && event.text.charCodeAt(0) !== 127 && (event.modifiers === Qt.NoModifier || event.modifiers === Qt.ShiftModifier)) {
            root.setFilter(root.filterText + event.text)
            event.accepted = true
          }
        }

        ConfirmDialog {
          id: deleteConfirm

          anchors.fill: parent
          opened: root.deleteConfirmOpen
          z: 10
          message: "Do you want to uninstall " + ((root.deleteTarget && root.deleteTarget.label) || "") + "?"
          confirmText: "Uninstall"
          background: root.background
          foreground: root.foreground
          scrim: root.scrim
          selectedBackground: root.selectedBackground
          selectedText: root.selectedText
          fontFamily: root.fontFamily
          cornerRadius: root.cornerRadius
          onCanceled: root.cancelDelete()
          onConfirmed: root.confirmDelete()
        }
      }

      Column {
        anchors.fill: parent
        anchors.topMargin: card.contentTopInset
        anchors.rightMargin: card.contentRightInset
        anchors.bottomMargin: card.contentBottomInset
        anchors.leftMargin: card.contentLeftInset
        spacing: root.contentSpacing

        // Search & Header Box (Command Ignition Engine)
        Rectangle {
          id: searchBox
          width: parent.width
          height: root.headerHeight
          radius: Theme.radiusMedium
          color: Theme.surfaceElevated
          border.width: root.filterText.startsWith(">") ? 1.5 : 1
          border.color: root.filterText.startsWith(">") ? Theme.accent : (root.filterText ? Theme.borderFocus : Theme.borderSubtle)
          clip: true

          Behavior on border.color {
            ColorAnimation { duration: Motion.micro }
          }
          Behavior on border.width {
            NumberAnimation { duration: Motion.micro }
          }

          // Command Ignition Bottom Accent Beam
          Rectangle {
            id: ignitionBar
            anchors.bottom: parent.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            height: root.filterText.startsWith(">") ? Style.space(2) : 0
            color: Theme.accent
            opacity: root.filterText.startsWith(">") ? 0.95 : 0.0

            Behavior on height {
              NumberAnimation { duration: Motion.micro; easing.type: Motion.easeExpressive }
            }
            Behavior on opacity {
              NumberAnimation { duration: Motion.micro }
            }
          }

          Row {
            anchors.left: parent.left
            anchors.leftMargin: Style.space(12)
            anchors.right: badgeArea.left
            anchors.rightMargin: Style.space(8)
            anchors.verticalCenter: parent.verticalCenter
            spacing: Style.space(10)

            Text {
              id: searchIconText
              anchors.verticalCenter: parent.verticalCenter
              text: root.filterText ? (root.filterText.startsWith(">") ? "󰅂" : "󰍉") : (root.activeMenu === "bookmarks" ? "󰃃" : (root.activeMenu === "apps" ? "󰀻" : "󰍉"))
              color: root.filterText ? Theme.accent : Theme.textSecondary
              opacity: root.filterText ? 1.0 : 0.6
              font.family: root.fontFamily
              font.pixelSize: Style.font.iconLarge
              scale: 1.0

              NumberAnimation on scale {
                id: searchIconBounce
                from: 0.65
                to: 1.0
                duration: Motion.standard
                easing.type: Motion.easeExpressive
                easing.overshoot: Motion.springOvershoot
              }
            }

            Item {
              height: parent.height
              width: parent.width - Style.space(34)
              anchors.verticalCenter: parent.verticalCenter

              Row {
                anchors.verticalCenter: parent.verticalCenter
                spacing: Style.space(2)

                Text {
                  id: headerPromptText
                  text: root.filterText || (root.dmenuActive ? (root.dmenuPrompt + "…") : ((root.item(root.activeMenu) ? (root.item(root.activeMenu).title || root.item(root.activeMenu).label) : "Search commands or type >") + "…"))
                  color: Theme.textPrimary
                  opacity: root.filterText ? 1.0 : 0.45
                  font.family: root.fontFamily
                  font.pixelSize: Style.font.heading
                  font.weight: root.filterText ? Font.Medium : Font.Normal
                  elide: Text.ElideRight
                }

                Rectangle {
                  id: cursorBlink
                  width: Style.space(2)
                  height: Style.font.heading + Style.space(2)
                  color: Theme.accent
                  anchors.verticalCenter: parent.verticalCenter
                  visible: root.opened
                  Timer {
                    id: cursorTimer
                    interval: 530
                    repeat: true
                    running: root.opened
                    onTriggered: cursorBlink.visible = !cursorBlink.visible
                  }
                }
              }
            }
          }

          Row {
            id: badgeArea
            anchors.right: parent.right
            anchors.rightMargin: Style.space(10)
            anchors.verticalCenter: parent.verticalCenter
            spacing: Style.space(6)

            Rectangle {
              id: commandBadge
              visible: opacity > 0
              opacity: root.filterText.startsWith(">") ? 1.0 : 0.0
              scale: root.filterText.startsWith(">") ? 1.0 : 0.7
              height: Style.space(22)
              width: commandBadgeText.implicitWidth + Style.space(14)
              radius: Style.space(4)
              color: Theme.accentSoft
              border.width: 1
              border.color: Theme.borderFocus
              anchors.verticalCenter: parent.verticalCenter

              Behavior on opacity {
                NumberAnimation { duration: Motion.micro; easing.type: Motion.easeMicro }
              }
              Behavior on scale {
                NumberAnimation { duration: Motion.standard; easing.type: Motion.easeExpressive; easing.overshoot: Motion.springOvershoot }
              }

              Text {
                id: commandBadgeText
                anchors.centerIn: parent
                text: "COMMAND DECK"
                color: Theme.accent
                font.family: root.fontFamily
                font.pixelSize: Style.font.caption
                font.weight: Font.Bold
              }
            }

            Rectangle {
              id: breadcrumbBadge
              visible: root.activeMenu !== "root" && !root.dmenuActive
              height: Style.space(22)
              width: breadcrumbText.implicitWidth + Style.space(14)
              radius: Style.space(4)
              color: Theme.accentSoft
              border.width: 1
              border.color: Theme.borderFocus
              anchors.verticalCenter: parent.verticalCenter
              scale: 1.0

              NumberAnimation on scale {
                id: badgeBounceAnim
                from: 0.6
                to: 1.0
                duration: Motion.standard
                easing.type: Motion.easeExpressive
                easing.overshoot: Motion.springOvershoot
              }

              Text {
                id: breadcrumbText
                anchors.centerIn: parent
                text: (root.item(root.activeMenu) ? root.item(root.activeMenu).label : root.activeMenu)
                color: Theme.accent
                font.family: root.fontFamily
                font.pixelSize: Style.font.caption
                font.weight: Font.DemiBold
              }
            }

            Rectangle {
              visible: displayModel.count > 0 && root.filterText.length > 0
              height: Style.space(22)
              width: countText.implicitWidth + Style.space(12)
              radius: Style.space(4)
              color: Theme.surfaceElevated
              border.width: 1
              border.color: Theme.borderSubtle
              anchors.verticalCenter: parent.verticalCenter

              Text {
                id: countText
                anchors.centerIn: parent
                text: displayModel.count + " found"
                color: Theme.textSecondary
                font.family: root.fontFamily
                font.pixelSize: Style.font.caption
              }
            }
          }
        }

        // =========================================================
        // ZERO-STATE CONTEXT DECK (Visible on root menu with no search)
        // =========================================================
        Column {
          id: contextDeck
          width: parent.width
          readonly property int deckHeight: root.contextDeckContentHeight
          height: root.showContextDeck ? deckHeight : 0
          visible: root.showContextDeck || opacity > 0
          opacity: root.showContextDeck ? 1.0 : 0.0
          spacing: Style.space(8)
          clip: true

          Behavior on height {
            NumberAnimation { duration: Motion.standard; easing.type: Motion.easeStandard }
          }
          Behavior on opacity {
            NumberAnimation { duration: Motion.micro; easing.type: Motion.easeMicro }
          }

          // 1. HERO: Now Playing Card (Collapses when no active media)
          Rectangle {
            id: nowPlayingCard
            width: parent.width
            height: root.hasMedia ? Style.space(52) : 0
            visible: root.hasMedia
            radius: Theme.radiusMedium
            color: Theme.surfaceElevated
            border.width: 1
            border.color: Theme.borderSubtle
            clip: true

            Behavior on height {
              NumberAnimation { duration: Theme.standard; easing.type: Theme.easeStandard }
            }

            Row {
              anchors.fill: parent
              anchors.margins: Style.space(8)
              spacing: Style.space(10)

              // Album Art or Equalizer Glyph
              Rectangle {
                width: Style.space(36)
                height: Style.space(36)
                radius: Theme.radiusSmall
                color: Theme.accentSoft
                clip: true
                anchors.verticalCenter: parent.verticalCenter

                Image {
                  id: artImg
                  anchors.fill: parent
                  fillMode: Image.PreserveAspectCrop
                  source: root.mediaArtUrl
                  visible: status === Image.Ready
                }

                Text {
                  anchors.centerIn: parent
                  visible: !artImg.visible
                  text: root.isMediaPlaying ? "󰎆" : "󰐊"
                  color: Theme.accent
                  font.family: root.fontFamily
                  font.pixelSize: Style.font.iconLarge
                }
              }

              // Track Info
              Column {
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width - Style.space(36) - mediaControlsRow.width - Style.space(30)
                spacing: Style.space(2)

                Text {
                  width: parent.width
                  text: root.mediaTitle || "Now Playing"
                  color: Theme.textPrimary
                  font.family: root.fontFamily
                  font.pixelSize: Style.font.body
                  font.weight: Font.DemiBold
                  elide: Text.ElideRight
                }

                Text {
                  width: parent.width
                  text: root.mediaArtist || (root.activePlayer ? (root.activePlayer.identity || "Media Player") : "")
                  color: Theme.textSecondary
                  font.family: root.fontFamily
                  font.pixelSize: Style.font.caption
                  elide: Text.ElideRight
                }
              }

              // Playback Controls
              Row {
                id: mediaControlsRow
                anchors.verticalCenter: parent.verticalCenter
                spacing: Style.space(6)

                // Prev
                Rectangle {
                  width: Style.space(28)
                  height: Style.space(28)
                  radius: Theme.radiusSmall
                  color: prevMouse.containsMouse ? Theme.surfaceInteractive : "transparent"
                  Text {
                    anchors.centerIn: parent
                    text: "󰒮"
                    color: Theme.textPrimary
                    font.family: root.fontFamily
                    font.pixelSize: Style.font.iconSmall
                  }
                  MouseArea {
                    id: prevMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                      if (root.mediaService) root.mediaService.runAction("previous", true)
                      else if (root.activePlayer && typeof root.activePlayer.previous === "function") root.activePlayer.previous()
                      else Util.execDetached("mpris-fast prev")
                    }
                  }
                }

                // Play / Pause
                Rectangle {
                  width: Style.space(30)
                  height: Style.space(30)
                  radius: Theme.radiusSmall
                  color: playMouse.containsMouse ? Theme.accentStrong : Theme.accent
                  Text {
                    anchors.centerIn: parent
                    text: root.isMediaPlaying ? "󰏤" : "󰐊"
                    color: Theme.accentContrast
                    font.family: root.fontFamily
                    font.pixelSize: Style.font.icon
                  }
                  MouseArea {
                    id: playMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                      if (root.mediaService) root.mediaService.runAction("playPause", true)
                      else if (root.activePlayer && typeof root.activePlayer.togglePlaying === "function") root.activePlayer.togglePlaying()
                      else Util.execDetached("mpris-fast toggle")
                    }
                  }
                }

                // Next
                Rectangle {
                  width: Style.space(28)
                  height: Style.space(28)
                  radius: Theme.radiusSmall
                  color: nextMouse.containsMouse ? Theme.surfaceInteractive : "transparent"
                  Text {
                    anchors.centerIn: parent
                    text: "󰒭"
                    color: Theme.textPrimary
                    font.family: root.fontFamily
                    font.pixelSize: Style.font.iconSmall
                  }
                  MouseArea {
                    id: nextMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                      if (root.mediaService) root.mediaService.runAction("next", true)
                      else if (root.activePlayer && typeof root.activePlayer.next === "function") root.activePlayer.next()
                      else Util.execDetached("mpris-fast next")
                    }
                  }
                }
              }
            }
          }

          // 2. LIVE TELEMETRY CAPSULES (Cloud Sync & Study Focus)
          Row {
            width: parent.width
            height: Style.space(34)
            spacing: Style.space(8)

            // Cloud Sync Capsule
            Rectangle {
              id: cloudSyncCapsule
              width: (parent.width - Style.space(8)) / 2
              height: parent.height
              radius: Theme.radiusSmall
              color: cloudMouse.containsMouse ? Theme.surfaceInteractive : Theme.surfaceElevated
              border.width: 1
              border.color: isSyncing ? Theme.borderFocus : Theme.borderSubtle

              readonly property bool isSyncing: root.cloudSyncData ? (root.cloudSyncData.active === true || root.cloudSyncData.status === "syncing") : false
              readonly property string syncPct: (root.cloudSyncData && root.cloudSyncData.progress_pct) ? (Math.round(root.cloudSyncData.progress_pct) + "%") : ""
              readonly property string syncSpeed: (root.cloudSyncData && root.cloudSyncData.speed) ? root.cloudSyncData.speed : ""

              Row {
                anchors.centerIn: parent
                spacing: Style.space(6)

                Text {
                  anchors.verticalCenter: parent.verticalCenter
                  text: cloudSyncCapsule.isSyncing ? "󰁯" : "󰄲"
                  color: cloudSyncCapsule.isSyncing ? Theme.accent : Theme.textSecondary
                  font.family: root.fontFamily
                  font.pixelSize: Style.font.iconSmall
                }

                Text {
                  anchors.verticalCenter: parent.verticalCenter
                  text: cloudSyncCapsule.isSyncing ? ("Cloud: " + cloudSyncCapsule.syncPct + " (" + cloudSyncCapsule.syncSpeed + ")") : "Cloud: Synced"
                  color: Theme.textPrimary
                  font.family: root.fontFamily
                  font.pixelSize: Style.font.caption
                  font.weight: Font.Medium
                  elide: Text.ElideRight
                }
              }

              MouseArea {
                id: cloudMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                  root.applySelected("cmd.sync_health", "omarchy-launch-terminal $HOME/Work/bin/omarchy-backup-health.sh")
                }
              }
            }

            // Study Focus Capsule
            Rectangle {
              id: studyFocusCapsule
              width: (parent.width - Style.space(8)) / 2
              height: parent.height
              radius: Theme.radiusSmall
              color: focusMouse.containsMouse ? Theme.surfaceInteractive : Theme.surfaceElevated
              border.width: 1
              border.color: isFocusActive ? Theme.warning : Theme.borderSubtle

              readonly property bool isFocusActive: root.studyModeData ? (root.studyModeData.active === true) : false
              readonly property string focusText: isFocusActive ? ("Focus: " + (root.studyModeData.remaining_formatted || "Active")) : "Study Mode: Idle"

              Row {
                anchors.centerIn: parent
                spacing: Style.space(6)

                Text {
                  anchors.verticalCenter: parent.verticalCenter
                  text: studyFocusCapsule.isFocusActive ? "󰑋" : "󰈅"
                  color: studyFocusCapsule.isFocusActive ? Theme.warning : Theme.textSecondary
                  font.family: root.fontFamily
                  font.pixelSize: Style.font.iconSmall
                }

                Text {
                  anchors.verticalCenter: parent.verticalCenter
                  text: studyFocusCapsule.focusText
                  color: Theme.textPrimary
                  font.family: root.fontFamily
                  font.pixelSize: Style.font.caption
                  font.weight: Font.Medium
                  elide: Text.ElideRight
                }
              }

              MouseArea {
                id: focusMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                  root.applySelected("cmd.study_menu", "omarchy-study-focus menu")
                }
              }
            }
          }

          // 3. FREQUENT APPS / WORKSTATION QUICK LAUNCH DECK (3x2 Grid)
          Grid {
            id: quickTilesGrid
            width: parent.width
            height: Style.space(38) * 2 + spacing
            columns: 3
            spacing: Style.space(6)

            Repeater {
              model: [
                { label: "Terminal", icon: "󰞷", action: "omarchy-launch-terminal" },
                { label: "Browser", icon: "󰈹", action: "omarchy-launch-browser" },
                { label: "AI Deck", icon: "󰚩", action: "omarchy-agent" },
                { label: "Editor", icon: "󰨞", action: "omarchy-launch-editor" },
                { label: "Files", icon: "󰉋", action: "omarchy-launch-file-manager" },
                { label: "Themes", icon: "󰏘", action: "omarchy-theme-picker" }
              ]

              delegate: Rectangle {
                id: tile
                required property var modelData
                required property int index

                readonly property string tileLabel: modelData.label
                readonly property string tileIcon: modelData.icon
                readonly property string tileAction: modelData.action || ""
                readonly property string tileRoute: modelData.route || ""

                width: (quickTilesGrid.width - Style.space(12)) / 3
                height: Style.space(38)
                radius: Theme.radiusSmall
                color: tileMouse.containsMouse ? Theme.surfaceInteractive : Theme.surfaceElevated
                border.width: 1
                border.color: tileMouse.containsMouse ? Theme.borderFocus : Theme.borderSubtle
                scale: tileMouse.pressed ? Theme.pressScale : 1.0

                Behavior on scale {
                  NumberAnimation { duration: Theme.micro; easing.type: Theme.easeStandard }
                }

                Row {
                  anchors.centerIn: parent
                  spacing: Style.space(6)

                  Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: tile.tileIcon
                    color: Theme.accent
                    font.family: root.fontFamily
                    font.pixelSize: Style.font.iconLarge
                  }

                  Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: tile.tileLabel
                    color: Theme.textPrimary
                    font.family: root.fontFamily
                    font.pixelSize: Style.font.bodySmall
                    font.weight: Font.Medium
                  }
                }

                MouseArea {
                  id: tileMouse
                  anchors.fill: parent
                  hoverEnabled: true
                  cursorShape: Qt.PointingHandCursor
                  onClicked: {
                    if (tile.tileRoute) {
                      root.setActiveMenu(tile.tileRoute, true, true)
                    } else if (tile.tileAction) {
                      root.applySelected("tile." + tile.tileLabel, tile.tileAction)
                    }
                  }
                }
              }
            }
          }
        }

        Item {
          id: listContainer
          width: parent.width
          height: root.visibleRowsHeight
          clip: true
          transform: Translate { x: root.navSlideOffset }
          opacity: root.navOpacity

          ListView {
            id: resultList
            anchors.fill: parent
            model: displayModel
            clip: true
            reuseItems: true
            cacheBuffer: root.baseRowHeight * 6
            spacing: root.rowSpacing
            boundsBehavior: Flickable.StopAtBounds
            currentIndex: root.selectedIndex

            highlightFollowsCurrentItem: false
            highlight: Item {
              id: liquidCapsule
              width: resultList.width
              visible: root.cursorActive && displayModel.count > 0 && root.selectedIndex >= 0
              z: 0

              property bool suppressAnim: false
              property int previousSelIndex: root.selectedIndex

              readonly property var curItem: resultList.currentItem
              readonly property real targetY: curItem ? curItem.y : (root.selectedIndex * (root.baseRowHeight + root.rowSpacing))
              readonly property real targetH: curItem ? curItem.height : root.baseRowHeight

              y: targetY
              height: targetH

              Behavior on y {
                enabled: !liquidCapsule.suppressAnim && !Motion.reducedMotion
                NumberAnimation {
                  duration: Motion.liquidMoveDuration
                  easing.type: Motion.easeStandard
                  easing.overshoot: Motion.springOvershoot
                }
              }

              Behavior on height {
                enabled: !liquidCapsule.suppressAnim && !Motion.reducedMotion
                NumberAnimation {
                  duration: Motion.micro
                  easing.type: Motion.easeStandard
                }
              }

              Connections {
                target: root
                function onActiveMenuChanged() {
                  liquidCapsule.suppressAnim = true
                  Qt.callLater(function() { liquidCapsule.suppressAnim = false })
                }
                function onOpenedChanged() {
                  if (!root.opened) {
                    liquidCapsule.suppressAnim = true
                  } else {
                    Qt.callLater(function() { liquidCapsule.suppressAnim = false })
                  }
                }
                function onSelectedIndexChanged() {
                  var diff = root.selectedIndex - liquidCapsule.previousSelIndex
                  if (liquidCapsule.previousSelIndex >= 0 && Math.abs(diff) === 1 && !liquidCapsule.suppressAnim && !Motion.reducedMotion) {
                    stretchAnim.direction = diff > 0 ? 1 : -1
                    stretchAnim.restart()
                  }
                  liquidCapsule.previousSelIndex = root.selectedIndex
                }
              }

              SequentialAnimation {
                id: stretchAnim
                property int direction: 1
                NumberAnimation {
                  target: capsuleStretch
                  property: "yScale"
                  to: Motion.liquidStretchMax
                  duration: Math.max(1, Math.round(Motion.liquidMoveDuration * 0.45))
                  easing.type: Easing.OutQuad
                }
                NumberAnimation {
                  target: capsuleStretch
                  property: "yScale"
                  to: 1.0
                  duration: Math.max(1, Math.round(Motion.liquidMoveDuration * 0.55))
                  easing.type: Motion.easeStandard
                  easing.overshoot: Motion.springOvershoot
                }
              }

              transform: Scale {
                id: capsuleStretch
                origin.x: liquidCapsule.width / 2
                origin.y: stretchAnim.direction > 0 ? 0 : liquidCapsule.height
                yScale: 1.0
              }

              BorderSurface {
                anchors.fill: parent
                radius: Theme.radiusSmall
                color: Theme.surfaceSelected
                borderSpec: root.selectedBorderSpec

                Rectangle {
                  id: liquidPill
                  width: Style.space(3.5)
                  height: parent.height - Style.space(12)
                  radius: Style.space(2)
                  color: Theme.accent
                  anchors.left: parent.left
                  anchors.leftMargin: Style.space(4)
                  anchors.verticalCenter: parent.verticalCenter
                  opacity: 0.95

                  transform: Scale {
                    id: pillScale
                    origin.y: liquidPill.height / 2
                    xScale: capsuleStretch.yScale > 1.05 ? 1.6 : 1.0
                    Behavior on xScale {
                      NumberAnimation { duration: Motion.micro; easing.type: Motion.easeStandard }
                    }
                  }
                }
              }
            }

            section.property: "section"
            section.criteria: ViewSection.FullString
            section.delegate: Item {
              required property string section

              width: ListView.view.width
              height: section === "drilldown" ? root.dividerHeight : 0
              visible: section === "drilldown"

              Rectangle {
                anchors.left: parent.left
                anchors.leftMargin: Style.space(4)
                anchors.right: parent.right
                anchors.rightMargin: Style.space(4)
                anchors.verticalCenter: parent.verticalCenter
                height: Style.spacing.hairline
                color: Util.alpha(root.foreground, 0.2)
              }
            }

            delegate: BorderSurface {
              id: row
              required property int index
              required property string itemId
              required property string kind
              required property string icon
              required property string iconFont
              required property string appIcon
              required property string appId
              required property string label
              required property string target
              required property string detail
              required property string path
              required property string action
              required property int childCount

              readonly property bool hasCursor: root.cursorActive && row.index === root.selectedIndex
              readonly property bool isApp: row.kind === "app"
              readonly property bool hasIcon: row.icon.length > 0 || row.isApp

              width: ListView.view.width
              height: root.rowHeightForDetail(row.detail)
              radius: Theme.radiusSmall
              color: "transparent"
              borderSpec: Border.none()

              Text {
                id: iconText
                visible: row.hasIcon && !row.isApp
                text: row.icon
                color: row.hasCursor ? Theme.accent : Theme.textSecondary
                font.family: row.iconFont.length > 0 ? row.iconFont : root.fontFamily
                font.pixelSize: Style.font.iconLarge
                width: Style.space(36)
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                anchors.left: parent.left
                anchors.leftMargin: root.rowReservedBorderLeft + Style.space(8)
                y: contentColumn.y + labelText.y + (labelText.height - height) / 2

                Behavior on color { ColorAnimation { duration: Motion.micro } }
              }

              Image {
                id: appIconImage
                visible: row.isApp
                width: Style.font.iconLarge
                height: Style.font.iconLarge
                fillMode: Image.PreserveAspectFit
                sourceSize.width: width * Screen.devicePixelRatio
                sourceSize.height: height * Screen.devicePixelRatio
                source: row.isApp && root.appLibrary ? root.appLibrary.iconSource(row.appIcon) : ""
                asynchronous: true
                anchors.left: parent.left
                anchors.leftMargin: root.rowReservedBorderLeft + Style.space(8) + (Style.space(36) - width) / 2
                y: contentColumn.y + labelText.y + (labelText.height - height) / 2
              }

              Column {
                id: contentColumn
                anchors.left: row.hasIcon ? iconText.right : parent.left
                anchors.leftMargin: row.hasIcon ? Style.space(6) : root.rowReservedBorderLeft + Style.space(18)
                anchors.right: trail.left
                anchors.rightMargin: Style.space(6)
                anchors.verticalCenter: parent.verticalCenter
                spacing: Style.space(2)

                Text {
                  id: labelText
                  width: parent.width
                  text: row.label
                  color: row.hasCursor ? (Theme.isLight ? Theme.accentStrong : Theme.textPrimary) : Theme.textSecondary
                  font.family: root.fontFamily
                  font.pixelSize: Style.font.heading
                  font.weight: row.hasCursor ? Font.DemiBold : Font.Medium
                  elide: Text.ElideRight

                  Behavior on color { ColorAnimation { duration: Motion.micro } }
                }

                Text {
                  width: parent.width
                  text: row.detail
                  visible: row.detail.length > 0 && (root.filterText.length > 0 || row.kind === "dmenu" || root.activeMenu === "bookmarks" || true)
                  color: row.hasCursor ? Theme.textSecondary : Theme.textMuted
                  font.family: root.fontFamily
                  font.pixelSize: Style.font.bodySmall
                  elide: Text.ElideRight
                }
              }

              Row {
                id: trail
                width: Style.space(16)
                anchors.right: parent.right
                anchors.rightMargin: root.rowReservedBorderRight + Style.space(8)
                y: contentColumn.y + labelText.y + (labelText.height - height) / 2
                spacing: 0

                Text {
                  text: row.kind === "menu" || row.kind === "link" ? "›" : ""
                  color: row.hasCursor ? Theme.accent : Theme.textMuted
                  opacity: row.kind === "menu" || row.kind === "link" ? (row.hasCursor ? 1.0 : 0.4) : 0
                  font.family: root.fontFamily
                  font.pixelSize: Style.font.heading
                  font.weight: Font.Normal
                  anchors.verticalCenter: parent.verticalCenter
                }
              }

              MouseArea {
                id: mouseArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onEntered: root.selectFromPointer(row.index, row, {
                  x: mouseArea.mouseX,
                  y: mouseArea.mouseY
                })
                onPositionChanged: function(mouse) {
                  root.selectFromPointer(row.index, row, mouse)
                }
                onClicked: {
                  root.cursorActive = true
                  root.selectedIndex = row.index
                  root.activateIndex(row.index, true)
                }
              }
            }
          }

          Rectangle {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            height: Math.min(Style.space(28), parent.height / 2)
            visible: opacity > 0
            opacity: resultList.contentHeight > resultList.height
              ? Math.max(0, Math.min(1, (resultList.contentY - resultList.originY) / height))
              : 0
            gradient: Gradient {
              GradientStop { position: 0; color: root.background }
              GradientStop { position: 1; color: Util.alpha(root.background, 0) }
            }
          }

          Rectangle {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            height: Math.min(Style.space(28), parent.height / 2)
            visible: opacity > 0
            opacity: resultList.contentHeight > resultList.height
              ? Math.max(0, Math.min(1, (resultList.originY + resultList.contentHeight - resultList.height - resultList.contentY) / height))
              : 0
            gradient: Gradient {
              GradientStop { position: 0; color: Util.alpha(root.background, 0) }
              GradientStop { position: 1; color: root.background }
            }
          }

          Column {
            anchors.centerIn: parent
            spacing: Style.space(8)
            visible: displayModel.count === 0 && root.mode !== "input"

            Text {
              text: "󰈉"
              color: root.selectedText
              opacity: 0.8
              font.family: root.fontFamily
              font.pixelSize: Style.font.displayLarge
              horizontalAlignment: Text.AlignHCenter
              width: Style.space(320)
            }

            Text {
              text: root.filterText ? "No matches for “" + root.filterText + "”" : "Nothing here yet"
              color: root.foreground
              opacity: 0.7
              font.family: root.fontFamily
              font.pixelSize: Style.font.title
              horizontalAlignment: Text.AlignHCenter
              width: Style.space(320)
            }
          }
        }

        // Micro-Footer / Shortcut HUD
        Rectangle {
          width: parent.width
          height: root.footerHeight
          color: "transparent"
          visible: root.mode !== "input"

          Row {
            anchors.left: parent.left
            anchors.leftMargin: Style.space(4)
            anchors.verticalCenter: parent.verticalCenter
            spacing: Style.space(12)

            Row {
              spacing: Style.space(4)
              anchors.verticalCenter: parent.verticalCenter
              Rectangle {
                width: k1.implicitWidth + Style.space(8)
                height: Style.space(16)
                radius: Style.space(3)
                color: Theme.surfaceElevated
                border.width: 1
                border.color: Theme.borderSubtle
                Text { id: k1; anchors.centerIn: parent; text: "↵"; color: Theme.textPrimary; font.pixelSize: Style.font.caption; font.family: root.fontFamily }
              }
              Text { text: "Open"; color: Theme.textMuted; font.pixelSize: Style.font.caption; font.family: root.fontFamily; anchors.verticalCenter: parent.verticalCenter }
            }

            Row {
              spacing: Style.space(4)
              anchors.verticalCenter: parent.verticalCenter
              Rectangle {
                width: k2.implicitWidth + Style.space(8)
                height: Style.space(16)
                radius: Style.space(3)
                color: Theme.surfaceElevated
                border.width: 1
                border.color: Theme.borderSubtle
                Text { id: k2; anchors.centerIn: parent; text: "↑↓"; color: Theme.textPrimary; font.pixelSize: Style.font.caption; font.family: root.fontFamily }
              }
              Text { text: "Navigate"; color: Theme.textMuted; font.pixelSize: Style.font.caption; font.family: root.fontFamily; anchors.verticalCenter: parent.verticalCenter }
            }

            Row {
              visible: root.activeMenu !== "root"
              spacing: Style.space(4)
              anchors.verticalCenter: parent.verticalCenter
              Rectangle {
                width: k3.implicitWidth + Style.space(8)
                height: Style.space(16)
                radius: Style.space(3)
                color: Theme.surfaceElevated
                border.width: 1
                border.color: Theme.borderSubtle
                Text { id: k3; anchors.centerIn: parent; text: "⌫"; color: Theme.textPrimary; font.pixelSize: Style.font.caption; font.family: root.fontFamily }
              }
              Text { text: "Back"; color: Theme.textMuted; font.pixelSize: Style.font.caption; font.family: root.fontFamily; anchors.verticalCenter: parent.verticalCenter }
            }

            Row {
              spacing: Style.space(4)
              anchors.verticalCenter: parent.verticalCenter
              Rectangle {
                width: kCmd.implicitWidth + Style.space(8)
                height: Style.space(16)
                radius: Style.space(3)
                color: Theme.surfaceElevated
                border.width: 1
                border.color: Theme.borderSubtle
                Text { id: kCmd; anchors.centerIn: parent; text: ">"; color: Theme.accent; font.pixelSize: Style.font.caption; font.weight: Font.Bold; font.family: root.fontFamily }
              }
              Text { text: "Commands"; color: Theme.textMuted; font.pixelSize: Style.font.caption; font.family: root.fontFamily; anchors.verticalCenter: parent.verticalCenter }
            }
          }

          Row {
            anchors.right: parent.right
            anchors.rightMargin: Style.space(4)
            anchors.verticalCenter: parent.verticalCenter
            spacing: Style.space(4)

            Rectangle {
              width: k4.implicitWidth + Style.space(8)
              height: Style.space(16)
              radius: Style.space(3)
              color: Theme.surfaceElevated
              border.width: 1
              border.color: Theme.borderSubtle
              Text { id: k4; anchors.centerIn: parent; text: "Esc"; color: Theme.textPrimary; font.pixelSize: Style.font.caption; font.family: root.fontFamily }
            }
            Text { text: "Close"; color: Theme.textMuted; font.pixelSize: Style.font.caption; font.family: root.fontFamily; anchors.verticalCenter: parent.verticalCenter }
          }
        }

        Item {
          width: parent.width
          height: 0
        }
      }
    }
  }
}
