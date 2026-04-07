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
  if [[ -f "$cat_dir/catppuccin.tmux" ]] && [[ -d "$cat_dir/.git" ]]; then
    return 0
  fi
  log "Cloning catppuccin/tmux ($CATPPUCCIN_TAG)..."
  rm -rf "$HOME/.tmux/plugins/catppuccin"
  mkdir -p "$HOME/.tmux/plugins/catppuccin"
  git clone --depth 1 -b "$CATPPUCCIN_TAG" \
    https://github.com/catppuccin/tmux.git "$cat_dir"
}

ensure_catppuccin_tmux_usable() {
  local cat_dir="$HOME/.tmux/plugins/catppuccin/tmux"
  if [[ -f "$cat_dir/catppuccin.tmux" ]]; then
    return 0
  fi
  log "Catppuccin plugin missing or incomplete — reinstalling..."
  rm -rf "$HOME/.tmux/plugins/catppuccin"
  install_catppuccin_tmux
  [[ -f "$cat_dir/catppuccin.tmux" ]] || die "catppuccin.tmux not found after clone — check network and tag $CATPPUCCIN_TAG"
}

# Prefer tmux-256color when terminfo exists (Ubuntu: ncurses-term / ncurses-base); else screen-256color.
pick_tmux_inner_term() {
  if command -v infocmp >/dev/null 2>&1 && infocmp -x tmux-256color >/dev/null 2>&1; then
    printf '%s' "tmux-256color"
    return 0
  fi
  if command -v infocmp >/dev/null 2>&1 && infocmp -x tmux >/dev/null 2>&1; then
    printf '%s' "tmux"
    return 0
  fi
  printf '%s' "screen-256color"
}

apply_tmux_default_terminal() {
  local dest="$1"
  local term
  term=$(pick_tmux_inner_term)
  sed -i.bak "s/^set -g default-terminal .*/set -g default-terminal \"$term\"/" "$dest"
  rm -f "${dest}.bak"
  log "tmux default-terminal (inside panes): $term"
}

# Best-effort TPM refresh (handles partial upgrades); never fatal.
run_tpm_plugin_sync() {
  local tpm_install="$HOME/.tmux/plugins/tpm/bin/install_plugins"
  local tpm_clean="$HOME/.tmux/plugins/tpm/bin/clean_plugins"
  if [[ ! -x "$tpm_install" ]]; then
    return 0
  fi
  if [[ ${NIKETAN_TPM_CLEAN:-0} == 1 ]] && [[ -x "$tpm_clean" ]]; then
    log "NIKETAN_TPM_CLEAN=1 — running TPM clean_plugins then install_plugins..."
    "$tpm_clean" || true
  fi
  log "Running TPM install_plugins..."
  "$tpm_install" || log "TPM install_plugins exited non-zero — in tmux press prefix + I to retry."
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
  ensure_catppuccin_tmux_usable

  cp "$src" "$dest"
  apply_tmux_default_terminal "$dest"
  log "Installed tmux.conf to $dest"

  run_tpm_plugin_sync

  if command -v tmux >/dev/null 2>&1 && [[ -n "${TMUX:-}" ]]; then
    tmux source-file "$dest" 2>/dev/null && log "Reloaded tmux config." || \
      log "Could not reload tmux from this shell — run: tmux source-file ~/.tmux.conf"
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
