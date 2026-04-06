#!/usr/bin/env bash
# Portable user-local CLI toolchain (no root). Idempotent: safe to re-run.
# Automatically detects your shell and wires everything up.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "$SCRIPT_DIR/lib/common.sh"
source "$SCRIPT_DIR/lib/neovim.sh"
source "$SCRIPT_DIR/lib/tools.sh"
source "$SCRIPT_DIR/lib/shell.sh"
source "$SCRIPT_DIR/lib/tmux.sh"

mkdir -p "$BIN" "$OPT" "$STATE"
detect_os_arch

log "Installing niketan to PREFIX=$PREFIX (OS=$OS ARCH=$ARCH)"
log ""

install_neovim
install_ripgrep
install_fd
install_fzf
install_kickstart_nvim
install_tmux_conf
write_env_snippet
inject_shell_rc

log ""
log "Done. Your shell rc ($SHELL_RC) has been updated."
log "Run 'source $SHELL_RC' or open a new shell to activate."
log ""
log "Then run: nvim  (or just: n)"
