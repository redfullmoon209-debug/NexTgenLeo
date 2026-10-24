# NexTgenLeo — active design

Godot 4.4.1, GL Compatibility, single-threaded browser export. PC + mobile browser first.

## Latest user corrections (2026-10-24)
- Class 0–2: Novice, quest-gated advancement.
- Class 3–4: choose one of Earth, Water, Wind, Fire, Lightning, Wood. Freely assign initial skills within the chosen element.
- Class 5–6: choose a profession belonging to the chosen element. Skills are then fixed by profession, not freely reassigned.
- Class 7–9: Light / Dark faction. Target / AoE mode is separate from loadout assignment.
- Class 10: final class. Levels 1–100 per class; advancement resets level to 1.
- Two skill tiers: **ขั้นแรก (Initial)** and **จอมจ้าว (Sovereign)**. Sovereign unlock requirements and actual skill list are not specified; do not invent them.

## Confirmed professions and weapons

| Element | Profession | Weapon |
| --- | --- | --- |
| Earth | นักสู้พิภพ | Knuckles |
| Earth | จอมหมัดภูผา | Bare fists |
| Water | จอมเวทวารี | Water/ice staff |
| Water | จ้าวสมุทร | Ocean spear |
| Wind | นักฆ่าวายุ | Kunai |
| Wind | จอมยุทธ์พัดวายุ | Fan |
| Fire | นักดาบเพลิง | Dual swords |
| Fire | จอมดาบอัคคี | Greatsword |
| Lightning | พลปืนอัสนี | Single pistol |
| Lightning | มือปืนสายฟ้า | Dual pistols |
| Wood | ผู้พิทักษ์พฤกษา | Vines |
| Wood | จ้าวไพร | Nature staff |

Names remain editable. Data lives in `data/balance.json`. Current skill powers, ranges, costs, enhancement cap/cost and map names beyond Starter Forest are **test balance**, not final approved design. Elemental advantage relationships are intentionally neutral until specified. Initial skill effects are shared prototype effects, not finished bespoke profession animations.

Male/Female original modular FBX files were not found in the accessible repository or Library search. All current characters, equipment, pets and scenery are procedural stand-ins. No user source models were modified. The permanent abdomen is retained when changing shirts. There is no imported production rig/skin binding yet.

See MASTER_COMMAND.md for the original request. These later corrections take precedence where they conflict.
