# ผลทดสอบ NexTgenLeo · Playtest 02

Date: **2026-10-23**. Scope: Phase 1 and the requested local item/weapon/pet placeholders. This report does not certify production MMORPG, multiplayer, payment or GM security.

## Baseline and startup findings

Base: `main` at `352a8024ee29879ccbb8e25ea3cc18b48aa4ddd3`.

- A clean baseline session in Chromium rendered the original canvas prototype (1280×745 drawing buffer, no JavaScript exception). The latest main already contained earlier fixes for hidden-canvas sizing and a commented-out start function; this investigation did **not** reproduce a black world with a fresh save on that commit.
- A malformed LocalStorage save (`{corrupt`) threw an uncaught JSON parse error and prevented startup. Reproduced before changes; now covered by a recovery warning and a passing browser regression.
- Startup now validates save values, handles denied/quota-full storage, sizes the canvas after it becomes visible, and renders a lit scene before loading models. Module/model/texture failures display an explicit error; required model loads have a 30-second timeout.
- During integration the Kenney GLBs were found to reference external `Textures/colormap.png`. Each pack now keeps its own original sidecar texture. The asset check validates these dependencies, and an intentionally missing texture produces a diagnostic instead of a silently broken scene.
- Real multitouch testing found secondary fingers do not reliably emit synthetic `click`. Action buttons now process `pointerdown`, independently of joystick ownership. A held stick is superseded by the ATK intent; a new movement intent cancels auto attack. Both orientations test a real kill while the stick and ATK finger are held together.

## Verification results

| Check | Result / evidence |
| --- | --- |
| Domain rules | **19/19 pass** with `npm test` |
| Asset provenance and file integrity | **48 assets / 26 item definitions** verified, including GLB sidecar textures |
| Browser scenarios | **14/14 pass**; machine-readable record: [browser-report.json](evidence/browser-report.json) |
| Desktop | Chromium, 1440×900, real rendering and mouse/keyboard interaction |
| Mobile portrait | Chromium touch emulation, 393×851 CSS pixels, DPR 2, female placeholder |
| Mobile landscape | Chromium touch emulation, 844×390 CSS pixels, DPR 2, male placeholder |
| Pages-style path | All browser tests run under `/NexTgenLeo/`, rather than the site root |
| Normal gameplay errors | No JavaScript/console errors or HTTP failures in the successful scenarios |
| Deliberate failure cases | Corrupt save, denied storage, missing model and missing texture were exercised; failures are visible or recoverable |
| Privilege URL | `?gm_demo=1` does not show a GM control. No GM backend exists; this is not a production authorization audit |

The actual Chromium version and final execution timestamp are in the JSON record. Tests use a software GPU in the development container, **not a physical Windows PC, Android phone, iPhone or Safari**. WebKit was not run because its host runtime libraries are missing. Physical-device performance and Safari compatibility remain unverified.

### Gameplay exercised in the browser

1. Start a character, see ground/trees/player/monsters, move with WASD, Jump and wheel zoom.
2. Click an actual projected monster, press ATK, auto approach, deal real damage, kill and gain 20 EXP. The first drop remains uncollected until LOOT, which adds 5 Gold and the material to the bag.
3. Check all Cash/EXP cards and all shop categories; purchase/use EXP ×2, Attack/Defense/HP buffs. Cash changes from 1,500 to 1,345 for the selected basket. All four advertised EXP durations/prices also have domain-rule tests.
4. Equip Sword/Gun/Kunai, verify hand attachment and screenshots. Enhance Sword to +1 and check the Gold/stone consumption. Switch between two 100-slot pages and use all clothing/accessory slots. +1 through +10 and failed enhancement are covered by domain rules.
5. Summon the Fox, use the Auto Loot Stone, feed it, increase bond, walk and observe its Walk clip. Kill a respawned target with a real skill, then observe the Fox travel to the new drop, remove it once, add its material/Gold and gain Pet EXP. Character EXP becomes 60 (20 before the buff, 40 after).
6. Use City Warp Scroll and reload; verify position, inventory enhancement, equipment references, live buff expiry, pet Auto Loot and currencies persist.
7. In each mobile orientation use actual touch events for joystick and a second action finger, Pinch Zoom and drag camera, then kill while the joystick remains held. Render inventory/shop icons and capture screenshots.

