#!/usr/bin/env bash
# Headless Neovim smoke test.
# Boots the config with `nvim --headless` and fails if startup emits errors.
# Reuses the user's real nvim data dir so it's fast (<1s once plugins are installed).
# Usage:
#   scripts/smoke-test.sh          # fast startup check
#   scripts/smoke-test.sh --sync   # also run :Lazy! sync (network required)

set -euo pipefail

if ! command -v nvim >/dev/null 2>&1; then
  echo "smoke-test: nvim not found in PATH" >&2
  exit 127
fi

SYNC=0
[[ "${1:-}" == "--sync" ]] && SYNC=1

CMDS=()
if [[ $SYNC -eq 1 ]]; then
  CMDS+=("+Lazy! sync")
fi
CMDS+=("+lua if #vim.v.errors > 0 then for _, e in ipairs(vim.v.errors) do io.stderr:write(e .. '\\n') end vim.cmd('cquit 1') end")
CMDS+=("+qa!")

OUTPUT_FILE="$(mktemp)"
trap 'rm -f "$OUTPUT_FILE"' EXIT

set +e
nvim --headless "${CMDS[@]}" >"$OUTPUT_FILE" 2>&1
STATUS=$?
set -e

# Nvim-specific error markers (avoids matching progress output containing "error" casually).
ERROR_RE='(Error detected while processing|Error executing (lua|vim\.schedule)|^E[0-9]+:|[[:space:]]E[0-9]+:)'

if [[ $STATUS -ne 0 ]] || grep -E "$ERROR_RE" "$OUTPUT_FILE" >/dev/null; then
  echo "smoke-test: FAILED (exit=$STATUS)" >&2
  cat "$OUTPUT_FILE" >&2
  exit 1
fi

echo "smoke-test: OK"
