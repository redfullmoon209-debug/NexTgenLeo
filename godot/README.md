# NexTgenLeo Thailand - Godot 4 starter

Open the godot folder with Godot 4.4+ and press F5.

Implemented in source:
- 3D third-person placeholder player and follow camera
- WASD, Space jump, right-mouse drag camera, wheel zoom, touch move/look
- 10 placeholder monsters, nearest-target basic attack (J or ATK), EXP and Gold rewards
- Starter Hunt quest (QUEST button): defeat 5 monsters for 100 Gold + 100 EXP
- Potion (H or POTION), HP/Stamina/EXP/Gold status, local JSON save and load
- Optional Thailand map load from res://assets/maps/thailand.glb

Limitations: NOT runtime tested yet. No Thailand mesh/texture file uploaded; temporary ground remains. Monster AI is placeholder chase without damage. No real multiplayer, character selection, shop, skills, equipment UI, mobile export preset, or server. Save is local only.

## Bring the real Thailand map
In Blender select the desired 31 objects (if extracting just map 1), File > Export > glTF 2.0, Format glTF Binary (.glb), Selected Objects. Keep UVs, material images and vertex colors. Save as godot/assets/maps/thailand.glb. Check materials in Godot: Blender Mix/Multiply shader nodes may not transfer identically; bake the visible colors to textures or recreate material in Godot. Large files may require Git LFS or a release asset, not normal GitHub API uploads.

## Test and web export
Import godot/project.godot in Godot, wait for import, press F5. Use Project > Export > Web to build HTML5. Publishing source files to GitHub Pages does not automatically compile Godot. Configure a hosting location for the exported build.

## Safety
Branch: godot-thailand-3d. Existing main branch browser demo remains unchanged. This is an incremental prototype, not a finished MMO.
