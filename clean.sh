#!/usr/bin/env bash
# Undo everything bootstrap.sh did. Idempotent: safe to re-run.
#
# Usage: ./clean.sh [--keep-nvim-config] [--agent <name>]
#   --keep-nvim-config  Don't remove ~/.config/nvim
#   --agent cursor      Also remove the Cursor CLI agent
set -euo pipefail

KEEP_NVIM_CONFIG=false
AGENTS=()
while [[ $# -gt 0 ]]; do
  case "$1" in
    --keep-nvim-config) KEEP_NVIM_CONFIG=true; shift ;;
    --agent)
      [[ -n "${2:-}" ]] || { echo "Error: --agent requires a name" >&2; exit 1; }
      AGENTS+=("$2"); shift 2 ;;
    *)
      echo "Unknown option: $1" >&2; exit 1 ;;
  esac
done

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "$SCRIPT_DIR/lib/common.sh"
source "$SCRIPT_DIR/lib/neovim.sh"
source "$SCRIPT_DIR/lib/tools.sh"
source "$SCRIPT_DIR/lib/shell.sh"
source "$SCRIPT_DIR/lib/tmux.sh"
source "$SCRIPT_DIR/lib/agents.sh"

detect_os_arch 2>/dev/null || true

log "Cleaning niketan (PREFIX=$PREFIX)..."
log ""

remove_shell_rc_block
clean_env_snippet
clean_tools
clean_neovim
clean_tmux_conf

if ((${#AGENTS[@]} > 0)); then
  for agent in "${AGENTS[@]}"; do
    clean_agent "$agent"
  done
fi

[[ -d "$STATE" ]] && rm -rf "$STATE" && log "Removed state dir $STATE"

unalias n 2>/dev/null && log "Removed alias 'n'"

log ""
log "Done. Open a new shell to pick up the changes."
log "The $BIN directory itself was left in place (other tools may use it)."
