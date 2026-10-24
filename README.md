# NexTgenLeo

Godot **4.4.1**, GDScript, GL Compatibility. Browser-first 3D RPG development sandbox.

**Play:** https://redfullmoon209-debug.github.io/NexTgenLeo/

The current build uses procedural placeholder art. It is not a finished MMORPG. See [verified systems and remaining work](docs/IMPLEMENTATION_STATUS.md) and [active game rules](docs/GAME_PLAN.md).

## Controls

PC: WASD move, Shift run, Space jump, left/right drag on empty world to orbit, wheel zoom, TAB lock target, F basic attack, 1–3 skills, R dash, H auto hunt, E pickup, B bag, P shop, C status, Q quest, M world, Esc close/cancel.

Mobile: left joystick, right action buttons, drag empty screen for camera, two camera fingers for pinch zoom. Accept Starter Hunt using Quest > AUTO TO NPC, then Talk to Elara. Select a target before attacking. Pet automatically collects nearby drops while summoned.

Class 3: select element and freely assign initial skills. Class 5: select one of that element's two professions; skill assignment then locks to profession. Class 7: faction. Sovereign skill unlock remains unspecified.

**Skills > Settings** contains quality, save, button layout and optional server connection. GM is an offline testing menu. Local saves stay in the current browser; browser private mode or clearing site data may remove them.

## Build and tests

Open `project.godot` with Godot 4.4.1. Install matching export templates.

```bash
GODOT_BIN=godot bash tools/check_godot.sh
python -m http.server 8060 --directory build/web
```

One Actions workflow validates and exports the Web build, then deploys the built files via GitHub Pages. Pull requests validate/export without deploying. The release uses the non-threaded template so Pages does not need cross-origin isolation headers.

## Multiplayer test

The optional server is separate from static Pages. See [server setup and limitations](server/README.md). Includes authority/persistence/movement/combat/economy/chat and party room groundwork. Guilds, trading, PvP and wars are not implemented.

## Assets

Procedural art was created for this repository. Original user Male/Female FBX files have not been imported because they were not found among accessible files. Noto Sans Thai is redistributed as a static Thai/ASCII subset under [SIL OFL](assets/fonts/OFL.txt).
