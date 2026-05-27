#!/usr/bin/env bash
# Setup hook: inject/update statusLine config into user settings
# Always updates the command path so it tracks the current plugin version
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

# Build command — always use POSIX paths.
# execCommandHook runs the command string through Git Bash (spawn with shell=gitBashPath),
# so Windows backslash paths (C:\Users\...) break — backslashes become escape chars.
# The .sh extension triggers auto-prepend of 'bash' in execCommandHook (line 862).
# On non-Windows, 'bash script.sh' works directly.
cmd="bash $script_path"

# Check if command already matches — skip write if unchanged
current_cmd=$(echo "$content" | jq -r '.statusLine.command // ""' 2>/dev/null || echo "")
if [ "$current_cmd" = "$cmd" ]; then
  exit 0
fi

# Inject/update statusLine config using jq, preserve all other fields
# Atomic write via temp file to avoid corruption on failure
tmp_file="${settings_file}.tmp.$$"
echo "$content" | jq --indent 2 --arg cmd "$cmd" \
  '. + { "statusLine": { "type": "command", "command": $cmd, "padding": 1 } }' \
  > "$tmp_file" && mv "$tmp_file" "$settings_file"
