#!/usr/bin/env bash
# Optional ssh `connect` helper — appended to ~/.local/niketan-env.sh by bootstrap.

NIKETAN_CONNECT_SECRETS="${NIKETAN_CONNECT_SECRETS:-$HOME/.config/niketan/connect-secrets.sh}"

append_ssh_connect_helpers() {
  local f="$1"
  local sec="$NIKETAN_CONNECT_SECRETS"
  {
    printf '\n# --- niketan: ssh connect ---\n'
    printf '# Optional: %s (see config/connect-secrets.example.sh); chmod 600.\n' "$sec"
    printf '[ -f "%s" ] && . "%s"\n' "$sec" "$sec"
  } >>"$f"

  cat >>"$f" <<'NIKETAN_EOF'
connect() {
	if [ -z "${1:-}" ]; then
		echo "usage: connect <number|hostname> [ssh arguments...]" >&2
		return 2
	fi
	local target
	if [[ "$1" =~ ^[0-9]+$ ]]; then
		target="sival-minipc-$1"
	else
		target="$1"
	fi
	shift
	local run_tmux=
	if [ "$#" -eq 0 ]; then run_tmux=1; fi
	if [ -n "$CONNECT_SSH_PASSWORD" ]; then
		if [ -n "$run_tmux" ]; then
			SSHPASS="$CONNECT_SSH_PASSWORD" sshpass -e ssh -t "$target" 'printf "\033]0;%s\007" "$(hostname -s 2>/dev/null || hostname)"; exec tmux a 2>/dev/null || exec tmux new-session'
		else
			SSHPASS="$CONNECT_SSH_PASSWORD" sshpass -e ssh "$target" "$@"
		fi
	else
		if [ -n "$run_tmux" ]; then
			ssh -t "$target" 'printf "\033]0;%s\007" "$(hostname -s 2>/dev/null || hostname)"; exec tmux a 2>/dev/null || exec tmux new-session'
		else
			ssh "$target" "$@"
		fi
	fi
}
NIKETAN_EOF
}

install_connect_secrets_example() {
  local ex="$NIKETAN_DIR/config/connect-secrets.example.sh"
  local dst="$NIKETAN_CONNECT_SECRETS"
  [[ -f "$ex" ]] || return 0
  if [[ -f "$dst" ]]; then
    return 0
  fi
  mkdir -p "$(dirname "$dst")"
  cp "$ex" "$dst"
  chmod 600 "$dst"
  log "Created $dst (empty CONNECT_SSH_PASSWORD — use ssh keys or edit and chmod 600)."
}
