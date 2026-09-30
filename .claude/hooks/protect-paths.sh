#!/usr/bin/env bash
# PreToolUse hook for Edit|Write. Refuses edits to files that aren't sources:
# _site/ is Jekyll's build output, dist/css/ is built from styles/, and
# styles/bootstrap/ is Bootstrap 3.4.1, vendored unmodified.
set -u

file=$(jq -r '.tool_input.file_path // empty')
case "$file" in
  */_site/*)
    echo "_site/ is Jekyll's build output. Edit the source file instead and rebuild with bundle exec jekyll build." >&2
    exit 2 ;;
  */dist/css/*)
    echo "dist/css/ is built from styles/. Edit styles/main.less or styles/variables.less instead; the CSS is rebuilt after the edit." >&2
    exit 2 ;;
  */styles/bootstrap/*)
    echo "styles/bootstrap/ is Bootstrap 3.4.1, vendored unmodified. Override variables in styles/variables.less or add rules to styles/main.less instead." >&2
    exit 2 ;;
esac
exit 0
