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

### Without git

```bash
curl -fsSL https://github.com/advaithbala/niketan/archive/refs/heads/main.tar.gz | tar -xz
cd niketan-main
./bootstrap.sh
```

## Teardown

```bash
./clean.sh                     # full teardown
./clean.sh --keep-nvim-config  # keep ~/.config/nvim
```

Safe to re-run in either direction — bootstrap is idempotent, clean is idempotent.

## What gets installed

| Tool | Version | Purpose |
|------|---------|---------|
| Neovim | 0.11.0 | Editor |
| ripgrep | 14.1.1 | Fast recursive search (`rg`) |
| fd | 10.2.0 | Fast file finder (`fd`) |
| fzf | latest | Fuzzy finder |
| kickstart.nvim | latest | Sane Neovim defaults with Telescope, LSP, Treesitter |
| tmux.conf | — | Versioned tmux config (prefix `Ctrl+a`, vim keys, mouse) |

Everything lives under `~/.local` (`bin/`, `opt/`, `state/niketan/`).

## Repo layout

```
niketan/
├── bootstrap.sh        # orchestrator — install everything
├── clean.sh            # orchestrator — teardown everything
├── config/
│   └── tmux.conf       # tmux configuration
└── lib/
    ├── common.sh       # shared helpers (log, download, detect OS/arch/shell)
    ├── neovim.sh       # neovim + kickstart install/clean
    ├── tools.sh        # ripgrep, fd, fzf install/clean
    ├── shell.sh        # env snippet + shell rc injection/removal
    └── tmux.sh         # tmux.conf install/clean
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
