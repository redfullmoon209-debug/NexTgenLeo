# Development server

Python 3.12:

```bash
python -m venv .venv
source .venv/bin/activate
pip install -r server/requirements.txt
python server/server.py
```

Default listen: `127.0.0.1:8765`. Health: `/health`; game socket: `/ws`.
In the game open **Skills > Settings > Multiplayer development server**.
For local HTTP testing connect to `ws://127.0.0.1:8765/ws`.

For external devices use a separately hosted TLS reverse proxy exposing `wss://YOUR_HOST/ws`; forward to this service. HTTPS Pages cannot connect to insecure remote `ws://`. Do not change the GitHub Pages URL to the server URL. Hosting is not purchased or provisioned by this repository.

Environment:
- `LEO_DB`: SQLite file path. Persist and back it up outside the checkout.
- `LEO_HOST`: bind address (default loopback). Set `0.0.0.0` only behind an appropriate proxy/firewall for a test environment.
- `PORT`: port, default 8765.
- `LEO_ORIGINS`: comma-separated browser Origin allowlist. Defaults to the target Pages origin and localhost:8060. Never use `*` for authenticated browser deployments.

The development client obtains an opaque guest bearer token and stores it separately for each server endpoint. There is no password recovery, no payment integration and no production GM endpoint. Keep test currency distinct from real purchases.

Every mutation has a request ID. Repeating the same ID returns the original receipt; it does not charge or grant twice. The server loads catalog prices and damage values itself. Client-supplied balances, inventory, EXP, damage and GM commands are not trusted. This implementation is a starting point, not a claim of complete anti-cheat or production readiness.

Tests:

```bash
cd server
python -m unittest -v
```

The Godot connection test can be run while the server is running:

```bash
godot --headless --path . --script res://tests/network_test.gd
```
