#!/usr/bin/env bash
# Setup hook: inject statusLine config into user settings if not already configured
set -euo pipefail

settings_file="$HOME/.claude/settings.json"
plugin_root="${CLAUDE_PLUGIN_ROOT:-}"

if [ -z "$plugin_root" ]; then
  exit 0
fi

script_path="$plugin_root/scripts/statusline.sh"

# Read existing settings or start fresh
if [ -f "$settings_file" ]; then
  content=$(cat "$settings_file")
else
  content="{}"
fi

# Check if statusLine already configured
has_statusline=$(echo "$content" | jq 'has("statusLine")' 2>/dev/null || echo "false")

if [ "$has_statusline" = "true" ]; then
  exit 0
fi

# Inject statusLine config using jq
echo "$content" | jq --arg cmd "bash $script_path" \
  '. + { "statusLine": { "type": "command", "command": $cmd, "padding": 1 } }' \
  > "$settings_file"
