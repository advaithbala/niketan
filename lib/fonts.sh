#!/usr/bin/env bash
# Install Nerd Fonts (user-local, no sudo). Used by tmux status icons and Neovim UI.

# Pin release: https://github.com/ryanoasis/nerd-fonts/releases
NERD_FONTS_VER="${NERD_FONTS_VER:-3.3.0}"
# Zip name must match a release asset (no spaces). Examples: JetBrainsMono, Hack.
NERD_FONT_FAMILY="${NERD_FONT_FAMILY:-JetBrainsMono}"

install_nerd_fonts() {
  if [[ ! "$NERD_FONT_FAMILY" =~ ^[a-zA-Z0-9_-]+$ ]]; then
    die "Invalid NERD_FONT_FAMILY (use alphanumeric, _, - only)"
  fi
  if [[ ! "$NERD_FONTS_VER" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    die "Invalid NERD_FONTS_VER (expected dotted version, e.g. 3.3.0)"
  fi

  local zip_name="${NERD_FONT_FAMILY}.zip"
  local url="https://github.com/ryanoasis/nerd-fonts/releases/download/v${NERD_FONTS_VER}/${zip_name}"
  local marker="$STATE/nerd-font-${NERD_FONTS_VER}-${NERD_FONT_FAMILY}.ok"
  [[ -f "$marker" ]] && return 0

  local dest_dir
  if [[ "$OS" == macos ]]; then
    dest_dir="$HOME/Library/Fonts"
  else
    dest_dir="$HOME/.local/share/fonts"
  fi

  local tgz="$STATE/$zip_name"
  log "Downloading Nerd Font ${NERD_FONT_FAMILY} v${NERD_FONTS_VER}..."
  download "$url" "$tgz"

  mkdir -p "$dest_dir"
  command -v unzip >/dev/null 2>&1 || die "unzip is required to install Nerd Fonts"
  unzip -o -q "$tgz" -d "$dest_dir"

  if [[ "$OS" == linux ]] && command -v fc-cache >/dev/null 2>&1; then
    fc-cache -f "$dest_dir" 2>/dev/null || true
  fi

  touch "$marker"
  log "Installed Nerd Font files under $dest_dir"
  log "Set your terminal profile to a patched face (e.g. \"JetBrainsMono Nerd Font\" or \"JetBrainsMonoNerdFont-Regular\")."
}
