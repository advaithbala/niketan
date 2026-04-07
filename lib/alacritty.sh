#!/usr/bin/env bash
# Install / remove Alacritty config (Nerd Font family + Catppuccin Mocha).

NIKETAN_ALACRITTY_MARKER="# niketan-managed"

install_alacritty_conf() {
  local src="$NIKETAN_DIR/config/alacritty/alacritty.toml"
  local dest_dir="${XDG_CONFIG_HOME:-$HOME/.config}/alacritty"
  local dest="$dest_dir/alacritty.toml"

  if [[ ! -f "$src" ]]; then
    log "No config/alacritty/alacritty.toml in niketan repo — skipping."
    return 0
  fi

  if [[ -f "$dest" ]] && ! grep -qF "$NIKETAN_ALACRITTY_MARKER" "$dest" 2>/dev/null; then
    cp "$dest" "${dest}.pre-niketan"
    log "Backed up existing $dest to ${dest}.pre-niketan"
  fi

  mkdir -p "$dest_dir"
  local fam
  fam=$(nerd_font_alacritty_family)
  case "$fam" in
    *'|'*|*'&'*) die "NERD_FONT_ALACRITTY_FAMILY must not contain | or & (sed)." ;;
  esac
  sed "s|__ALACRITTY_FONT_FAMILY__|$fam|g" "$src" >"${dest}.tmp"
  mv "${dest}.tmp" "$dest"
  log "Installed Alacritty config $dest (family \"$fam\"). Quit and reopen Alacritty so it picks up new fonts."
}

clean_alacritty_conf() {
  local dest="${XDG_CONFIG_HOME:-$HOME/.config}/alacritty/alacritty.toml"
  local backup="${dest}.pre-niketan"

  if [[ -f "$backup" ]]; then
    mv "$backup" "$dest"
    log "Restored $backup to $dest"
  elif [[ -f "$dest" ]] && grep -qF "$NIKETAN_ALACRITTY_MARKER" "$dest" 2>/dev/null; then
    rm -f "$dest"
    log "Removed $dest"
  else
    log "No niketan-managed alacritty.toml — skipping."
  fi
}
