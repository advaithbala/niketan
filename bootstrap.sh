#!/usr/bin/env bash
# Portable user-local CLI toolchain (no root). Idempotent: safe to re-run.
# Automatically detects your shell and wires everything up.
#
# Usage: ./bootstrap.sh [--agent <name>]
#   --agent cursor    Also install the Cursor CLI agent
set -euo pipefail

AGENTS=()
while [[ $# -gt 0 ]]; do
  case "$1" in
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

mkdir -p "$BIN" "$OPT" "$STATE"
detect_os_arch

log "Installing niketan to PREFIX=$PREFIX (OS=$OS ARCH=$ARCH)"
log ""

install_neovim
install_ripgrep
install_fd
install_fzf
install_kickstart_nvim
install_nvim_folding
install_tmux_conf
write_env_snippet
inject_shell_rc

for agent in "${AGENTS[@]}"; do
  install_agent "$agent"
done

log ""
log "Done. Your shell rc ($SHELL_RC) has been updated."
log "Run 'source $SHELL_RC' or open a new shell to activate."
log ""
log "Then run: nvim  (or just: n)"
