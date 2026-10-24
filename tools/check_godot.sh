#!/usr/bin/env bash
set -euo pipefail
GODOT="${GODOT_BIN:-godot}"
check_run() {
  local task_log
  task_log=$(mktemp)
  if ! "$GODOT" "$@" > "$task_log" 2>&1; then cat "$task_log"; rm -f "$task_log"; return 1; fi
  cat "$task_log"
  if rg -q 'SCRIPT ERROR:|Parse Error:|ERROR:' "$task_log"; then rm -f "$task_log"; return 1; fi
  rm -f "$task_log"
}
check_run --headless --editor --path . --quit
check_run --headless --path . --script res://tests/game_test.gd
check_run --headless --path . --script res://tests/gm_test.gd
check_run --headless --path . --quit-after 120
mkdir -p build/web
# New URLs prevent a browser/CDN mixing the new HTML with cached old game code.
release_stem="game-${GITHUB_SHA:-local-mouse-v1}"
check_run --headless --path . --export-release Web "build/web/$release_stem.html"
for extension in html js wasm pck; do test -s "build/web/$release_stem.$extension"; done
cp "build/web/$release_stem.html" build/web/index.html
touch build/web/.nojekyll
