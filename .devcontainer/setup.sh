#!/usr/bin/env bash
set -euo pipefail
VERSION=4.4.1
mkdir -p "$HOME/.local/bin" "$HOME/.local/share/godot/export_templates/$VERSION.stable"
curl -fL --retry 3 -o /tmp/nex-godot.zip "https://github.com/godotengine/godot/releases/download/$VERSION-stable/Godot_v$VERSION-stable_linux.x86_64.zip"
unzip -oq /tmp/nex-godot.zip -d /tmp/nex-godot
install -m 755 "/tmp/nex-godot/Godot_v$VERSION-stable_linux.x86_64" "$HOME/.local/bin/godot"
curl -fL --retry 3 -o /tmp/nex-templates.tpz "https://github.com/godotengine/godot/releases/download/$VERSION-stable/Godot_v$VERSION-stable_export_templates.tpz"
unzip -oq /tmp/nex-templates.tpz -d /tmp/nex-templates
cp -a /tmp/nex-templates/templates/. "$HOME/.local/share/godot/export_templates/$VERSION.stable/"
echo "Ready: run bash tools/serve_web.sh"
