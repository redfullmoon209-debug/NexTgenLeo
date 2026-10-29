# NexTgenLeo Thailand - Godot 4 starter

Open the `godot` folder with Godot 4.4+ and press F5.

## Playable prototype

- Third-person 3D movement, follow camera, touch move/look and keyboard controls.
- Ten temporary monsters, target selection, basic attacks, three active class skills, EXP, levels and Gold.
- Twelve temporary jobs with separate stat profiles, weapon names, colors and three skill definitions per job.
- Temporary procedural armor, weapon meshes and +0 to +10 upgrades. Monsters have a 35% chance to drop Ore used for upgrades.
- Hunt quest, healing potion, mobile action buttons and local JSON save/load.
- Optional Thailand GLB map at `res://assets/maps/thailand.glb`; a green prototype field remains until that file is supplied.

The models are generated from basic Godot meshes as replaceable placeholders. These are local single-player mechanics; there is no server-authoritative multiplayer, account system, shared economy, or live 20-player tournament yet. Enemy AI currently follows the player but does not deal damage. The Godot build workflow uploads an HTML5 artifact for signed-in repository access; it does not publish a public Pages site.

## Bring the real Thailand map

In Blender select the desired map objects, then export as glTF Binary (.glb) with UVs and materials. Save as `godot/assets/maps/thailand.glb`. Large files may require Git LFS or a release asset.

## Run and export

Import `godot/project.godot` in Godot 4.4+, wait for import, then press F5. The repository workflow creates a web export artifact from the `godot-thailand-3d` branch.

## Safety

This prototype is on branch `godot-thailand-3d`; the main branch remains unchanged. It is not a finished MMO.
