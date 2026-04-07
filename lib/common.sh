#!/usr/bin/env bash
# Shared helpers used by all niketan modules.

PREFIX="${PREFIX:-$HOME/.local}"
BIN="$PREFIX/bin"
OPT="$PREFIX/opt"
STATE="$PREFIX/state/niketan"
NIKETAN_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

MARKER="# >>> niketan >>>"
MARKER_END="# <<< niketan <<<"

log() { printf '%s\n' "$*"; }
die() { log "ERROR: $*" >&2; exit 1; }

# Niketan assumes a normal developer OS image: git, tmux, ncurses (infocmp), unzip, and a HTTP client.
# Everything else is installed under PREFIX without root.
check_niketan_prereqs() {
  command -v git >/dev/null 2>&1 || die "git is required"
  command -v curl >/dev/null 2>&1 || command -v wget >/dev/null 2>&1 || die "curl or wget is required"
  command -v unzip >/dev/null 2>&1 || die "unzip is required"
  command -v bash >/dev/null 2>&1 || die "bash is required"
  command -v tmux >/dev/null 2>&1 || die "tmux is required"
  command -v infocmp >/dev/null 2>&1 || die "infocmp is required (ncurses terminfo database)"
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

detect_os_arch() {
  case "$(uname -s)" in
    Linux)  OS=linux ;;
    Darwin) OS=macos ;;
    *)      die "Unsupported OS: $(uname -s)" ;;
  esac
  case "$(uname -m)" in
    x86_64)        ARCH=x86_64 ;;
    aarch64|arm64) ARCH=arm64 ;;
    *)             die "Unsupported arch: $(uname -m)" ;;
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
