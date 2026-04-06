#!/usr/bin/env bash
# Install / clean tmux.conf from niketan's config/.

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
}
