# NexTgenLeo — Professional art delivery contract

**Engine** Godot 4.4.1 / GL Compatibility. Primary target Android/Web, PC for QA. The gameplay code and 200-slot/19-equip-slot UI already exist. Artists should deliver **assets only**, not rewrite gameplay systems.

## Ready-to-use manifest

`content/asset_manifest.json` is committed with empty paths. Empty paths deliberately keep the existing procedural characters and map placeholders.

1. Prepare each imported/rigged asset as a **Godot PackedScene (.tscn)** under `res://content/`.
2. Populate `characters.Male`, `characters.Female`, and/or `zones["0"]` through `zones["4"]` with a path like `res://content/characters/male.tscn`.
3. Build and test the Godot Web export. The loader rejects paths outside `res://content/`, non-.tscn files, and missing scenes; the procedural fallback stays available.
4. Character scenes are attached under the height-scaled avatar transform; the original movement collision, game state, skills and inventory are not replaced. Zone scenes attach as authored **scenery**, hiding the temporary camp; existing quest/NPC/monster spawn logic remains in gameplay code.

**Important:** this is a **visual scene loading hook**, not automatic animation retargeting, cloth skinning or pathfinding for authored geometry. Those are separate integration/QA steps when actual files arrive.

## Character model contract

| Asset | Requirement |
|---|---|
| Male / Female | One .tscn root Node3D each; origin at ground/feet, facing forward consistently |
| Geometry | Modular body preserved beneath clothing, including abdomen for cropped shirts |
| Rig | Skeleton3D with documented bone list and bind/rest transforms; keep one skeleton per model |
| Materials | Embedded or linked PBR BaseColor/Normal/ORM textures, no missing external dependencies |
| Animations | Named Idle, Walk, Run, Jump, Fall, Basic1, Basic2, Basic3, Dodge, Death and job-specific skills |
| Weapons | Document sockets/attachment points for right hand, left hand and back; align to animation |
| Compatibility | GL Compatibility/Web/Android shader support, no platform-specific unsupported effects |

### Equipment slots that the models must support

**Combat armor:** `hat`, `shirt`, `gloves`, `pants`, `shoes`.

**Weapons:** `weapon` (right hand), `weapon_left` (left hand).

**Mount / loot:** `mount`, `loot_pet`.

**Jewelry:** `ring`, `bracelet_left`, `accessory` (necklace), `bracelet_right`, `ring_right`.

**Fashion overrides:** `fashion_hat`, `fashion_shirt`, `fashion_gloves`, `fashion_pants`, `fashion_shoes`.

Fashion is a **visual override**, not an additional combat-stat boost. Clothing must cover the required body segments without accidentally hiding exposed abdomen. For all item packs, supply the item icon PNG and a matching in-world mesh plus rig/skin weights where relevant. Do not remove equipment metadata IDs from `data/balance.json`.

## World art contract (five map scenes)

| Zone index | Design name | Folder suggestion |
|---|---|---|
| 0 | Starter Forest | `content/zones/starter_forest.tscn` |
| 1 | Azure Coast | `content/zones/azure_coast.tscn` |
| 2 | Amber Highlands | `content/zones/amber_highlands.tscn` |
| 3 | Frost Hollow | `content/zones/frost_hollow.tscn` |
| 4 | Twilight Reach | `content/zones/twilight_reach.tscn` |

Each scene should contain a **Node3D root**, validated static collision, navigation geometry for later bake, authored lighting compatible with GL, safe-zone ground, NPC locations, portals and clear monster spawn regions. Suggested named markers: `PlayerSpawn`, `SafeZone`, `QuestNPC`, `PortalToNext`, `MonsterSpawns`, `BossSpawn`.

Do not assume the existing procedural spawns already read these markers; gameplay marker linking and NavMesh baking are required at final art integration. Maintain clear movement paths at the existing placeholder spawn coordinates until integration is completed.

## Delivery package

- Male scene, female scene, all textures/materials, original rig and source FBX/GLB/Blender exports
- Map scenes with static collisions and documented spawn markers
- Consistent scale (Godot world uses meters) and a T-pose or A-pose bind reference
- Naming sheet for slot attachments and bone names
- Production usage/license rights and source attribution if third-party items are included
- Preview screenshots and a low-end Android/Web export performance report

**Acceptance before release:** verify 3D model loading, gender swap, 19 equipment slots, cloth visibility, run/attack animation sync, all five zone entries, player collision, NPC access, real-device mobile FPS/memory, and multiplayer authority without uploading local saves.
