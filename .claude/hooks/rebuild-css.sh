#!/usr/bin/env bash
# PostToolUse hook for Edit|Write. GitHub Pages doesn't build the CSS, so after
# a Less source in styles/ changes, rebuild dist/css right away.
set -u

file=$(jq -r '.tool_input.file_path // empty')
case "$file" in
  *.less) ;;
  *) exit 0 ;;
esac

root=$(git -C "$(dirname "$file")" rev-parse --show-toplevel 2>/dev/null) || exit 0
case "$file" in
  "$root"/styles/*) ;;
  *) exit 0 ;;
esac

if [ ! -x "$root/node_modules/.bin/lessc" ]; then
  echo "Less changed but node_modules is missing. Run npm ci, then npm run build:css." >&2
  exit 2
fi

if ! output=$(cd "$root" && npm run --silent build:css 2>&1); then
  # lessc colours its errors; strip the escape codes so Claude can read them.
  printf 'npm run build:css failed:\n%s\n' "$output" | sed $'s/\x1b\\[[0-9;]*m//g' >&2
  exit 2
fi

jq -n '{hookSpecificOutput: {hookEventName: "PostToolUse",
  additionalContext: "Rebuilt the compiled CSS with npm run build:css. Commit dist/css/styles.css and styles.min.css with the Less change."}}'
