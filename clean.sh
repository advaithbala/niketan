#!/usr/bin/env bash
# Undo everything bootstrap.sh did. Idempotent: safe to re-run.
# Usage: ./clean.sh [--keep-nvim-config]
#   --keep-nvim-config  Don't remove ~/.config/nvim (useful if you customized it)

set -euo pipefail

PREFIX="${PREFIX:-$HOME/.local}"
BIN="$PREFIX/bin"
OPT="$PREFIX/opt"
STATE="$PREFIX/state/niketan"

KEEP_NVIM_CONFIG=false
for arg in "$@"; do
  case "$arg" in
    --keep-nvim-config) KEEP_NVIM_CONFIG=true ;;
    *) echo "Unknown option: $arg" >&2; exit 1 ;;
  esac
done

log() { printf '%s\n' "$*"; }

MARKER="# >>> niketan >>>"
MARKER_END="# <<< niketan <<<"

detect_os() {
  case "$(uname -s)" in
    Linux)  OS=linux ;;
    Darwin) OS=macos ;;
    *)      OS=unknown ;;
  esac
}

detect_shell_rc() {
  local shell_name
  shell_name="$(basename "${SHELL:-/bin/bash}")"

  case "$shell_name" in
    zsh)  SHELL_RC="$HOME/.zshrc" ;;
    bash)
      if [[ "$OS" == macos ]]; then
        SHELL_RC="$HOME/.bash_profile"
      else
        SHELL_RC="$HOME/.bashrc"
      fi
      ;;
    fish) SHELL_RC="$HOME/.config/fish/config.fish" ;;
    *)    SHELL_RC="$HOME/.profile" ;;
  esac
}

remove_shell_rc_block() {
  detect_shell_rc

  if [[ ! -f "$SHELL_RC" ]]; then
    log "No shell rc at $SHELL_RC — nothing to clean."
    return 0
  fi

  if ! grep -qF "$MARKER" "$SHELL_RC"; then
    log "No niketan block in $SHELL_RC — nothing to clean."
    return 0
  fi

  local tmp
  tmp=$(mktemp)
  local in_block=false
  while IFS= read -r line || [[ -n "$line" ]]; do
    if [[ "$line" == "$MARKER" ]]; then
      in_block=true
      continue
    fi
    if [[ "$line" == "$MARKER_END" ]]; then
      in_block=false
      continue
    fi
    if [[ "$in_block" == false ]]; then
      printf '%s\n' "$line" >> "$tmp"
    fi
  done < "$SHELL_RC"

  mv "$tmp" "$SHELL_RC"
  log "Removed niketan block from $SHELL_RC"
}

remove_binaries() {
  local bins=(nvim rg fd fzf)
  for b in "${bins[@]}"; do
    if [[ -L "$BIN/$b" ]] || [[ -f "$BIN/$b" ]]; then
      rm -f "$BIN/$b"
      log "Removed $BIN/$b"
    fi
  done
}

remove_opt_dirs() {
  for d in "$OPT"/nvim-linux-* "$OPT"/nvim-macos-* "$OPT/nvim-current" "$OPT/fzf"; do
    if [[ -e "$d" ]]; then
      rm -rf "$d"
      log "Removed $d"
    fi
  done
}

remove_state() {
  if [[ -d "$STATE" ]]; then
    rm -rf "$STATE"
    log "Removed state dir $STATE"
  fi
}

remove_path_snippet() {
  local f="$PREFIX/niketan-env.sh"
  if [[ -f "$f" ]]; then
    rm -f "$f"
    log "Removed $f"
  fi
}

remove_nvim_config() {
  local target="${XDG_CONFIG_HOME:-$HOME/.config}/nvim"
  local nvim_data="${XDG_DATA_HOME:-$HOME/.local/share}/nvim"
  local nvim_cache="${XDG_CACHE_HOME:-$HOME/.cache}/nvim"

  if [[ "$KEEP_NVIM_CONFIG" == true ]]; then
    log "Keeping Neovim config at $target (--keep-nvim-config)"
    return 0
  fi

  for d in "$target" "$nvim_data" "$nvim_cache"; do
    if [[ -d "$d" ]]; then
      rm -rf "$d"
      log "Removed $d"
    fi
  done
}

remove_fzf_home() {
  if [[ -d "$HOME/.fzf" ]]; then
    rm -rf "$HOME/.fzf"
    log "Removed $HOME/.fzf"
  fi
}

main() {
  detect_os
  log "Cleaning niketan (PREFIX=$PREFIX)..."
  log ""

  remove_shell_rc_block
  remove_binaries
  remove_opt_dirs
  remove_state
  remove_path_snippet
  remove_nvim_config
  remove_fzf_home

  log ""
  log "Done. Open a new shell to pick up the changes."
  log "The $BIN directory itself was left in place (other tools may use it)."
}

main "$@"
