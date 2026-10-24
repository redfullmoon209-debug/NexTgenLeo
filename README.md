# NexTgenLeo - Phase 1+ Godot 4 prototype

## Current state
This clean Godot 4 project contains a visible 3D ground, camera, capsule player, placeholder sword, sphere pet, collectible drops, item catalog, a basic shop/inventory selection UI, EXP x2 timer, and pet follow/pickup logic. All visuals are **built-in Godot primitives or text glyphs**. They are not external art assets, and no third-party models or icon PNGs have been imported yet.

## Run
Open project.godot with Godot 4.4+, then F5. Keyboard arrows (Godot ui_* actions) move. On touch screens, drag on the left half. Select an item in the bottom list; Buy selected purchases with demo Cash, Use selected applies only implemented effects. Pet automatically collects glowing loot spheres into upgrade_stone inventory. This is local prototype behavior only.

## Important limitations
- NOT tested on PC or mobile devices yet; Godot executable and HTML5 export have not been run here.
- The buff icons currently use glyphs, not actual icon art. Attack/Defense/HP buffs, warp, pet food, affinity, enhancement, and many equipment entries are cataloged but not functional.
- The sword is a box placeholder attached to the player; no real mesh or rig is present.
- Pet follows and collects test drops but uses a bobbing motion, not a skeletal walking animation.
- No real Thailand map, multiplayer, authentication, persistence, payment, or real Cash Shop service.

## Licensed asset candidates (NOT YET COPIED)
- Kenney Game Icons: https://kenney.nl/assets/game-icons (CC0)
- Kenney RPG Base: https://kenney.nl/assets/rpg-base (CC0)
- Kenney Mini Characters: https://kenney.nl/assets/mini-characters (CC0, animated character pack)
- Kenney Cube Pets (review source license before import): https://kenney.nl/assets/cube-pets

Official Kenney asset pages state CC0 for the listed packs. See https://creativecommons.org/publicdomain/zero/1.0/ . No artwork from other games is permitted without a compatible license.

## Asset replacement
Keep the stable IDs in scripts/item_catalog.gd. Planned icon paths: assets/icons/<id>.png; planned model paths: assets/models/<id>.glb. The current UI does NOT load these paths automatically yet; they are placeholders for a later integration pass.

## Web build
No browser export has been built or validated from this clean branch. Godot Web export and hosting configuration are still needed before Chrome playtesting.
