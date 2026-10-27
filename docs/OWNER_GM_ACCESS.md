# Yellow player dropdown and red GM test button

The player HUD uses one yellow main-menu button next to the minimap. All standard menus (Bag, Shop, Character, Quest, World, Pet, Auto, Skills, Settings and Connect) are in this dropdown. Existing keyboard shortcuts still work.

## Offline Sandbox (public GitHub Pages)

The red **GM** button is now **visible next to the yellow button** for all visitors to the public **Offline Sandbox**, restoring the original local test workflow. It opens character gender/job/faction selectors and other test tools. These actions affect only the local offline simulation; they do not grant authority over a multiplayer server.

**Important:** The public static page has no owner login. All visitors can open this red offline-test button, not only the project owner. It cannot be made owner-only securely with client-side username checks, a hardcoded password or hidden JavaScript. For truly private GM privileges, use an authenticated server.

## Online servers: GM access remains restricted

When the client begins connecting to an online server, the red GM button is hidden. The server must explicitly confirm an owner's role to show it again. The server-side `gm` and money-grant commands remain blocked even for verified roles until privileged server operations are implemented safely.

1. Host `server/server.py` behind TLS (`wss://`).
2. Set `LEO_GM_OWNER_SECRET` privately on that server to a unique random secret of at least 24 characters. Never commit it to public files.
3. In the game use Yellow Menu → Connect to connect to this trusted server, then Yellow Menu → Settings → เจ้าของ: ยืนยันสิทธิ์ GM.
4. Enter the owner secret. After a successful `gm_role` response the red button becomes visible; the offline GM action panel itself does not operate on online authoritative game state.
5. On disconnect the online role is revoked and the game restores public Offline Sandbox mode.

This owner-secret handshake is not GitHub OAuth identity verification. For a production game, implement server-backed account authentication and authorize every GM action server-side.

## Tests

- Godot: offline GM visibility and functionality, transition to restricted online mode, and button return on disconnect
- Chromium: red GM placement and click on desktop; visible offline GM on mobile; yellow dropdown still works
- Server: owner-secret validation; guests cannot forge online GM authority or run privileged commands
