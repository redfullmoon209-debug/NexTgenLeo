# NexTgenLeo — Integrated systems & HUD delivery status

**Goal:** one repository and one integrated test/review flow; user supplies final professional models/maps in a later asset drop. **This is not a completed live-service MMORPG** until the remaining production tasks below are implemented and tested.

## Included in the integrated systems/HUD PR

- **Navy-and-silver HUD**: character/class/level display, numeric HP/Stamina/EXP, currency label, quest tracker, target frame with HP, pet/auto-hunt/buff status, shadowed action controls and faction-aware outlines
- **Responsive button layout**: retain current configurable action offsets, clamp action buttons inside the viewport, keep left game world unobstructed and preserve the separate GM orb / yellow main dropdown
- **200-slot inventory / 19 equipment slots**: original equip and fashion system remains; add selectable multi-stack selling with explicit confirmation and an atomic state operation (invalid selections change nothing)
- **Auto-hunt preferences**: save/reload enabled hunting skills and search radius through the current versioned offline settings
- **Art integration**: validated local manifest + optional Male/Female/5-zone PackedScene hooks with procedural fallbacks, and a documented artist delivery contract
- **Regression coverage**: Godot state tests + Chromium interaction/layout checks; do not merge until CI passes

## Systems already present in the repo (development sandbox)

Class 0–10, levels 1–100, Class 3 six elements, Class 5 twelve professions, Class 7 Light/Dark, three skills + basic combat, stamina, auto-hunt, NPC starter quest, five placeholder zone variants, normal/elite/boss tags, loot and auto-loot pet, respawn, shops/currency, inventory/equip, offline GM tools, versioned offline saves, drag/resize foundation for action buttons.

An **optional** separate Python/aiohttp/SQLite test server exists, with server authority for a subset of movement, combat, experience, economy, inventory, quests and chat. GitHub Pages does **not** host this multiplayer backend.

## Still NOT production-complete

1. **Production online operation:** registered accounts/login/recovery, TLS hosting, secure owner role/GM action authorization, monitoring, backups/migrations, scalable persistence, reconnect, load testing and deployment.
2. **Multiplayer gameplay:** robust player-to-player interactions, trading/escrow, guilds, party progression, PvP and faction wars, player revival, anti-cheat review.
3. **High-level combat:** detailed 12-profession skills and skill animation/effects, Sovereign unlock (not designed yet), final element advantage/balance and scalable AI/pathfinding.
4. **World content:** five actual authored maps, nine distinct mobs and boss per map, multiple quests and NPCs, complete pets/mount gameplay.
5. **Art:** imported professional character rigs, animations, modular clothing and weapon rigs, all icons, VFX, sound and performance LOD work.
6. **Device and platform sign-off:** actual Android/iOS device FPS/battery/thermal tests, accessibility/font checks, export and store requirements.

Do not mark any of the above complete on the basis of a browser sandbox check. Full art integration will require real files and verification. The server's GM authorization and safety controls must be revisited before any public online launch.

## Useful acceptance gates

- Godot import and all state/tests pass
- Chromium desktop + touch gameplay/menu regression passes
- Responsive HUD retains clear avatar/minimap/action-control zones
- Bulk sale checks prevent partial changes or unexpected gold creation
- No professional assets present: both genders and zones fall back to procedural stand-ins
- Once assets arrive: compare imported mesh/skeleton/animations/materials with the existing slots, check GL Compatibility and mobile render speed
- Before production launch: backend authorization, persistence and security tests, mobile device benchmarks, content and networking load tests

**References:** `docs/GAME_PLAN.md` (approved class/job rules), `docs/ART_DELIVERY_CONTRACT.md`, `docs/IMPLEMENTATION_STATUS.md`.
