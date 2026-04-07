#!/usr/bin/env bash
# Portable user-local CLI toolchain (no root). Idempotent: safe to re-run.
# Automatically detects your shell and wires everything up.
#
# Usage: ./bootstrap.sh [--local|--remote] [--agent <name>]
#   --local           Force fonts + Alacritty (default on non-SSH shells)
#   --remote          Skip fonts + Alacritty (overrides auto; same as typical SSH)
#   NIKETAN_SESSION   auto | local | remote — same as flags; env is read before parsing
#   --agent cursor    Also install the Cursor CLI agent
set -euo pipefail

NIKETAN_SESSION="${NIKETAN_SESSION:-auto}"
AGENTS=()
while [[ $# -gt 0 ]]; do
  case "$1" in
    --local)  NIKETAN_SESSION=local; shift ;;
    --remote) NIKETAN_SESSION=remote; shift ;;
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
source "$SCRIPT_DIR/lib/fonts.sh"
source "$SCRIPT_DIR/lib/alacritty.sh"
source "$SCRIPT_DIR/lib/tmux.sh"
source "$SCRIPT_DIR/lib/agents.sh"

mkdir -p "$BIN" "$OPT" "$STATE"
detect_os_arch
detect_niketan_session
check_niketan_prereqs

log "Installing niketan to PREFIX=$PREFIX (OS=$OS ARCH=$ARCH)"
log ""

install_neovim
install_ripgrep
install_fd
install_fzf
install_tree_sitter
install_kickstart_nvim
install_nvim_parsers
install_nvim_folding
patch_kickstart_for_niketan
if [[ "${NIKETAN_INSTALL_UI:-1}" == 1 ]]; then
  install_nerd_fonts
  install_alacritty_conf
else
  log "Skipping Nerd Fonts and Alacritty (use local bootstrap for terminal UI)."
fi
install_tmux_conf
write_env_snippet
inject_shell_rc

# Empty "${AGENTS[@]}" under `set -u` errors on some Bash versions; guard instead.
if ((${#AGENTS[@]} > 0)); then
  for agent in "${AGENTS[@]}"; do
    install_agent "$agent"
  done
fi

log ""
log "Done. Your shell rc ($SHELL_RC) has been updated."
log "Run 'source $SHELL_RC' or open a new shell to activate."
log ""
log "Then run: nvim  (or just: n)"
