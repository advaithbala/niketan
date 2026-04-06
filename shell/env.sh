# Source from ~/.bashrc / ~/.zshrc after running bootstrap.sh, e.g.:
#   [ -f "$HOME/.local/niketan-env.sh" ] && . "$HOME/.local/niketan-env.sh"
#
# Or from a checkout of this repo (replace with your clone path):
#   . "/path/to/niketan/shell/env.sh"

if [ -f "${HOME}/.local/niketan-env.sh" ]; then
  # shellcheck source=/dev/null
  . "${HOME}/.local/niketan-env.sh"
elif [ -d "${HOME}/.local/bin" ]; then
  export PATH="${HOME}/.local/bin:${PATH}"
fi

alias n=nvim
