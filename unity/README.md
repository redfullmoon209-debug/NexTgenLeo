# NexTgenLeo — Unity prototype

This folder is a separate Unity project on branch `unity/nextgenleo`. Existing Godot and Three.js versions remain unchanged.

## Open

1. Install Unity Hub and a Unity 6 editor with Web Build Support and your desired mobile build modules.
2. In Unity Hub select **Add project from disk** and choose the `unity/` folder.
3. In Unity Editor create a 3D scene, add an empty GameObject named `Game`, and attach `NexTgenLeoBootstrap` from `Assets/Scripts`.
4. Press Play. Controls: WASD / arrows move, Space jump, B inventory. The starter scene is generated at runtime; replace placeholders with appropriately licensed models.

## Asset licensing

Fab Standard Licensed assets can generally be used in Unity. Do not import Unreal Engine-only or UE-only licensed content into Unity. Review each product license before importing. Prefer FBX, GLB, textures, and audio files, not `.uasset` files. Do not commit paid/redistribution-restricted assets to a public repository. Git LFS is recommended for permitted large binary assets.

## Deployment

Unity Editor/Web Build Support is required to export WebGL. GitHub Pages can host the exported static files; GitHub alone cannot run the Unity Editor or import models. No Unity web deployment is configured yet.
