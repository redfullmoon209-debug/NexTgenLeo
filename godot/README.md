# NexTgenLeo Thailand — Godot 4.4+ starter

This is a separate Godot project inside the existing NexTgenLeo repository, on branch godot-thailand-3d. The old web demo is untouched.

## Run on PC
Open the godot/ folder with Godot 4.4 or later and press F6/F5. WASD moves, hold right mouse button to orbit, mouse wheel zooms. On touchscreens: drag on the left half to move, right half to rotate camera.

## Import Thailand map
Export the Blender scene to glTF Binary (.glb) as godot/assets/maps/thailand.glb. Check exported vertex colors and texture connections. A Blender Mix/Multiply shader does not automatically transfer as an equivalent Godot material. The map will be loaded at runtime if present.

## Browser testing
In Godot, Project > Export > Add Web preset, export to a separate folder. Publish the generated web files with GitHub Pages or another static host. The GitHub repository alone does not execute Godot. Web export has browser and mobile GPU limitations.

## Current status
Initial playable 3D controller and temporary ground only. Actual Thailand .glb asset is not included yet, so do not mistake the placeholder for the final map. Character animations, imported-map collision, and gameplay systems are future work.
