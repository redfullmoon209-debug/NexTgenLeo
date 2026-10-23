# Portable playtest architecture

This is a single-player **local playtest**, not an authoritative online game. No registration, email provider, database, payment service or GM endpoint has been deployed. Browser data, currencies, buffs and item ownership can be edited by the browser owner and must never be accepted as trusted multiplayer data.

| Layer | Location | Responsibility |
| --- | --- | --- |
| Gameplay rules | `data/rules.json` | Level cap, height curve, ranges/intervals, three prototype skills, capacity, Speed Run tiers; reserved future jobs/elements |
| Item catalog | `data/items.json` | Stable item IDs, icons/models by Asset ID, effects/durations, currency/price, equipment slots |
| Asset catalog | `data/assets.json` | Local file paths, provenance, licenses, checksums |
| Simulation | `src/gameplay.js` | Combat, XP, drops, inventory transactions, buffs, pets, enhancement, save validation |
| 3D adapter | `src/scene.js` | Three.js scene, imported GLB/animations, hand attachment, picking and camera |
| UI | `src/ui.js`, `index.html`, `style.css` | Shop, 200-slot bag, item details, pet controls and status |
| Browser integration | `game.js` | Input ownership, camera gestures, startup, LocalStorage and animation loop |

## Replacing assets

1. Import the new licensed file and its textures to `assets/models/<pack>/` or `assets/icons/` and retain license notices.
2. Update the existing Asset ID's `path` and checksum in `data/assets.json`. Item saves refer to stable item IDs, not file paths.
3. Reuse `weapon.sword`, `weapon.gun`, `weapon.kunai`, `pet.fox` and `character.male/female` IDs. Changes of rig, native dimensions or orientation also require adapter changes in `ForestScene.actor/equipWeapon/pose`.
4. Test hand position, forward axis, clip names, foot placement and level scaling on both character choices. Future modular clothing needs matching rig/weights, body hiding masks, and exposed abdomen geometry. Current clothing is an inventory/equipment-slot prototype only; no fitted modular meshes are claimed.
5. Run `npm run check:assets`, `npm test`, and `npm run test:browser`. Render every changed asset on desktop and mobile viewports before replacing the placeholder.

## Save contract

`nextgenleo_playtest_v2` stores versioned player data, item UID/ID/count/+level, equipped UID references, absolute buff expiry times and pet state. Legacy `nextgenleo_playtest_v1` is read without deleting it. Known legacy item names migrate to IDs. Invalid numbers, coordinates and unknown item definitions are rejected/clamped. GM flags and scale overrides are never imported. Corrupted JSON displays a warning and permits a new session; denied/quota-full storage permits a session with a save warning.

200 slots = two pages of 100. Consumables/materials stack to 99; equipment and pet instances do not stack. Purchases and pickups first validate capacity, so full bags do not consume currency or delete loot. Equipment +levels stay on item instances, and failed enhancement reduces one level without destroying the instance.

## Engine migration / server boundary

Godot/Unreal/Unity clients should consume the same JSON IDs and domain rules, then replace the rendering/input adapter. Height is `0.7 + 0.3 * (level - 1) / 99`. A future server-authorized GM size multiplier belongs outside that curve. Neither visual scale changes combat reach or damage.

Phase 2 must move trusted simulation/state to a separate backend. Clients send intents (move, select target, attack, use item); the server validates identity, ownership, cooldowns, ranges, balances and loot claims. Store character, buff expiry, inventory, pet and dungeon cooldown state transactionally. Add authenticated reconnect and two-session tests before claiming multiplayer. Do not submit this LocalStorage snapshot as authoritative state.

Production Owner GM requires a verified account with an explicit server-side owner user ID, denied ordinary-player tests, validation and an audit log for every action. There is no GM UI or endpoint in this public build; URL parameters never grant a role. That absence is not a claim that a future GM backend is secure.

External services, hosting and email/payment credentials are not configured. Deployment or any cost-bearing provider requires the owner's approval. No real payment controls are enabled.

## Remaining phases

- Phase 2: verified email/auth, authoritative server, database, realtime movement/animation/combat/chat, reconnect; test at least two sessions.
- Phase 3: class advancement quests, all confirmed jobs' full 15-skill catalogs, elemental rules, robust character persistence; keep unconfirmed job slots unnamed.
- Phase 4: ten zones, ten private dungeons, per-dungeon one-hour cooldown starting on successful entry, bosses/world bosses and progression rewards.
- Phase 5: server-persisted pets and pet progression, Daily Quest/60 CP economy, fashion, trade, market, party/guild and separated PvP. The starter pet/shop implemented here are local prototypes, not completion of Phase 5.
