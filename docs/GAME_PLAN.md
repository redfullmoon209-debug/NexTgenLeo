# NexTgenLeo — active design

## Delivery strategy — improve the existing game, do not restart

**Owner decision (2026-10-30):** Continue fixing and extending the **existing Godot NexTgenLeo repository**. Do **not** create a replacement game or rebuild it from scratch; that would repeat gameplay, UI and integration work already completed. Preserve working save/load, combat, inventory, equipment, GM/testing tools, 3D scene setup, and deployment.

**Working method:** Keep the current playable build as a baseline. Work on short feature branches with end-to-end fixes, test Godot import/export plus desktop/mobile UI controls, and merge only green changes. Replace UI visuals in place with independently authored transparent PNGs, editable source layers, and Godot-native dynamic labels. Reuse the live UI node trees and data bindings wherever possible; do not rewrite functioning mechanics merely for cosmetic work.

**Priorities:** (1) stabilize current playtest and fix concrete broken functions, (2) systematically polish the UHD HUD, inventory, skill window, equipment and menus, (3) complete the first three career paths without player-facing elements, (4) add more gameplay content, paths and eventually an element system only after separate approval. Do not delete legacy six-element prototype data while refactoring or break existing saves.

## Current decision — no elements in the first release (2026-10-30)

**This section supersedes the older 3-element/6-element delivery plan and the element-gated class rules listed in the historical prototype section below.**

### Phase 1 — complete 3 career paths, no element system

- Build and polish **3 playable class/career paths** first, not 3 elements and not 6 professions derived from elements.
- **No player-facing element choice, element requirement, element-based damage/counters, or elemental skill-tree classification** in the Phase 1 release. Skills are organized under careers/weapons rather than elements.
- The exact names, weapons and identities of the 3 initial paths **have not been selected by the owner**. Do not silently choose from the six prototype elements or auto-map old professions.
- Retain a starting character/Novice experience, advancement, EXP/levels, equipment, progression, quests, combat, saved progress and test controls. Revisit the current Class 3 elemental-choice gate and Class 5 job selection during implementation: remove the elemental dependency without inventing a new advancement rule.
- Aim for 14 career-specific skills per chosen path (active, passive and contextual buffs/debuffs as designed), with **3 equipped active skill slots** and an independent basic attack. Upgrade using earned skill points plus in-game Gold. Existing 14-skill templates are placeholders, not finished career skill designs.
- **UHD UI first**: design all UI consistently; author separate transparent original PNG elements and editable layered source files. Never cut assets from a full-screen composite. Render dynamic text, prices, skill levels and localized labels in Godot. Integrate and test each UI module in-game rather than judging by concept art alone.
- Release acceptance: verified Godot build/import/export, save compatibility, controls/combat/skills, desktop and touch browser tests, and a live verified URL.

### Phase 2 — expand from 3 to 6 career paths

- Add **3 more career paths** to reach 6, reusing the same progression, skills, equipment, 3-slot hotbar, UI, data and save-game architecture.
- Do **not** introduce elemental choice automatically in Phase 2. Six career paths and six elemental attributes are separate concepts.
- Preserve existing player progress and prepare non-destructive content migration.

### Phase 3 — optional elements (later, only after owner approval)

- Add elements as a **separate future gameplay layer**, after the basic career system is working and accepted.
- The older Earth/Water/Wind/Fire/Lightning/Wood design and 12 prototype professions are **reference material only**, not a requirement to expose all six elements or twelve professions at launch.
- Do not fix elemental affinity to a profession, set match-up advantages, introduce elemental quests/skill trees or choose an unlock Class until the owner confirms how the new elemental system should work.

### Safe transition from the current repository

- **Planning update only.** The current Godot source still includes a prototype six-element choice at Class 3, element-dependent professions at Class 5 and related data. This document update does not mean the running game has already been converted.
- Keep the prototype definitions and save-game fields in the repository while refactoring. Do not delete or overwrite the existing player saves, item economy or skill progression.
- Implement an element-free career path selection in a separate tested code change; do not remove the legacy system from the live build until tests cover save migration and the three accepted paths.
- Phase 1's 3 career identities and their distinct weapons must be confirmed before final artwork and content authoring.

## Historical reference — superseded element-based prototype rules

The following rules describe the old prototype and should **not** be interpreted as the approved Phase 1 player experience. They remain for migration and possible later elemental expansion.

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
