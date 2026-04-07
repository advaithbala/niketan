#!/usr/bin/env bash
# Install Nerd Fonts (user-local, no sudo). Used by tmux status icons and Neovim UI.

# Pin release: https://github.com/ryanoasis/nerd-fonts/releases
NERD_FONTS_VER="${NERD_FONTS_VER:-3.3.0}"
# Zip name must match a release asset (no spaces). Examples: JetBrainsMono, Hack.
NERD_FONT_FAMILY="${NERD_FONT_FAMILY:-JetBrainsMono}"

# Alacritty needs the exact font family string (see: fc-list on Linux, Font Book on macOS).
# Override when using a custom NERD_FONT_FAMILY zip.
nerd_font_alacritty_family() {
  if [[ -n "${NERD_FONT_ALACRITTY_FAMILY:-}" ]]; then
    printf '%s' "$NERD_FONT_ALACRITTY_FAMILY"
    return 0
  fi
  case "${NERD_FONT_FAMILY:-JetBrainsMono}" in
    JetBrainsMono) printf '%s' 'JetBrainsMono Nerd Font' ;;
    Hack)          printf '%s' 'Hack Nerd Font' ;;
    FiraCode)      printf '%s' 'FiraCode Nerd Font' ;;
    *)
      die "Set NERD_FONT_ALACRITTY_FAMILY to your font's exact family name (NERD_FONT_FAMILY=${NERD_FONT_FAMILY})"
      ;;
  esac
}

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

  # Extract into a single family subdirectory so user font dirs stay tidy (nerd-fonts zips ship a top-level folder).
  local extract_root="$STATE/nerd-fonts-extract/$NERD_FONT_FAMILY"
  rm -rf "$extract_root"
  mkdir -p "$extract_root" "$dest_dir"
  unzip -o -q "$tgz" -d "$extract_root"

  local ttf_count=0
  while IFS= read -r f; do
    [[ -f "$f" ]] || continue
    install -m 0644 "$f" "$dest_dir/$(basename "$f")"
    ttf_count=$((ttf_count + 1))
  done < <(find "$extract_root" -name '*.ttf' -type f)
  rm -rf "$extract_root"

  if [[ "$ttf_count" -eq 0 ]]; then
    die "No .ttf files found in Nerd Font archive — wrong NERD_FONT_FAMILY or corrupt zip."
  fi

  if [[ "$OS" == linux ]] && command -v fc-cache >/dev/null 2>&1; then
    fc-cache -f "$dest_dir" 2>/dev/null || true
  fi

  touch "$marker"
  log "Installed $ttf_count Nerd Font file(s) into $dest_dir"
}
