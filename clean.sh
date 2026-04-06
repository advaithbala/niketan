#!/usr/bin/env bash
# Undo everything bootstrap.sh did. Idempotent: safe to re-run.
# Usage: ./clean.sh [--keep-nvim-config]
set -euo pipefail

KEEP_NVIM_CONFIG=false
for arg in "$@"; do
  case "$arg" in
    --keep-nvim-config) KEEP_NVIM_CONFIG=true ;;
    *) echo "Unknown option: $arg" >&2; exit 1 ;;
  esac
done

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "$SCRIPT_DIR/lib/common.sh"
source "$SCRIPT_DIR/lib/neovim.sh"
source "$SCRIPT_DIR/lib/tools.sh"
source "$SCRIPT_DIR/lib/shell.sh"
source "$SCRIPT_DIR/lib/tmux.sh"

detect_os_arch 2>/dev/null || true

log "Cleaning niketan (PREFIX=$PREFIX)..."
log ""

remove_shell_rc_block
clean_env_snippet
clean_tools
clean_neovim
clean_tmux_conf

[[ -d "$STATE" ]] && rm -rf "$STATE" && log "Removed state dir $STATE"

log ""
log "Done. Open a new shell to pick up the changes."
log "The $BIN directory itself was left in place (other tools may use it)."
