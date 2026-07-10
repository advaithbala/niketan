# niketan

Portable, user-local CLI development environment: everything niketan installs lands under `~/.local` (or `PREFIX`) without `sudo`.

Your OS image should already include **git**, **tmux**, **ncurses** (`infocmp`), and **curl** or **wget**. **unzip** is required only when bootstrap installs **Nerd Fonts** (local sessions). Niketan does not run package managers for those.

It installs **Neovim 0.11**, **ripgrep**, **fd**, **fzf**, and **kickstart.nvim** into `PREFIX`, **tmux.conf**, detects your shell, and wires up your rc. On a **local** (non-SSH) shell it also installs **JetBrains Mono Nerd Font** and an **Alacritty** profile; over **SSH** those are skipped because glyphs and terminal config belong on the machine where the window is drawn.

### Local vs remote bootstrap

| Where you run `./bootstrap.sh` | Fonts + Alacritty | Neovim, tools, tmux, shell |
|--------------------------------|-------------------|----------------------------|
| Laptop / normal terminal       | yes (default)     | yes                        |
| Over SSH (`ssh user@host`)     | no                | yes                        |

Override when detection is wrong (e.g. [Mosh](https://mosh.org/) may not set SSH vars):

```bash
NIKETAN_SESSION=local ./bootstrap.sh    # force fonts + Alacritty
./bootstrap.sh --local
./bootstrap.sh --remote               # force skip UI (headless CI, etc.)
```

`NIKETAN_SESSION` is `auto` (default), `local`, or `remote`.

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
| Nerd Font (JetBrainsMono zip) | pinned | Icons + tmux powerline curves; flat install into your user font dir |
| alacritty.toml | — | `~/.config/alacritty/alacritty.toml`: same font family, `builtin_box_drawing = false`, Mocha colors |

Everything lives under `~/.local` (`bin/`, `opt/`, `state/niketan/`).

### ssh `connect`

Bootstrap appends an optional **`connect`** function to `~/.local/niketan-env.sh`. Numeric first argument expands to **`sival-minipc-<n>`**; otherwise the first argument is used as the full hostname.

- With **no arguments after** the host, **`ssh -t`** runs **`tmux a`** (or **`tmux new-session`** if none).
- Extra arguments omit tmux and run **`ssh`** with your remote command, as before.
- **`CONNECT_SSH_PASSWORD`**: optional, read from **`~/.config/niketan/connect-secrets.sh`** (create once from **`config/connect-secrets.example.sh`**, **`chmod 600`**). Prefer **SSH keys**.

This file stays under **`~/.config`** so **`./clean.sh`** does not remove your secrets (`./clean.sh` wipes **`~/.local/state/niketan`**, but not `~/.config/niketan`).

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
│   ├── connect-secrets.example.sh # template → ~/.config/niketan/connect-secrets.sh
│   ├── alacritty/
│   │   └── alacritty.toml # template → ~/.config/alacritty (font token filled by bootstrap)
│   ├── nvim/
│   │   └── folding.lua # Treesitter-based code folding
│   └── tmux.conf       # tmux configuration
└── lib/
    ├── common.sh       # shared helpers (log, download, detect OS/arch/shell)
    ├── connect.sh      # ssh `connect` helper + optional secrets install (see README)
    ├── fonts.sh        # Nerd Font download + Alacritty family name mapping
    ├── alacritty.sh    # Alacritty config install/clean
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
| `connect` | ssh helper (hosts `sival-minipc-<n>`, tmux attach, optional `sshpass`) |
