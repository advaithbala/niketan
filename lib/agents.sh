#!/usr/bin/env bash
# Install / clean CLI coding agents.
# Supported agents: cursor
# Add new agents by implementing install_agent_<name> and clean_agent_<name>.

SUPPORTED_AGENTS="cursor"

print_supported_agents() {
  log "Supported agents: $SUPPORTED_AGENTS"
}

install_agent() {
  local agent="$1"
  case "$agent" in
    cursor) install_agent_cursor ;;
    *)
      log "Unknown agent: $agent"
      print_supported_agents
      return 1
      ;;
  esac
}

clean_agent() {
  local agent="$1"
  case "$agent" in
    cursor) clean_agent_cursor ;;
    *)
      log "Unknown agent: $agent"
      print_supported_agents
      return 1
      ;;
  esac
}

# --- cursor ------------------------------------------------------------------

install_agent_cursor() {
  if command -v cursor >/dev/null 2>&1; then
    log "Cursor CLI already installed ($(command -v cursor))."
    return 0
  fi

  log "Installing Cursor CLI..."
  local installer
  installer=$(mktemp)
  download "https://cursor.com/install" "$installer"
  bash "$installer"
  rm -f "$installer"

  if command -v cursor >/dev/null 2>&1; then
    log "Cursor CLI installed successfully."
  else
    log "Cursor CLI install script finished but 'cursor' not found on PATH."
    log "You may need to open a new shell."
  fi
}

clean_agent_cursor() {
  local cursor_bin
  cursor_bin="$(command -v cursor 2>/dev/null || true)"

  if [[ -z "$cursor_bin" ]]; then
    log "Cursor CLI not found — nothing to clean."
    return 0
  fi

  rm -f "$cursor_bin"
  log "Removed $cursor_bin"

  local cursor_dir="$HOME/.cursor"
  if [[ -d "$cursor_dir" ]]; then
    rm -rf "$cursor_dir"
    log "Removed $cursor_dir"
  fi
}
