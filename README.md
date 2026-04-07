# niketan

Portable, user-local CLI development environment. No root required.

Installs **Neovim 0.11**, **ripgrep**, **fd**, **fzf**, and **kickstart.nvim** into `~/.local`, sets up your **tmux.conf**, detects your shell, and wires everything up automatically.

## Quick start

```bash
git clone https://github.com/advaithbala/niketan.git ~/.niketan
cd ~/.niketan
./bootstrap.sh
```

Then open a new shell (or `source ~/.bashrc`) and run `n` to launch Neovim.

### With a CLI agent

```bash
./bootstrap.sh --agent cursor
```

### Without git

```bash
curl -fsSL https://github.com/advaithbala/niketan/archive/refs/heads/main.tar.gz | tar -xz
cd niketan-main
./bootstrap.sh
```

## Teardown

```bash
./clean.sh                          # full teardown
./clean.sh --keep-nvim-config       # keep ~/.config/nvim
./clean.sh --agent cursor           # also remove Cursor CLI
```

Safe to re-run in either direction — bootstrap is idempotent, clean is idempotent.

## What gets installed

| Tool | Version | Purpose |
|------|---------|---------|
| Neovim | 0.11.0 | Editor |
| ripgrep | 14.1.1 | Fast recursive search (`rg`) |
| fd | 10.2.0 | Fast file finder (`fd`) |
| fzf | latest | Fuzzy finder |
| tree-sitter | 0.24.7 | Parser generator CLI (compiles Treesitter grammars for folding) |
| kickstart.nvim | latest | Sane Neovim defaults with Telescope, LSP, Treesitter |
| folding config | — | Treesitter-based code folding (`za` toggle, `zc` close, `zo` open) |
| tmux.conf | — | Versioned tmux config (prefix `Ctrl+a`, vim keys, mouse, catppuccin theme) |
| TPM | latest | Tmux Plugin Manager |
| catppuccin/tmux | v2.1.3 | Catppuccin Mocha theme for tmux |

Everything lives under `~/.local` (`bin/`, `opt/`, `state/niketan/`).

## CLI agents

Agents are opt-in via `--agent <name>`. You can pass multiple `--agent` flags.

| Agent | Command | What it does |
|-------|---------|-------------|
| `cursor` | `--agent cursor` | Installs the [Cursor](https://cursor.com) CLI |

## Repo layout

```
niketan/
├── bootstrap.sh        # orchestrator — install everything
├── clean.sh            # orchestrator — teardown everything
├── config/
│   ├── nvim/
│   │   └── folding.lua # Treesitter-based code folding
│   └── tmux.conf       # tmux configuration
└── lib/
    ├── common.sh       # shared helpers (log, download, detect OS/arch/shell)
    ├── agents.sh       # CLI agent install/clean (cursor, etc.)
    ├── neovim.sh       # neovim + kickstart install/clean
    ├── tools.sh        # ripgrep, fd, fzf, tree-sitter install/clean
    ├── shell.sh        # env snippet + shell rc injection/removal
    └── tmux.sh         # tmux.conf, TPM, catppuccin install/clean
```

## Tested platforms

| Platform | Status |
|----------|--------|
| Ubuntu 22.04 (x86_64) | Working |
| Ubuntu 24.04 (x86_64) | Working |
| macOS (arm64 / x86_64) | Supported, not yet verified |

## Aliases

| Alias | Command |
|-------|---------|
| `n` | `nvim` |
