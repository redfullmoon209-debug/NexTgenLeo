# NexTgenLeo — Godot 4.4.1 3D browser playtest

This is a **separate Godot engine migration prototype**, developed on `godot/3d-browser-playtest`. The Work/Three.js prototype remains intact on `fix/playable-forest-placeholder-assets` for potential Unreal Engine migration. The original HTML/JS files are not overwritten.

## Scope

The Godot scene uses a real 3D world, GL Compatibility renderer, CharacterBody3D, third-person Camera3D, Godot-imported Kenney GLB forest/character/orc models and Khronos Fox.glb where available. It includes desktop/mobile movement, camera rotation/zoom, jumping, target selection, basic combat, drops and an Auto Loot follower. Temporary visuals are not final modular Male/Female characters. There is **no multiplayer server**, email authentication, payment integration, or production persistence.

## Run locally

Open the **repository root** (the folder containing `project.godot`) in Godot 4.4.1, allow the GLB assets to import, then press F6/F5.

Desktop: WASD move; mouse right-drag orbit; mouse wheel zoom; Space jump; Tab target nearest enemy; F attack; Shift dash; left click a monster to select. Mobile: left-side touch joystick, drag right side to rotate camera, two-finger pinch zoom, tap right-side ATK/JUMP/DASH touch zones.

## Browser export

The `Godot 4.4.1 Web Export` workflow builds on the Godot branch and publishes only the generated `godot-playtest/` directory to the `main` branch. With GitHub Pages configured to deploy from `main` / `(root)`, the independent playtest URL is:

https://redfullmoon209-debug.github.io/NexTgenLeo/godot-playtest/

This does not replace the existing site root. Check the Actions build **and open the actual page** on PC/iPhone before calling the browser release verified. If repository settings disallow Actions pushes to main, the workflow artifact can be downloaded and deployment needs a maintainer action.

Licensed placeholder source files stay under `assets/models/` and `assets/licenses/` as supplied by Work. Do not delete the original web prototype.
