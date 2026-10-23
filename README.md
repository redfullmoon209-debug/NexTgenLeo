# NexTgenLeo — Web Playtest V1

A dependency-free browser RPG prototype for desktop and mobile. This is **not yet a multiplayer game**.

## What works
- Character name + male/female selection (local demo; no email authentication).
- Canvas-based pseudo-3D forest with trees, monsters, target selection, WASD / touch joystick, drag camera.
- Basic attack (2.2 world units), AoE (4.5 units), HP/SP/EXP, leveling, Gold, starter quest, local inventory.
- Prototype Cash Shop with **no real payments**.
- GM **local-only demo** (optional query parameter `?gm_demo=1`): grant items/Gold/Cash, scale character 30–300%, speed, kill/revive. **This is not secure authorization.** Never use this switch for production GM access.
- LocalStorage save on the same browser/device.

## Run locally
Open `index.html` in a browser, or serve the folder:
```sh
python3 -m http.server 8080
```
Then visit `http://localhost:8080`.

## Deploy
GitHub Pages can host the static demo after the repo owner enables it in **Settings → Pages**, selecting the branch to publish (typically `main` after merging the PR). For a private repository, GitHub plan and Pages visibility rules apply. A static page **cannot** provide shared multiplayer, secure email login, server-authoritative items, or Owner GM.

## Next architecture milestones
1. Auth provider with verified email and protected account IDs.
2. Authoritative game server with realtime transport (WebSocket), character persistence, inventory transactions and anti-cheat.
3. Server-assigned OWNER role, never from client query string; GM action audit log, target validation, and rate limits.
4. Replace canvas prototype with a dedicated 3D client (Godot web export or other web-capable engine), while preserving backend APIs and JSON gameplay definitions.
5. Add zones 1–10, private dungeons 1–10, quests, pet and trade systems incrementally.

## Security
Never publish secrets, owner email, or private keys in this repository. This version is a single-player gameplay prototype, not an online account service.
