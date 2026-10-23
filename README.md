# NexTgenLeo · Web Playtest 02

A real-time **local single-player 3D playtest** of Starter Forest, with sourced placeholder models/icons. This is not yet an online MMORPG. No login, backend, payment processor or public GM is enabled.

## Run and test

Node 20+ is sufficient to serve the game; there is no client build step or runtime CDN dependency.

```sh
npm start
# http://localhost:8080
```

For development checks:

```sh
npm ci
npm test
npm run check:assets
npx playwright install --with-deps chromium
npm run test:browser
```

An existing Chromium executable can be supplied with `BROWSER_EXECUTABLE_PATH=/path/to/chromium`. Browser tests start their own HTTP server, mount under `/NexTgenLeo/` to check GitHub Pages paths, exercise real input/gameplay, and save screenshots plus a JSON report under `test-results/`.

## Implemented in this playtest

- A lit Three.js forest, imported Kenney player/enemy/environment models, and real character animation clips. Male/Female choices use two placeholders; height grows from 70% at Lv.1 to 100% at Lv.100.
- PC WASD, mouse drag/wheel camera, Space Jump, Shift Dash, F ATK, 1–3 prototype skills, Tab target, G pickup, X cancel. Hold R for level-gated Speed Run. Mobile joystick, individual action pointers, drag camera and two-finger Pinch Zoom.
- Raycast selection, no-target rejection, automatic approach/basic attacks, real range checks, damage, EXP, leveling, respawn, loot drops, death and revival. Attack animations lock movement; Jump queues, Dash interrupts.
- 200 inventory slots (two pages of 100), stack cap 99, equipment instances, image/details views, three visible weapon placeholders, equipment slots, +1–+10 enhancement with non-destructive failure.
- Local Cash/Gold shop; all four EXP ×2 durations and specified prices; Attack/Defense/HP +20% buffs, warp, revive item, pet supplies and materials. Timed buffs expire using wall-clock time and persist after reload. EXP ×2 permits unlimited on-spot half-HP/SP revives while active.
- A visible animated Fox that follows and travels to dropped loot, moves items/Gold into the bag, gains pet EXP and uses food, hunger, bond treats and an Auto Loot Stone. Capacity is checked before collecting. PvE pet bonuses only.
- Automatic starter hunt and a one-time reward; minimap, HP/SP/EXP, target frame and timed buff icons.
- Validated local saves, known legacy item migration, corrupted/blocked storage warnings, visible module/model/texture failure diagnostics, and resize after showing the canvas.

**Clothing, hats, hair and accessories currently have icons, details and equipment slots, but do not have fitted modular clothing meshes.** Gun uses a Blaster; Kunai uses a scaled-down sword. These are explicitly temporary assets, not final production models or animation polish.

## What remains

Verified email/account auth, unique online names, authoritative server/database, two-session multiplayer, chat/reconnect, server-persisted characters/pets, full class advancement, six elemental systems, 12 full jobs/15 skills each, 10 zones/dungeons, bosses, Daily Quest/CP economy, modular clothing, trade/market/party/guild/PvP and secure Owner GM are not complete. See [architecture and remaining phases](docs/ARCHITECTURE.md).

The browser owner can edit local state. Never trust playtest currencies/items in a production server. No URL grants GM access. All Cash is trial Cash and no real-money purchases are possible.

## Deployment and evidence

GitHub Pages currently serves `main`. This change is proposed on a branch/PR; the live URL does not acquire branch changes until the owner merges and Pages deploys the commit. A Pages build success alone does not validate gameplay. [QA report](docs/QA.md) records baseline findings, test scope, captured evidence and device limitations.

See [asset attribution and licenses](CREDITS.md). Every imported visual is stored in the repository and indexed in `data/assets.json`; no new images were generated.
