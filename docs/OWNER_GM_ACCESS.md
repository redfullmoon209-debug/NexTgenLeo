# Main dropdown and owner-only GM access

The player HUD uses one yellow main-menu button next to the minimap. All standard menus—Bag, Shop, Character, Quest, World, Pet, Auto, Skills, Settings and Connect—are accessible through this dropdown. Keyboard shortcuts remain supported.

The adjacent red **GM** button is **hidden for every unauthenticated visitor** on GitHub Pages. The site is a public static offline sandbox, so it cannot identify a GitHub account on its own. Checking a username in public JavaScript or embedding an admin password in the Web export would be unsafe and would not make the button private.

## Owner activation (trusted development server only)

1. Host the existing `server/server.py` WebSocket server behind TLS (`wss://`).
2. Set `LEO_GM_OWNER_SECRET` **privately on the server** to a unique, random string of **at least 24 characters**. Never commit or put this secret in GitHub Pages, JavaScript, or documentation.
3. From the game, use yellow Menu → Settings → Connect to connect to the server.
4. Select yellow Menu → Settings → "เจ้าของ: ยืนยันสิทธิ์ GM". Enter the private owner secret.
5. The server validates it. Only after a successful `gm_role` response does the separate red GM button appear. Guests, unverified users and disconnected sessions do not see the button.

The role is bound to the authenticated server connection and revoked on disconnect. `gm`/money grants are still rejected by the backend; this change does not introduce production administrator commands. The old GM gameplay panel remains a local test tool and its changes are not sent to the online server. Further production GM actions must be implemented on the authoritative server with explicit authorization checks.

**Security:** Do not share the owner secret. This is server-secret authentication, not GitHub OAuth identity verification. Owner red-button activation on the public web is not possible until a compatible WSS server is actually configured and connected.

## QA

Godot tests verify public menu routing and guest GM denial, and local-only GM controls when the role is explicitly granted in the test. Chromium tests exercise the yellow dropdown on desktop and touch and confirm the GM button is hidden for guests. Python server tests validate owner authentication, rejection of invalid credentials and no privilege escalation via ordinary client commands.
