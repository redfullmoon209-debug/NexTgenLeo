# NexTgenLeo verification — 2026-10-24

Runtime source: `92b5b8b3a18cdfaf0c8f6815ed23f8802855d749`.
Final publishing workflow: `f86e50d801dca01f484b35f27427751f443def99`.

| Check | Result |
| --- | --- |
| Godot version | 4.4.1 stable, exact official binary |
| Editor import | Passed, no parse/script errors |
| Gameplay regression checks | 53 passed, 0 failed |
| Runtime smoke | Passed |
| Web release export | Passed; HTML/JS/WASM/PCK present |
| Python server unittest | 11 passed, including live two-client WebSocket test |
| Godot to server | Guest session, authoritative snapshot/purchase and offline restore passed |
| Chromium desktop | Actual WebGL2 scene loaded; movement, Bag, target and wheel passed |
| Chromium emulated touch | Joystick + attack together, release, pinch and player framing passed |
| Browser console | No captured JavaScript or GDScript errors in successful run |
| Real Android/iPhone/Safari | Not tested |
| Production multiplayer | Not deployed; test server requires separate hosting |

[Final release workflow](https://github.com/redfullmoon209-debug/NexTgenLeo/actions/runs/40104267080) is the authoritative deployment result. [Implementation status and remaining work](IMPLEMENTATION_STATUS.md) distinguishes prototypes from finished systems.

## Scope and limits

This is an integrated development sandbox. Procedural characters, weapons, pet and environments are stand-ins. The original Male/Female modular FBX files were not found among accessible sources. Five selectable zones reuse prototype geometry. Sovereign skill unlock rules remain unspecified. Guilds, trading, PvP and wars are not implemented.

The browser runner uses a software graphics backend. Recorded sample FPS varied from 1–2 during startup to around 12–22 in later touch samples; this is not a phone benchmark. The exported release reported static memory as zero/unavailable, so complete browser/WASM memory use is not verified.

The owner Pages Source setting should be GitHub Actions to prevent the implicit README/Jekyll deployment from competing with the game. The available integration cannot change this administration setting. No additional write permission or self-pushing workflow was enabled.

## Reproduce

```bash
GODOT_BIN=godot bash tools/check_godot.sh
python -m unittest discover -s server -v
GODOT_BIN=godot python tools/test_network.py
npm install --no-save --no-package-lock playwright@1.62.1
npx playwright install --with-deps chromium
node tests/browser_test.cjs
```

## Mouse input regression — 2026-10-24
Native PC mouse clicks open/close menus. Left drag works on empty world on either side of the screen; right drag also orbits. UI presses are reserved for controls, and camera drag clears when application focus is lost. Browser export asset names include the release SHA to prevent cached game bundles being reused after updates. Acceptance also covers resize from 1280×720 to 1920×1080; touch regression checks remain enabled.
