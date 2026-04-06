#!/usr/bin/env bash
# Install / clean Neovim and kickstart.nvim config.

NVIM_VER="${NVIM_VER:-0.11.0}"

install_neovim() {
  local stamp="$STATE/nvim-${NVIM_VER}.ok"
  [[ -f "$stamp" ]] && return 0

  local name url tgz extracted
  if [[ "$OS" == linux ]]; then
    case "$ARCH" in
      x86_64) name="nvim-linux-x86_64.tar.gz" ;;
      arm64)  name="nvim-linux-arm64.tar.gz" ;;
      *) die "Unsupported Linux arch: $ARCH" ;;
    esac
  else
    case "$ARCH" in
      x86_64) name="nvim-macos-x86_64.tar.gz" ;;
      arm64)  name="nvim-macos-arm64.tar.gz" ;;
      *) die "Unsupported macOS arch: $ARCH" ;;
    esac
  fi

  url="https://github.com/neovim/neovim/releases/download/v${NVIM_VER}/${name}"
  tgz="$STATE/$name"
  log "Downloading Neovim $NVIM_VER ($name)..."
  download "$url" "$tgz"
  tar -xzf "$tgz" -C "$OPT"

  if [[ "$OS" == linux ]]; then
    extracted=$(find "$OPT" -maxdepth 1 -type d -name 'nvim-linux-*' | head -1)
  else
    extracted=$(find "$OPT" -maxdepth 1 -type d -name 'nvim-macos-*' | head -1)
  fi

  [[ -n "$extracted" ]] || die "Could not find extracted nvim directory"
  ln -sfn "$extracted" "$OPT/nvim-current"
  ln -sfn "$OPT/nvim-current/bin/nvim" "$BIN/nvim"
  touch "$stamp"
}

install_kickstart_nvim() {
  local target="${XDG_CONFIG_HOME:-$HOME/.config}/nvim"
  if [[ -d "$target/.git" ]] || [[ -f "$target/init.lua" ]]; then
    log "Neovim config already present at $target — skipping kickstart clone."
    return 0
  fi
  log "Cloning kickstart.nvim into $target ..."
  git clone --depth 1 https://github.com/nvim-lua/kickstart.nvim.git "$target"
  log "Kickstart installed. First ':Lazy' sync may take a minute."
}

clean_neovim() {
  rm -f "$BIN/nvim"
  for d in "$OPT"/nvim-linux-* "$OPT"/nvim-macos-* "$OPT/nvim-current"; do
    [[ -e "$d" ]] && rm -rf "$d" && log "Removed $d"
  done

  if [[ "${KEEP_NVIM_CONFIG:-false}" == true ]]; then
    log "Keeping Neovim config (--keep-nvim-config)"
    return 0
  fi

  local target="${XDG_CONFIG_HOME:-$HOME/.config}/nvim"
  local nvim_data="${XDG_DATA_HOME:-$HOME/.local/share}/nvim"
  local nvim_cache="${XDG_CACHE_HOME:-$HOME/.cache}/nvim"
  for d in "$target" "$nvim_data" "$nvim_cache"; do
    [[ -d "$d" ]] && rm -rf "$d" && log "Removed $d"
  done
}
