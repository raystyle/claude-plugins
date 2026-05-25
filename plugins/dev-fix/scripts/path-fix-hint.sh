#!/usr/bin/env bash
# PostToolUseFailure hook: detect Windows backslash paths in failed Bash commands
# and inject additionalContext to prompt Claude to use forward slashes.
#
# Trigger: Bash tool failure where the command contains drive-letter paths (C:\ D:\ etc.)
# Action:  Return additionalContext hint to correct the paths on retry.

set -euo pipefail

input=$(cat | tr -d '\r')

tool_name=$(printf '%s' "$input" | jq -r '.tool_name // empty' 2>/dev/null) || true

# Only handle Bash tool failures
if [ "$tool_name" != "Bash" ]; then
  echo '{"hookSpecificOutput":{"hookEventName":"PostToolUseFailure"}}'
  exit 0
fi

# Use jq to test if command contains a Windows drive-letter path (X:\)
# jq's test() works on the raw string without bash escape interpretation
has_win_path=$(printf '%s' "$input" | jq -r '(.tool_input.command // "") | test("[A-Za-z]:\\\\")' 2>/dev/null) || true

if [ "$has_win_path" = "true" ]; then
  jq -n --arg ctx \
    'The Bash command failed and contains Windows backslash paths (e.g. C:\ or D:\). In Git Bash, backslashes are escape characters: \t becomes tab, \n becomes newline, \o becomes o, etc. Replace ALL backslashes in file paths with forward slashes: D:\foo\bar should be D:/foo/bar. Never use backslashes in Bash file paths on Windows.' \
    '{
      hookSpecificOutput: {
        hookEventName: "PostToolUseFailure",
        additionalContext: $ctx
      }
    }'
else
  echo '{"hookSpecificOutput":{"hookEventName":"PostToolUseFailure"}}'
fi
