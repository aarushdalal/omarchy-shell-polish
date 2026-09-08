#!/usr/bin/env bash
# ==============================================================================
# Helper for omarchy-shell-polish
# Provides manual snippet inspection and safety dry-run checks.
# NEVER automatically overwrites live shell or Hyprland configurations.
# ==============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

case "${1:-check}" in
  check)
    echo "Checking Omarchy environment for shell polish snippets..."
    if command -v hyprctl >/dev/null 2>&1; then
      echo "  [OK] Hyprland is available"
    fi
    if [[ -f "$HOME/.config/hypr/looknfeel.lua" ]]; then
      echo "  [OK] Found ~/.config/hypr/looknfeel.lua"
    fi
    if [[ -f "$HOME/.config/omarchy/shell.json" ]]; then
      echo "  [OK] Found ~/.config/omarchy/shell.json"
    fi
    echo "Available snippets in $SCRIPT_DIR/snippets/:"
    ls "$SCRIPT_DIR/snippets"
    ;;
  status)
    echo "Omarchy Shell Polish provides curated configuration snippets."
    echo "Review snippets in snippets/ and docs/ for manual application."
    ;;
  *)
    echo "Usage: $0 {check|status} [--dry-run]"
    echo "Note: Snippets must be merged manually to protect your existing configuration."
    exit 0
    ;;
esac
