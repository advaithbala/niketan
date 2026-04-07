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

# True when this shell is the far side of an SSH login (fonts/terminal live on the client).
niketan_is_remote_shell() {
  [[ -n "${SSH_CONNECTION:-}" ]] && return 0
  [[ -n "${SSH_CLIENT:-}" ]] && return 0
  [[ -n "${SSH_TTY:-}" ]] && return 0
  return 1
}

# NIKETAN_SESSION: auto | local | remote (override with env or bootstrap --local / --remote).
# NIKETAN_INSTALL_UI=1 → Nerd Fonts + Alacritty; 0 → skip (Neovim/tools/tmux/shell still run).
detect_niketan_session() {
  case "${NIKETAN_SESSION:-auto}" in
    local)
      NIKETAN_INSTALL_UI=1
      log "Session: local (forced) — Nerd Fonts + Alacritty will run."
      ;;
    remote)
      NIKETAN_INSTALL_UI=0
      log "Session: remote (forced) — skipping Nerd Fonts and Alacritty."
      ;;
    auto)
      if niketan_is_remote_shell; then
        NIKETAN_INSTALL_UI=0
        log "Session: SSH remote — skipping Nerd Fonts and Alacritty (install those on your local machine)."
      else
        NIKETAN_INSTALL_UI=1
        log "Session: local shell — Nerd Fonts + Alacritty will run."
      fi
      ;;
    *)
      die "NIKETAN_SESSION must be auto, local, or remote (got: ${NIKETAN_SESSION})"
      ;;
  esac
  export NIKETAN_INSTALL_UI
}

# Niketan assumes git, tmux, ncurses (infocmp), and HTTP fetch. unzip only when installing UI assets.
check_niketan_prereqs() {
  command -v git >/dev/null 2>&1 || die "git is required"
  command -v curl >/dev/null 2>&1 || command -v wget >/dev/null 2>&1 || die "curl or wget is required"
  command -v bash >/dev/null 2>&1 || die "bash is required"
  command -v tmux >/dev/null 2>&1 || die "tmux is required"
  command -v infocmp >/dev/null 2>&1 || die "infocmp is required (ncurses terminfo database)"

  if [[ "${NIKETAN_INSTALL_UI:-1}" == 1 ]]; then
    command -v unzip >/dev/null 2>&1 || die "unzip is required for Nerd Fonts (or bootstrap over SSH / NIKETAN_SESSION=remote to skip fonts)"
  fi
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
