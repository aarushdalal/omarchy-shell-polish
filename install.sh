#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
case "${1:-check}" in
 check|status) exec python3 "$SCRIPT_DIR/tools/install_refinement.py" ;;
 apply) shift; exec python3 "$SCRIPT_DIR/tools/install_refinement.py" --apply "$@" ;;
 rollback) shift; exec python3 "$SCRIPT_DIR/tools/install_refinement.py" --rollback "$@" ;;
 *) echo "Usage: $0 {check|apply|rollback JOURNAL_DIRECTORY}" >&2; exit 1 ;;
esac
