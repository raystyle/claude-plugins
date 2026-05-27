#!/usr/bin/env bash
# Collect MCP/LSP service info, cache per session
# Called on SessionStart and PostToolUse (mcp__* matcher)
set -euo pipefail

input=$(cat | tr -d '\r')
session_id=$(echo "$input" | jq -r '.session_id // "unknown"' 2>/dev/null || echo "unknown")
tool_name=$(echo "$input" | jq -r '.tool_name // ""' 2>/dev/null || echo "")

svc_cache="/tmp/claude-statusline-services-${session_id}.cache"
mcp_cache="/tmp/claude-statusline-mcp-${session_id}.cache"

# ── Extract MCP server name from tool_name (mcp__<server>__<tool>) ──
# Plugin MCP tools: mcp__plugin_<name>_<key>__<tool> → show as <name>
# User MCP tools:  mcp__<server>__<tool> → show as <server>
if [[ "$tool_name" == mcp__* ]]; then
  rest="${tool_name#mcp__}"
  if [[ "$rest" == *"__"* ]]; then
    srv="${rest%__*}"
  else
    srv="$rest"
  fi

  # Strip plugin_ prefix for cleaner display
  if [[ "$srv" == plugin_* ]]; then
    srv="${srv#plugin_}"
    if [[ "$srv" == *_* ]]; then
      srv="${srv%_*}"
    fi
  fi

  existing=""
  [ -f "$mcp_cache" ] && existing=$(cat "$mcp_cache" 2>/dev/null || echo "")
  if [ -z "$existing" ]; then
    echo "$srv" > "$mcp_cache"
  elif ! echo "$existing" | grep -qx "$srv"; then
    echo "$existing"$'\n'"$srv" > "$mcp_cache"
  fi
fi

# ── Configured MCP servers from settings ──
# jq on Windows can't open MSYS paths; pipe content through stdin instead
config_servers=""
user_settings="$HOME/.claude/settings.json"
if [ -f "$user_settings" ]; then
  config_servers=$(cat "$user_settings" | jq -r '.mcpServers // {} | keys[]' 2>/dev/null || echo "")
fi

project_dir="${CLAUDE_PROJECT_DIR:-}"
if [ -n "$project_dir" ] && [ -f "$project_dir/.mcp.json" ]; then
  proj_servers=$(cat "$project_dir/.mcp.json" | jq -r '.mcpServers // {} | keys[]' 2>/dev/null || echo "")
  config_servers=$(printf '%s\n%s' "$config_servers" "$proj_servers" | sed '/^$/d')
fi

# ── Merge configured + discovered via tool use ──
discovered=""
[ -f "$mcp_cache" ] && discovered=$(cat "$mcp_cache" 2>/dev/null || echo "")
all_servers=$(printf '%s\n%s' "$config_servers" "$discovered" | sed '/^$/d' | sort -u)

# ── Plugin scan: detect MCP and LSP from enabled plugins ──
# jq on Windows can't open MSYS paths; use grep + sed instead
lsp_display=""
mcp_display=""

# Get enabled plugin short names from settings (format: "name@marketplace": true)
enabled_names=""
if [ -f "$user_settings" ]; then
  enabled_names=$(cat "$user_settings" | sed -n 's/.*"\([^"@]*\)@[^"]*"[[:space:]]*:[[:space:]]*true.*/\1/p' 2>/dev/null || echo "")
fi

if [ -n "$enabled_names" ]; then
  _plugins_dir="$HOME/.claude/plugins"
  # Build grep pattern: ^name$|^name2$|...
  name_pattern=$(echo "$enabled_names" | tr '\n' '|' | sed 's/|$//; s/|/\\|^/g; s/^/^/')

  # Single scan — output "mcp:name" or "lsp:name" per line
  plugin_services=$(find "$_plugins_dir/marketplaces" -path '*/.claude-plugin/plugin.json' 2>/dev/null | while IFS= read -r pf; do
    pname=$(sed -n 's/.*"name"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' "$pf" | head -1)
    [ -n "$pname" ] || continue
    echo "$pname" | grep -qx "$name_pattern" 2>/dev/null || continue
    grep -q '"mcpServers"' "$pf" 2>/dev/null && echo "mcp:$pname"
    grep -q '"lspServers"' "$pf" 2>/dev/null && echo "lsp:$pname"
  done)

  # Merge plugin MCP into all_servers
  plugin_mcp=$(echo "$plugin_services" | grep '^mcp:' | sed 's/^mcp://' | sort -u | sed '/^$/d')
  if [ -n "$plugin_mcp" ]; then
    all_servers=$(printf '%s\n%s' "$all_servers" "$plugin_mcp" | sed '/^$/d' | sort -u)
  fi

  # Extract plugin LSP
  lsp_names=$(echo "$plugin_services" | grep '^lsp:' | sed 's/^lsp://' | sort -u | sed '/^$/d')
  if [ -n "$lsp_names" ]; then
    lsp_display=$(echo "$lsp_names" | tr '\n' ' ' | sed 's/ *$//' | sed 's/  */ · /g')
  fi
fi

# ── MCP display ──
if [ -n "$all_servers" ]; then
  mcp_display=$(echo "$all_servers" | tr '\n' ' ' | sed 's/ *$//' | sed 's/  */ · /g')
fi

# ── Write cache (no formatting — let statusline.sh handle colors) ──
printf "MCP:%s\nLSP:%s" "$mcp_display" "$lsp_display" > "$svc_cache"
