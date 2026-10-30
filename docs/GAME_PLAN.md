# NexTgenLeo — active design


## Approved delivery scope — 3 branches first, 6 branches later (2026-10-30)

**User direction:** Finish 3 elemental branches to playable, art-ready quality **before** developing the remaining 3. Preserve the 6-element / 12-profession long-term plan; this is phased delivery, not removal of the six-element design.

**Phase 1 — priority build (3 elements, 6 professions):**
- Select the first 3 elements from Earth, Water, Wind, Fire, Lightning, Wood. **Which 3 are not yet confirmed; do not assume or silently select.**
- Keep 2 profession choices per selected element at Class 5. Deliver each selected profession's 14 skills (active/passive/support as applicable); only 3 active hotbar slots at a time. Class 3 still selects one element and Class 7 still unlocks faction choice.
- Complete the selected paths vertically: progression, class/job selection, skill upgrades using skill points and Gold, skills and combat effects, 3 hotbar actions, character/equipment visuals, UHD skill UI, save/load, input on desktop and mobile.
- Production UI workflow: original separate transparent PNG assets (not cropped from a composite), editable source layers, reusable 9-slice frames, and Godot-generated text/levels/costs for localization. Validate the Godot integration, not just screenshots.
- Release gate: Godot import/export, automated checks, desktop/touch browser checks, and verified deployed build. Prototype definitions alone do not count as a completed path.

**Phase 2 — expansion (remaining 3 elements, total 6 elements / 12 professions):**
- Add the other 3 elemental branches only after the Phase 1 set is working and reviewed.
- Reuse the same 14-skill, skill upgrade, equipment, HUD, UI asset, and persistence systems for 6 more professions.
- Keep old player saves/data compatible and do not delete existing six-element prototype data. Gate availability with configuration or progression rules instead of destructive data removal.

**Current repo caveat:** The balance.json file already has prototype catalogs for all 6 elements and 12 professions, including 14 data entries per profession. They are not 12 completed classes with final bespoke art, animation, effects, balance, or verified gameplay. Defer production completion of the remaining 3 branches.

**Unresolved owner decision:** identify the first 3 elements for Phase 1. Until then, record the scope without hardcoding the active subset.


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
