#!/usr/bin/env bash
# Portable user-local CLI toolchain (no root). Idempotent: safe to re-run.
# Usage: ./bootstrap.sh
# Automatically detects your shell (bash/zsh/fish) and appends the source line
# to the appropriate rc file. Safe to re-run — the block is only added once.

set -euo pipefail

PREFIX="${PREFIX:-$HOME/.local}"
BIN="$PREFIX/bin"
OPT="$PREFIX/opt"
STATE="$PREFIX/state/niketan"
NVIM_VER="${NVIM_VER:-0.11.0}"

mkdir -p "$BIN" "$OPT" "$STATE"

log() { printf '%s\n' "$*"; }
die() { log "ERROR: $*" >&2; exit 1; }

detect_os_arch() {
  case "$(uname -s)" in
    Linux) OS=linux ;;
    Darwin) OS=macos ;;
    *) die "Unsupported OS: $(uname -s)" ;;
  esac
  case "$(uname -m)" in
    x86_64) ARCH=x86_64 ;;
    aarch64|arm64) ARCH=arm64 ;;
    *) die "Unsupported arch: $(uname -m)" ;;
  esac
}

download() {
  local url="$1" out="$2"
  if command -v curl >/dev/null 2>&1; then
    curl -fsSL --retry 3 -o "$out" "$url"
  elif command -v wget >/dev/null 2>&1; then
    wget -q -O "$out" "$url"
  else
    die "Need curl or wget"
  fi
}

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
    url="https://github.com/neovim/neovim/releases/download/v${NVIM_VER}/${name}"
    tgz="$STATE/$name"
    log "Downloading Neovim $NVIM_VER ($name)..."
    download "$url" "$tgz"
    tar -xzf "$tgz" -C "$OPT"
    extracted=$(find "$OPT" -maxdepth 1 -type d -name 'nvim-linux-*' | head -1)
  else
    case "$ARCH" in
      x86_64) name="nvim-macos-x86_64.tar.gz" ;;
      arm64)  name="nvim-macos-arm64.tar.gz" ;;
      *) die "Unsupported macOS arch: $ARCH" ;;
    esac
    url="https://github.com/neovim/neovim/releases/download/v${NVIM_VER}/${name}"
    tgz="$STATE/$name"
    log "Downloading Neovim $NVIM_VER ($name)..."
    download "$url" "$tgz"
    tar -xzf "$tgz" -C "$OPT"
    extracted=$(find "$OPT" -maxdepth 1 -type d -name 'nvim-macos-*' | head -1)
  fi

  [[ -n "$extracted" ]] || die "Could not find extracted nvim directory"
  ln -sfn "$extracted" "$OPT/nvim-current"
  ln -sfn "$OPT/nvim-current/bin/nvim" "$BIN/nvim"
  touch "$stamp"
}

install_ripgrep() {
  local ver="${RG_VER:-14.1.1}"
  local stamp="$STATE/rg-${ver}.ok"
  [[ -f "$stamp" ]] && return 0

  if [[ "$OS" == linux ]]; then
    local triplet
    [[ "$ARCH" == x86_64 ]] && triplet=x86_64-unknown-linux-musl
    [[ "$ARCH" == arm64 ]] && triplet=aarch64-unknown-linux-gnu
    local name="ripgrep-${ver}-${triplet}.tar.gz"
    local url="https://github.com/BurntSushi/ripgrep/releases/download/${ver}/${name}"
  else
    local triplet
    [[ "$ARCH" == x86_64 ]] && triplet=x86_64-apple-darwin
    [[ "$ARCH" == arm64 ]] && triplet=aarch64-apple-darwin
    local name="ripgrep-${ver}-${triplet}.tar.gz"
    local url="https://github.com/BurntSushi/ripgrep/releases/download/${ver}/${name}"
  fi

  local tgz="$STATE/$name"
  local xdir="$STATE/extract/ripgrep-${ver}"
  rm -rf "$xdir"
  mkdir -p "$xdir"
  log "Downloading ripgrep $ver..."
  download "$url" "$tgz"
  tar -xzf "$tgz" -C "$xdir"
  local binpath
  binpath=$(find "$xdir" -name rg -type f | head -1)
  [[ -n "$binpath" ]] || die "rg binary not found in archive"
  install -m0755 "$binpath" "$BIN/rg"
  touch "$stamp"
}

