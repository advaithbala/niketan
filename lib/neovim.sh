#!/usr/bin/env bash
# Install / clean Neovim and kickstart.nvim config.

NVIM_VER="${NVIM_VER:-0.11.0}"

install_neovim() {
  local stamp="$STATE/nvim-${NVIM_VER}.ok"
  [[ -f "$stamp" && -x "$BIN/nvim" ]] && return 0

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

# Parsers to pre-compile at bootstrap time.
# Neovim 0.11 bundles: c, lua, markdown, markdown_inline, query, vim, vimdoc.
# We add commonly-used languages whose parsers nvim-treesitter cannot compile
# without tree-sitter CLI + a C compiler (its async install silently fails in
# headless mode and on first interactive launch the user sees no folds).
NIKETAN_PARSERS=(
  "json|https://github.com/tree-sitter/tree-sitter-json|001c28d7a29832b06b0e831ec77845553c89b56d"
  "python|https://github.com/tree-sitter/tree-sitter-python|v0.25.0"
  "bash|https://github.com/tree-sitter/tree-sitter-bash|a06c2e4415e9bc0346c6b86d401879ffb44058f7"
  "yaml|https://github.com/tree-sitter-grammars/tree-sitter-yaml|4463985dfccc640f3d6991e3396a2047610cf5f8"
  "toml|https://github.com/tree-sitter-grammars/tree-sitter-toml|64b56832c2cffe41758f28e05c756a3a98d16f41"
)

install_nvim_parsers() {
  command -v "$BIN/tree-sitter" >/dev/null 2>&1 || {
    log "tree-sitter CLI not found — skipping parser pre-compilation."
    return 0
  }
  command -v cc >/dev/null 2>&1 || command -v gcc >/dev/null 2>&1 || {
    log "No C compiler found — skipping parser pre-compilation."
    return 0
  }

  local nvim_ts_dir="${XDG_DATA_HOME:-$HOME/.local/share}/nvim/lazy/nvim-treesitter"
  local parser_dir="${XDG_DATA_HOME:-$HOME/.local/share}/nvim/site/parser"
  local queries_dir="${XDG_DATA_HOME:-$HOME/.local/share}/nvim/site/queries"
  mkdir -p "$parser_dir" "$queries_dir"

  for entry in "${NIKETAN_PARSERS[@]}"; do
    IFS='|' read -r lang url rev <<< "$entry"

    [[ -f "$parser_dir/${lang}.so" ]] && continue

    local workdir="$STATE/ts-build/$lang"
    rm -rf "$workdir"
    mkdir -p "$workdir"

    log "  Compiling Treesitter parser: $lang"
    local tgz="$workdir/src.tar.gz"
    download "${url}/archive/${rev}.tar.gz" "$tgz"
    tar -xzf "$tgz" -C "$workdir"

    local src
    src=$(find "$workdir" -maxdepth 1 -type d -name 'tree-sitter-*' | head -1)
    [[ -n "$src" ]] || { log "  WARNING: could not extract $lang parser — skipping."; continue; }

    if ! (cd "$src" && "$BIN/tree-sitter" build -o "$workdir/parser.so" 2>/dev/null) \
         < /dev/null; then
      log "  WARNING: failed to compile $lang parser — skipping."
      rm -rf "$workdir"
      continue
    fi

    cp "$workdir/parser.so" "$parser_dir/${lang}.so"

    local query_src="$nvim_ts_dir/runtime/queries/$lang"
    if [[ -d "$query_src" ]]; then
      ln -sfn "$query_src" "$queries_dir/$lang"
    fi

    rm -rf "$workdir"
  done
  rm -rf "$STATE/ts-build"
}

install_nvim_folding() {
  local target="${XDG_CONFIG_HOME:-$HOME/.config}/nvim/plugin"
  local src="$NIKETAN_DIR/config/nvim/folding.lua"
  [[ -f "$src" ]] || die "Missing $src"
  mkdir -p "$target"
  if [[ -f "$target/folding.lua" ]] && cmp -s "$src" "$target/folding.lua"; then
    return 0
  fi
  cp "$src" "$target/folding.lua"
  log "Installed Treesitter folding config to $target/folding.lua"
}

clean_neovim() {
  [[ -L "$BIN/nvim" || -f "$BIN/nvim" ]] && rm -f "$BIN/nvim" && log "Removed $BIN/nvim"
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
