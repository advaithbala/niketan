#!/usr/bin/env bash
# Write env snippet and inject/remove it from the user's shell rc.

write_env_snippet() {
  local f="$PREFIX/niketan-env.sh"
  cat >"$f" <<'SNIPPET'
# Added by niketan bootstrap — prepend user-local tools
export PATH="__BIN__:$PATH"
alias n=nvim

# Prompt: user@host:/full/path$  (green user@host, blue path)
# Uses only standard ANSI colors (no 256/truecolor assumptions).
if [ -n "$ZSH_VERSION" ]; then
  autoload -Uz colors && colors
  setopt PROMPT_SUBST
  PROMPT='%{$fg[green]%}%n@%m%{$reset_color%}:%{$fg[blue]%}%~%{$reset_color%}$ '
elif [ -n "$BASH_VERSION" ]; then
  PS1='\[\e[32m\]\u@\h\[\e[0m\]:\[\e[34m\]\w\[\e[0m\]\$ '
fi
SNIPPET

  # Patch in the actual BIN path (written at install time)
  sed -i.bak "s|__BIN__|$BIN|" "$f" && rm -f "${f}.bak"
  log "Wrote $f"
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

remove_shell_rc_block() {
  detect_shell_rc

  if [[ ! -f "$SHELL_RC" ]]; then
    log "No shell rc at $SHELL_RC — nothing to clean."
    return 0
  fi
  if ! grep -qF "$MARKER" "$SHELL_RC"; then
    log "No niketan block in $SHELL_RC — nothing to clean."
    return 0
  fi

  local tmp in_block=false
  tmp=$(mktemp)
  while IFS= read -r line || [[ -n "$line" ]]; do
    if [[ "$line" == "$MARKER" ]];     then in_block=true;  continue; fi
    if [[ "$line" == "$MARKER_END" ]]; then in_block=false; continue; fi
    [[ "$in_block" == false ]] && printf '%s\n' "$line" >> "$tmp"
  done < "$SHELL_RC"

  mv "$tmp" "$SHELL_RC"
  log "Removed niketan block from $SHELL_RC"
}

clean_env_snippet() {
  local f="$PREFIX/niketan-env.sh"
  [[ -f "$f" ]] && rm -f "$f" && log "Removed $f"
}
