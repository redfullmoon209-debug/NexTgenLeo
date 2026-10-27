# NexTgenLeo art assets

## Current characters
- **Female:** `assets/characters/female/Female.glb` (13 MB) is a supplied model connected through `content/characters/female_visual.tscn`.
- **Male:** No approved production model is configured; the built-in procedural avatar remains the visible fallback.

The source GLB includes a large helper mesh named `Cube`. The female scene explicitly hides that mesh and uses the named humanoid mesh `Arm` for fitted visual bounds; the source GLB itself remains unmodified.

The female scene uses `scripts/imported_character_visual.gd` to determine the model's mesh bounds, rescale to approximately 1.72 meters and align the feet with the gameplay avatar origin. This adapter affects only the visual; player collision, input and combat remain untouched.

The in-game **Character Status > Switch Male / Female** control swaps between the integrated model and the fallback. The inventory 3D preview uses the same visible avatar.

### Integration procedure for additional licensed artwork
1. Import a legally owned GLB into an appropriate `assets/characters/` directory.
2. Create a visual adapter scene under `content/characters/`, supplying the GLB as `source_scene`.
3. Configure a scene path in `content/asset_manifest.json`.
4. Adjust `facing_yaw_degrees` only after checking facing direction in-game.
5. Run `tools/check_godot.sh` and browser screenshot checks before merging.

**Limitations:** This first integration does not implement retargeted skeletal animations, modular clothes, or weapon-to-hand sockets for the imported art. Those require inspection of the GLB skeleton and professional equipment meshes. Offline demo content is not equivalent to a production MMO asset pipeline.