install_fd() {
  local ver="${FD_VER:-10.2.0}"
  local stamp="$STATE/fd-${ver}.ok"
  [[ -f "$stamp" ]] && return 0

  local triplet name url tgz binpath
  if [[ "$OS" == linux ]]; then
    [[ "$ARCH" == x86_64 ]] && triplet=x86_64-unknown-linux-musl
    [[ "$ARCH" == arm64 ]] && triplet=aarch64-unknown-linux-gnu
  else
    [[ "$ARCH" == x86_64 ]] && triplet=x86_64-apple-darwin
    [[ "$ARCH" == arm64 ]] && triplet=aarch64-apple-darwin
  fi
  # Upstream archives use the "fd-vX.Y.Z-..." prefix
  name="fd-v${ver}-${triplet}.tar.gz"
  url="https://github.com/sharkdp/fd/releases/download/v${ver}/${name}"
  tgz="$STATE/$name"
  local xdir="$STATE/extract/fd-${ver}"
  rm -rf "$xdir"
  mkdir -p "$xdir"
  log "Downloading fd $ver..."
  download "$url" "$tgz"
  tar -xzf "$tgz" -C "$xdir"
  binpath=$(find "$xdir" -path "*/fd-v${ver}-*/fd" -type f 2>/dev/null | head -1)
  [[ -n "$binpath" ]] || binpath=$(find "$xdir" -name fd -type f | head -1)
  [[ -n "$binpath" ]] || die "fd binary not found in archive"
  install -m0755 "$binpath" "$BIN/fd"
  touch "$stamp"
}

install_fzf() {
  local dir="$OPT/fzf"
  local stamp="$STATE/fzf.ok"
  [[ -f "$stamp" ]] && return 0

  if [[ -d "$dir/.git" ]]; then
    git -C "$dir" pull --ff-only || true
  else
    rm -rf "$dir"
    log "Cloning fzf..."
    git clone --depth 1 https://github.com/junegunn/fzf.git "$dir"
  fi
  "$dir/install" --bin --no-update-rc
  # install puts binary in ~/.fzf/bin by default; copy into our PREFIX
  if [[ -x "$HOME/.fzf/bin/fzf" ]]; then
    install -m0755 "$HOME/.fzf/bin/fzf" "$BIN/fzf"
  elif [[ -x "$dir/bin/fzf" ]]; then
    install -m0755 "$dir/bin/fzf" "$BIN/fzf"
  else
    die "fzf install did not produce a binary"
  fi
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

write_path_snippet() {
  local f="$PREFIX/niketan-env.sh"
  cat >"$f" <<EOF
# Added by niketan bootstrap — prepend user-local tools
export PATH="$BIN:\$PATH"
alias n=nvim
EOF
  log "Wrote $f"
}

MARKER="# >>> niketan >>>"
MARKER_END="# <<< niketan <<<"

detect_shell_rc() {
  local shell_name
  shell_name="$(basename "${SHELL:-/bin/bash}")"

  case "$shell_name" in
    zsh)  SHELL_RC="$HOME/.zshrc" ;;
    bash)
      if [[ "$OS" == macos ]]; then
        # macOS bash uses .bash_profile for login shells
        SHELL_RC="$HOME/.bash_profile"
      else
        SHELL_RC="$HOME/.bashrc"
      fi
      ;;
    fish) SHELL_RC="$HOME/.config/fish/config.fish" ;;
    *)    SHELL_RC="$HOME/.profile" ;;
  esac
}

inject_shell_rc() {
  local snippet_path="$PREFIX/niketan-env.sh"

  detect_shell_rc
  log "Detected shell rc: $SHELL_RC"

  if [[ -f "$SHELL_RC" ]] && grep -qF "$MARKER" "$SHELL_RC"; then
    log "Shell rc already contains niketan block — skipping."
    return 0
  fi

  mkdir -p "$(dirname "$SHELL_RC")"

  local block
  block=$(cat <<EOF

$MARKER
[ -f "$snippet_path" ] && . "$snippet_path"
$MARKER_END
EOF
)

  printf '%s\n' "$block" >> "$SHELL_RC"
  log "Appended source block to $SHELL_RC"
}

main() {
  detect_os_arch
  log "Installing to PREFIX=$PREFIX (OS=$OS ARCH=$ARCH)"
  install_neovim
  install_ripgrep
  install_fd
  install_fzf
  write_path_snippet
  install_kickstart_nvim
  inject_shell_rc

  log ""
  log "Done. Your shell rc ($SHELL_RC) has been updated."
  log "Run 'source $SHELL_RC' or open a new shell to activate."
  log ""
  log "Then run: nvim  (or just: n)"
  log "Kickstart help: https://github.com/nvim-lua/kickstart.nvim"
}

main "$@"
