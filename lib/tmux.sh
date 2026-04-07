#!/usr/bin/env bash
# Install / clean tmux.conf, TPM, and catppuccin theme.

CATPPUCCIN_TAG="${CATPPUCCIN_TAG:-v2.1.3}"

install_tpm() {
  local tpm_dir="$HOME/.tmux/plugins/tpm"
  if [[ -d "$tpm_dir/.git" ]]; then
    return 0
  fi
  log "Cloning TPM (Tmux Plugin Manager)..."
  mkdir -p "$HOME/.tmux/plugins"
  git clone --depth 1 https://github.com/tmux-plugins/tpm.git "$tpm_dir"
}

install_catppuccin_tmux() {
  local cat_dir="$HOME/.tmux/plugins/catppuccin/tmux"
  if [[ -d "$cat_dir/.git" ]]; then
    return 0
  fi
  log "Cloning catppuccin/tmux ($CATPPUCCIN_TAG)..."
  mkdir -p "$HOME/.tmux/plugins/catppuccin"
  git clone --depth 1 -b "$CATPPUCCIN_TAG" \
    https://github.com/catppuccin/tmux.git "$cat_dir"
}

install_tmux_conf() {
  local src="$NIKETAN_DIR/config/tmux.conf"
  local dest="$HOME/.tmux.conf"

  if [[ ! -f "$src" ]]; then
    log "No config/tmux.conf in niketan repo — skipping."
    return 0
  fi

  if [[ -f "$dest" ]] && ! grep -qF "# niketan-managed" "$dest"; then
    local backup="${dest}.pre-niketan"
    cp "$dest" "$backup"
    log "Backed up existing $dest to $backup"
  fi

  install_tpm
  install_catppuccin_tmux

  cp "$src" "$dest"
  log "Installed tmux.conf to $dest"

  if command -v tmux >/dev/null 2>&1 && [[ -n "${TMUX:-}" ]]; then
    tmux source-file "$dest" 2>/dev/null && log "Reloaded tmux config." || true
  fi
}

clean_tmux_conf() {
  local dest="$HOME/.tmux.conf"
  local backup="${dest}.pre-niketan"

  if [[ -f "$backup" ]]; then
    mv "$backup" "$dest"
    log "Restored $backup to $dest"
  elif [[ -f "$dest" ]] && grep -qF "# niketan-managed" "$dest"; then
    rm -f "$dest"
    log "Removed $dest"
  else
    log "No niketan-managed tmux.conf found — skipping."
  fi

  if [[ -d "$HOME/.tmux/plugins" ]]; then
    rm -rf "$HOME/.tmux/plugins"
    log "Removed $HOME/.tmux/plugins"
  fi
}
