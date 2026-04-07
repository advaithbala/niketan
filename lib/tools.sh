#!/usr/bin/env bash
# Install / clean ripgrep, fd, and fzf.

install_ripgrep() {
  local ver="${RG_VER:-14.1.1}"
  local stamp="$STATE/rg-${ver}.ok"
  [[ -f "$stamp" && -x "$BIN/rg" ]] && return 0

  local triplet name url
  if [[ "$OS" == linux ]]; then
    [[ "$ARCH" == x86_64 ]] && triplet=x86_64-unknown-linux-musl
    [[ "$ARCH" == arm64 ]]  && triplet=aarch64-unknown-linux-gnu
  else
    [[ "$ARCH" == x86_64 ]] && triplet=x86_64-apple-darwin
    [[ "$ARCH" == arm64 ]]  && triplet=aarch64-apple-darwin
  fi
  name="ripgrep-${ver}-${triplet}.tar.gz"
  url="https://github.com/BurntSushi/ripgrep/releases/download/${ver}/${name}"

  local tgz="$STATE/$name"
  local xdir="$STATE/extract/ripgrep-${ver}"
  rm -rf "$xdir"; mkdir -p "$xdir"
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
  [[ -f "$stamp" && -x "$BIN/fd" ]] && return 0

  local triplet name url
  if [[ "$OS" == linux ]]; then
    [[ "$ARCH" == x86_64 ]] && triplet=x86_64-unknown-linux-musl
    [[ "$ARCH" == arm64 ]]  && triplet=aarch64-unknown-linux-gnu
  else
    [[ "$ARCH" == x86_64 ]] && triplet=x86_64-apple-darwin
    [[ "$ARCH" == arm64 ]]  && triplet=aarch64-apple-darwin
  fi
  name="fd-v${ver}-${triplet}.tar.gz"
  url="https://github.com/sharkdp/fd/releases/download/v${ver}/${name}"

  local tgz="$STATE/$name"
  local xdir="$STATE/extract/fd-${ver}"
  rm -rf "$xdir"; mkdir -p "$xdir"
  log "Downloading fd $ver..."
  download "$url" "$tgz"
  tar -xzf "$tgz" -C "$xdir"

  local binpath
  binpath=$(find "$xdir" -path "*/fd-v${ver}-*/fd" -type f 2>/dev/null | head -1)
  [[ -n "$binpath" ]] || binpath=$(find "$xdir" -name fd -type f | head -1)
  [[ -n "$binpath" ]] || die "fd binary not found in archive"
  install -m0755 "$binpath" "$BIN/fd"
  touch "$stamp"
}

install_fzf() {
  local dir="$OPT/fzf"
  local stamp="$STATE/fzf.ok"
  [[ -f "$stamp" && -x "$BIN/fzf" ]] && return 0

  if [[ -d "$dir/.git" ]]; then
    git -C "$dir" pull --ff-only || true
  else
    rm -rf "$dir"
    log "Cloning fzf..."
    git clone --depth 1 https://github.com/junegunn/fzf.git "$dir"
  fi
  "$dir/install" --bin --no-update-rc
  if [[ -x "$HOME/.fzf/bin/fzf" ]]; then
    install -m0755 "$HOME/.fzf/bin/fzf" "$BIN/fzf"
  elif [[ -x "$dir/bin/fzf" ]]; then
    install -m0755 "$dir/bin/fzf" "$BIN/fzf"
  else
    die "fzf install did not produce a binary"
  fi
  touch "$stamp"
}

clean_tools() {
  for b in rg fd fzf; do
    [[ -L "$BIN/$b" || -f "$BIN/$b" ]] && rm -f "$BIN/$b" && log "Removed $BIN/$b"
  done
  [[ -e "$OPT/fzf" ]] && rm -rf "$OPT/fzf" && log "Removed $OPT/fzf"
  [[ -d "$HOME/.fzf" ]] && rm -rf "$HOME/.fzf" && log "Removed $HOME/.fzf"
}
