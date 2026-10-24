# Implementation and test status — 2026-10-24

This is a playable **development sandbox**, not a complete or production MMORPG.

## Implemented offline
- Third-person movement, camera follow/orbit, jump/run/dash, mouse zoom, multitouch joystick and pinch input, action buttons, remappable action-button offsets.
- Procedural Male/Female avatars, level/class height scaling, modular equipment visuals, different weapon shapes, simple procedural walk/attack/death motion. No imported skeleton or animation clips.
- Class 0–10 / levels 1–100, EXP, quest gates, six element choices at Class 3, twelve profession choices at Class 5, fixed profession loadout after Class 5, initial/sovereign tier metadata, faction choice at Class 7, AoE/Target switch.
- Basic + three skills, target lock, approach/continuous attacks, critical hits, stamina/cooldown, AoE, auto hunt skill/radius settings.
- Fourteen enemies, normal/elite/boss/world boss tags, chase/leash/flee/respawn, drops, pet loot pickup. One prototype monster species.
- Starter hunt accept/kill/turn-in, NPC auto navigation, sanctuary death/revive and crystal revival, EXP penalty without level loss.
- Inventory 200 slots / 2 pages / stack 99, transactional capacity checking, sorting/use/sell/drop/equip/unequip, +0 equipment and test enhancement, NPC/Cash shops, timed buffs, warp scrolls.
- Following pet, level/EXP, five computed evolution stages; placeholder visual rather than five finished animated pet models.
- Five selectable **prototype zone variants**. They share geometry; these are not five finished designed maps.
- HUD/menu/minimap, settings/performance counters, offline-only GM tools, versioned local JSON saves and periodic autosave.

## Implemented server test
- Separate Python/aiohttp WebSocket authority, SQLite character persistence, opaque development guest sessions, peer movement snapshots, shared monsters, server-owned combat/EXP/loot/currency/inventory, shop/equipment, quest/progression validation, chat and opt-in party room codes.
- Idempotent economic request receipts, transactional rollback, finite/range/type checks, movement distance budgets, combat range/cooldown validation, origin allowlist and message/rate limits.
- Godot optional server connection via Skills > Settings > Multiplayer. Online/offline data is separated; no offline save is uploaded. Unsupported online features and GM are disabled.
- Development guest tokens are not a finished account/password/recovery system. Server test is not hosted by GitHub Pages.

## Verification performed locally
- Exact Godot 4.4.1 editor import, runtime smoke and Web release export.
- 53 gameplay checks: stack/capacity atomicity, purchases/sales, EXP/class gates, element/profession/faction rules, free/fixed skill assignment, height caps, quest lifecycle, actual menu opening, scene spawning, combat, loot, equipment, revive, dispatched multitouch action/joystick isolation, release-over-GUI, pinch input and save/load round-trip.
- 11 Python unittest cases, including two live WebSocket clients, snapshots/chat, persistence/reconnect, duplicate requests, invalid quantities/movement, forged economy/GM, attack range/cooldown, and class/job gates.
- Godot client live WebSocket test: guest handshake/snapshot, authoritative purchase, disconnect/offline restore.
- Browser acceptance and deployment results are recorded separately when completed. Headless checks do not establish device performance or mobile Safari compatibility.

## Not complete / not verified
- Sovereign unlock class, sovereign skill list, detailed element counter relationships, final enhancement/equipment evolution rules: waiting for design details.
- Actual user FBX imports, compatible skeleton/skin weights, Mixamo animation integration, hair physics, professional character art and VFX, full-body status preview.
- Bespoke skill sets/effects per profession, faction-specific combat effects, comprehensive equipment stats and stat allocation, multi-select selling.
- Five finished maps, nine monster species per map, collection quests, robust pathfinding around all obstacles, authored LOD/occlusion, audio/music.
- Pet-specific inventory/abilities and finished five-stage evolution art, equipment evolution system.
- Full party gameplay, guild membership/permissions, trading/escrow, PvP and guild/element/faction wars, player revival of other players.
- Production authentication, operational deployment, TLS hosting, backups/migrations, load/soak/security review and large player counts.
- Real Android/iPhone testing and measured mobile FPS/memory. Desktop software renderer figures cannot predict phone performance.

## Deployment and browser evidence
- Initial integrated sandbox commit 3b197d3: GitHub Actions deployment completed successfully.
- Cloud-browser attempt reached the Godot loader but that environment reports missing WebGL2. This does not verify 3D rendering.
- Local Chromium installation could not start because this execution environment disallows required Unix socket operations.
- A Chromium acceptance job is included in CI to test actual desktop and emulated touch input in a supported runner. Its final run result must be checked before claiming browser acceptance.

- Chromium CI attempt loaded the actual WebGL game and passed movement/menu checks, then caught a wheel zoom failure. Wheel routing was corrected and regression checks added; acceptance rerun required.
