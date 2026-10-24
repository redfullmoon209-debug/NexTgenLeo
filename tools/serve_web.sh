#!/usr/bin/env bash
set -euo pipefail
godot --headless --editor --path . --quit
mkdir -p build/web
godot --headless --path . --export-release Web build/web/index.html
echo "Open Codespaces forwarded port 8080 in a browser"
python3 -m http.server 8080 --bind 0.0.0.0 --directory build/web
