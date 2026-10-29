# NexTgenLeo Thailand - Godot 4 starter

Open the `godot` folder with Godot 4.4+ and press F5.

## Playable prototype and class progression

- Third-person 3D movement, follow camera, touch move/look and keyboard controls.
- Monsters chase and attack; players can fight, take damage, earn EXP/Gold, complete a hunt quest, loot Ore, revive at camp and save locally.
- New characters start as Novice with three active skills. At Lv.10 choose one of six elements; at Lv.15 choose one of six paths; at Lv.30 choose one of two specializations in that path.
- Each final specialization has its own 14-skill deck, including active attacks and automatically unlocked passive buffs. Three active skills are equipped at once. More skills unlock as the character levels.
- Every character level grants one Skill Point. Upgrade an unlocked active skill with one Skill Point plus Gold; rank is capped by character level and damage scales with both level and rank.
- Skills match their job and weapon: weapon reach/power/cooldown vary, area attacks hit groups, support paths can heal and grant team attack/speed/defense buffs, and other paths can buff themselves or reduce enemy armor. Passive skills add job-specific attack, speed, guard and team-buff bonuses.
- Procedural placeholder armor and weapon meshes, +0 to +10 equipment upgrades and a 35% Ore drop chance. Optional Thailand GLB map at `godot/assets/maps/thailand.glb`; the green prototype field remains until it is supplied.

The models use basic Godot meshes as replaceable placeholders. This is still a local prototype: party buffs are prepared to affect party members running this player script, but there is no server-authoritative multiplayer, account system, shared economy or live 20-player tournament yet. The workflow builds an HTML5 export as a GitHub Actions artifact; it does not publish a public Pages site.

## Run and export

Import `godot/project.godot` in Godot 4.4+, wait for import, then press F5. The repository workflow exports a web build from branch `godot-thailand-3d`.

## Safety

This prototype is on branch `godot-thailand-3d`; the main branch remains unchanged. It is not a finished MMO.
