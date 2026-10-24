# NexTgenLeo

New **Godot 4.4.1** 3D project, browser-first for PC and mobile. This is a **prototype**, not the finished MMORPG.

## Current playable test
- Procedural forest ground and placeholder character (no external assets)
- PC: WASD move, Shift run, Space jump, drag right side with left mouse button to orbit camera, mouse wheel zoom
- Mobile: left-side touch joystick, RUN and JUMP buttons, drag empty right-side area to orbit camera
- Godot **GL Compatibility** renderer for Web export

## Run in Godot
Open `project.godot` with Godot **4.4.1** and press **F6/F5** (run project: F5).

## Browser test (PC/mobile)
1. Install Godot 4.4.1 **Web export templates** from Editor > Manage Export Templates.
2. Project > Export > Web > Export Project to `build/web/index.html`.
3. Serve `build/web` over HTTP (do not double-click index.html). In Codespaces terminal: `python3 -m http.server 8080 --directory build/web`.
4. In Codespaces **Ports**, set 8080 visibility to Public if you need to open it from your phone. Open the forwarded HTTPS URL on PC or mobile.
5. Web builds need browser WebGL2 support. Test on Chrome Android / Safari iOS. Browser performance depends on device.

## Architecture
- `scenes/main.tscn` — entry scene
- `scripts/main.gd` — temporary 3D prototype, input, touch HUD
- `assets/README.md` — asset import conventions
- `docs/GAME_PLAN.md` — design decisions to validate before implementing full MMORPG

The actual Male/Female modular FBX/GLB assets have **not** been imported. Online multiplayer, inventory, classes, jobs, factions, skills, quests and server are **not implemented**.
