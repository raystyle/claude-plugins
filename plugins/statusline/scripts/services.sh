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
if [[ "$tool_name" == mcp__* ]]; then
  rest="${tool_name#mcp__}"
  if [[ "$rest" == *"__"* ]]; then
    srv="${rest%__*}"
  else
    srv="$rest"
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
config_servers=""
user_settings="$HOME/.claude/settings.json"
if [ -f "$user_settings" ]; then
  config_servers=$(jq -r '.mcpServers // {} | keys[]' "$user_settings" 2>/dev/null || echo "")
fi

project_dir="${CLAUDE_PROJECT_DIR:-}"
if [ -n "$project_dir" ] && [ -f "$project_dir/.mcp.json" ]; then
  proj_servers=$(jq -r '.mcpServers // {} | keys[]' "$project_dir/.mcp.json" 2>/dev/null || echo "")
  config_servers=$(printf '%s\n%s' "$config_servers" "$proj_servers" | sed '/^$/d')
fi

# ── Merge ──
discovered=""
[ -f "$mcp_cache" ] && discovered=$(cat "$mcp_cache" 2>/dev/null || echo "")
all_servers=$(printf '%s\n%s' "$config_servers" "$discovered" | sed '/^$/d' | sort -u)

# ── MCP display — full names
mcp_display=""
if [ -n "$all_servers" ]; then
  mcp_display=$(echo "$all_servers" | tr '\n' ' ' | sed 's/ *$//' | sed 's/  */ · /g')
fi

# ── LSP detection — full names ──
# dir-name → display-name mapping; ps5/ps7 conflict: keep powershell only
lsp_display=""
lsp_names=""
plugin_data_dir="$HOME/.claude/plugins/data"
if [ -d "$plugin_data_dir" ]; then
  has_psh=false
  has_pwsh=false
  for d in "$plugin_data_dir"/*; do
    [ -d "$d" ] || continue
    dirname=$(basename "$d")
    case "$dirname" in
      typescript-inline) lsp_names="${lsp_names}typescript " ;;
      rust-inline)       lsp_names="${lsp_names}rust " ;;
      python-inline)     lsp_names="${lsp_names}python " ;;
      psh5-inline)       lsp_names="${lsp_names}psh5 " ;;
      pwsh7-inline)      lsp_names="${lsp_names}pwsh7 " ;;
      nushell-inline)    lsp_names="${lsp_names}nushell " ;;
    esac
  done
fi

# Marketplace plugins
marketplace_dir="$HOME/.claude/plugins/marketplaces"
if [ -d "$marketplace_dir" ]; then
  for pf in "$marketplace_dir"/*/.claude-plugin/plugin.json; do
    [ -f "$pf" ] || continue
    has_lsp=$(jq 'has("lspServers")' "$pf" 2>/dev/null || echo "false")
    if [ "$has_lsp" = "true" ]; then
      pname=$(jq -r '.name // ""' "$pf" 2>/dev/null || echo "")
      [ -n "$pname" ] && lsp_names="${lsp_names}${pname} "
    fi
  done
fi

# Dedup, sort
if [ -n "$lsp_names" ]; then
  lsp_display=$(echo "$lsp_names" | tr ' ' '\n' | sort -u | sed '/^$/d' | tr '\n' ' ' | sed 's/ *$//' | sed 's/  */ · /g')
fi

# ── Write cache (no formatting — let statusline.sh handle colors) ──
printf "MCP:%s\nLSP:%s" "$mcp_display" "$lsp_display" > "$svc_cache"