Unit tests additionally cover inventory full/stack boundaries and atomic failure, level height and equal base weapon damage, attack movement lock/queued Jump/Dash cancellation, all three skill effects/SP/cooldowns, buff expiry, hunger/food/bond, pickup-once/full-bag behavior, pet bonuses, non-destructive enhancement, Speed Run exhaustion, revival privileges/EXP loss and one-time starter quest reward.

## Screenshots from the tested game

| Scene | Screenshot |
| --- | --- |
| Before: canvas baseline | [baseline-desktop.png](evidence/baseline-desktop.png) |
| 3D Starter Forest | [desktop-forest.png](evidence/desktop-forest.png) |
| EXP durations / Cash Shop | [desktop-cash-shop.png](evidence/desktop-cash-shop.png) |
| Bag / enhancement details | [desktop-inventory.png](evidence/desktop-inventory.png) |
| Fox after actual Auto Loot | [desktop-pet-loot.png](evidence/desktop-pet-loot.png) |
| Sword / Gun / Kunai | [Sword](evidence/desktop-weapon-sword.png), [Gun](evidence/desktop-weapon-gun.png), [Kunai](evidence/desktop-weapon-kunai.png) |
| Mobile portrait | [forest](evidence/mobile-portrait-forest.png), [inventory](evidence/mobile-portrait-inventory.png), [shop](evidence/mobile-portrait-shop.png) |
| Mobile landscape | [forest](evidence/mobile-landscape-forest.png), [inventory](evidence/mobile-landscape-inventory.png), [shop](evidence/mobile-landscape-shop.png) |

## GitHub Pages verification

The live Pages URL returned HTTP 200. Its `index.html`, `game.js` and `style.css` matched the base main commit byte-for-byte during investigation:

| File | Published SHA-256 |
| --- | --- |
| index.html | `d6422a8e9646993885fa8b3fef52f8e12d318a533e543cb9c3dc7585f31294d5` |
| game.js | `370c9b1361cf6a3d81dc5f5f463fac8b31dc4345ba3299abdbe99841e2e2712e` |
| style.css | `bfe010a58e1a23f73610a174494da4836be9d408b9f693aeb33a7d416821bbd7` |

These changes are on a review branch. **The new version is not claimed live on Pages.** Merge the PR, wait for Pages to deploy that commit, then repeat the live-device smoke test. Local tests include Pages subpath resolution and a versioned entry script/style URL to reduce stale-entry caching.

## Reproduce before merging

```sh
git fetch origin
git switch fix/playable-forest-placeholder-assets
npm ci
npm test
npm run check:assets
npx playwright install --with-deps chromium
npm run test:browser
npm start
```

Open `http://localhost:8080`, create a 3–18 character name, use LOCK → ATK → LOOT, visit the shop/bag, and open the pet panel to summon and activate Auto Loot. The starting supplies and 1,500 Cash are trial data. On a phone on the same network, open the development PC's LAN address on port 8080. Do not expose this development server as a production backend.

## Material limitations / incomplete work

- This is local single-player data. No verified account, authoritative server/database, two-session multiplayer, real payment or secure Owner GM has been implemented or certified.
- Clothing/hair/accessories have real inventory items, icons, detail screens and equipment slots; **fitted modular meshes and body clipping masks are not implemented**.
- Gun is a Kenney Blaster. Kunai is a scaled sword asset. Final character/weapon/pet models, exact combat poses and motion polish remain replaceable placeholders.
- Full Class advancement, six elements, 12 full jobs/15 skills each, world/dungeons/bosses, Daily Quest economy, trade/market/party/guild and PvP remain future phases. Prototype skills, local pet progression and the local starter quest do not complete those phases.
- See [ARCHITECTURE.md](ARCHITECTURE.md) for the engine migration path and server boundaries, and [CREDITS.md](../CREDITS.md) for each asset's rights and attribution.
