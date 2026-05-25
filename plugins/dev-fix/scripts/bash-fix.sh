#!/usr/bin/env bash
# PreToolUse hook for Bash tool:
#   1. Fixes Windows Git Bash CR line-ending issues
#   2. Prepends UTF-8 encoding environment setup
#   3. Auto-activates Python virtual environment (.venv / venv) if found in CWD

set -euo pipefail

# ── Fix Windows Git Bash \r line endings ──
input=$(cat | tr -d '\r')

# Use jq to safely parse JSON and extract command (handles all escape sequences)
original_cmd=$(echo "$input" | jq -r '.tool_input.command // empty' 2>/dev/null) || true

if [ -z "${original_cmd:-}" ]; then
  echo '{"continue":true}'
  exit 0
fi

# ── Build prefix ──
prefix_parts=(
  "chcp.com 65001 > /dev/null 2>&1"
)

[ -z "${PYTHONUTF8:-}" ] && prefix_parts+=("export PYTHONUTF8=1")
[ -z "${PYTHONIOENCODING:-}" ] && prefix_parts+=("export PYTHONIOENCODING=utf-8")
[ -z "${LESSCHARSET:-}" ] && prefix_parts+=("export LESSCHARSET=utf-8")
[ -z "${LANG:-}" ] && prefix_parts+=("export LANG=C.UTF-8")
[ -z "${LC_ALL:-}" ] && prefix_parts+=("export LC_ALL=C.UTF-8")

# ── Prevent MSYS2/Git Bash path mangling ──
[ -z "${MSYS_NO_PATHCONV:-}" ] && prefix_parts+=("export MSYS_NO_PATHCONV=1")
[ -z "${MSYS2_ARG_CONV_EXCL:-}" ] && prefix_parts+=("export MSYS2_ARG_CONV_EXCL='*'")

# ── Auto-detect and activate venv (only for direct python/pip commands) ──
if echo "$original_cmd" | grep -qE '(^|\s|;|&&|\|)(python|pip|pip3|pytest|mypy|black|ruff|flake8|pylint)\b' \
   && ! echo "$original_cmd" | grep -qE '(^|\s|;|&&|\|)(uv|conda|pipx|poetry)\b'; then
  cwd="${PWD:-$(pwd)}"
  for candidate in .venv venv; do
    candidate_path="$cwd/$candidate"
    if [ -f "$candidate_path/Scripts/activate" ] || [ -f "$candidate_path/bin/activate" ]; then
      venv_posix=$(cd "$candidate_path" && pwd)
      if [ -f "$candidate_path/Scripts/activate" ]; then
        activate_path="$venv_posix/Scripts/activate"
      else
        activate_path="$venv_posix/bin/activate"
      fi
      prefix_parts+=("source \"$activate_path\"")
      break
    fi
  done
fi

# Join prefix parts with "; "
prefix=$(IFS='; '; echo "${prefix_parts[*]}")
prefix="$prefix; "

# Build modified command and output as JSON via jq
modified_cmd="$prefix$original_cmd"

jq -n \
  --arg cmd "$modified_cmd" \
  '{
    continue: true,
    hookSpecificOutput: {
      hookEventName: "PreToolUse",
      permissionDecision: "allow",
      updatedInput: { command: $cmd }
    }
  }'
