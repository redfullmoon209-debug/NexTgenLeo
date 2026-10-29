# NexTgenLeo Thailand - Godot 4 starter

Open the `godot` folder with Godot 4.4+ and press F5.

## Playable prototype

- Third-person 3D movement, follow camera, touch move/look and keyboard controls.
- Ten temporary monsters, target selection, basic attacks, EXP, levels, Gold and local saving.
- Twelve temporary jobs. Each job has 14 named skills; three can be equipped at once. The three starting skills are available at level 1, and more unlock as the character levels up.
- Every character level grants one Skill Point. Upgrade an unlocked equipped skill by spending one Skill Point plus Gold. Skill rank is capped by character level, and damage scales with both character level and skill rank.
- Temporary procedural armor and job-themed weapon meshes, weapon/armor upgrades to +10, and a 35% Ore drop chance from monsters.
- Hunt quest, healing potion and mobile action buttons.
- Optional Thailand GLB map at `res://assets/maps/thailand.glb`; a green prototype field remains until that file is supplied.

The models use basic Godot meshes as replaceable placeholders. This is a local single-player prototype: there is no server-authoritative multiplayer, account system, shared economy or live 20-player tournament yet. Enemy AI currently follows the player but does not deal damage. The workflow builds an HTML5 export and stores it as a GitHub Actions artifact; it does not publish a public Pages site.

## Bring the real Thailand map

In Blender select the desired map objects, then export as glTF Binary (.glb) with UVs and materials. Save as `godot/assets/maps/thailand.glb`. Large files may require Git LFS or a release asset.

## Run and export

Import `godot/project.godot` in Godot 4.4+, wait for import, then press F5. The repository workflow exports a web build from the `godot-thailand-3d` branch.

## Safety

This prototype is on branch `godot-thailand-3d`; the main branch remains unchanged. It is not a finished MMO.
