# Asset credits and licenses

All artwork in Playtest 02 is reused, pre-existing artwork. No AI images were generated. Files are served from this repository, without hotlinks or runtime CDN dependencies. Every imported visual has an Asset ID, source URL, author, license and SHA-256 in `data/assets.json`.

## Kenney

**Mini Dungeon 2.0**, **Mini Forest 1.0**, and **Blaster Kit**, by **Kenney** (https://kenney.nl), under **CC0 1.0** (https://creativecommons.org/publicdomain/zero/1.0/).

- https://kenney.nl/assets/mini-dungeon — human, orc, sword and chest.
- https://kenney.nl/assets/mini-forest — archer, trees, rocks, plants and tent.
- https://kenney.nl/assets/blaster-kit — blaster-d used as the Gun placeholder.

Original pack license notices are in `assets/licenses/`. Original GLB and colormap files are preserved. The Kunai placeholder reuses the sword model at a smaller display scale; it is not a final kunai model. Male/Female selection uses human/archer placeholders; they are not the user's final base meshes.

## Fox

Source: https://github.com/KhronosGroup/glTF-Sample-Assets/tree/main/Models/Fox

- Model: **PixelMannen**, © 2014 Public, **CC0 1.0**.
- Rigging and animation: **tomkranis**, © 2014, **CC BY 4.0**.
- glTF conversion: **AsoboStudio and scurest**, © 2017, **CC BY 4.0**.

License: https://creativecommons.org/licenses/by/4.0/

The original `Fox.glb` is distributed unchanged. Its original attribution and source description are retained in `assets/licenses/Fox-README.md`. Survey and Walk are played by the client. Scaling/orientation occurs at runtime only. The model's CC0 license does **not** override the animation/conversion's CC BY 4.0 requirements.

## Game-icons.net

Icons made by **Lorc**, **Delapouite**, **Skoll**, and **Zeromancer**. Available on https://game-icons.net.

Source repository: https://github.com/game-icons/icons at commit `82d948812bfe3f269ef8f731dcdb07b08160edc4`.

**CC BY 3.0**: https://creativecommons.org/licenses/by/3.0/ for Lorc, Delapouite and Skoll. **CC0** for Zeromancer's `heart-plus.svg`, as specified in the original `assets/licenses/game-icons.txt`.

SVG source files are unchanged. The manifest's `originalPath` identifies each author and original file, e.g. `lorc/broadsword.svg` corresponds to https://github.com/game-icons/icons/blob/82d948812bfe3f269ef8f731dcdb07b08160edc4/lorc/broadsword.svg. Icons are presented with UI frames, duration labels and enhancement badges. This attribution is linked from the character screen and Settings.

## Noto Sans Thai

Noto Sans Thai, The Noto Project Authors (https://github.com/notofonts/thai), **SIL Open Font License 1.1**. Font and original license are in `assets/fonts/`. Source: https://github.com/google/fonts/tree/main/ofl/notosansthai. The font file is unchanged, renamed locally to `NotoSansThai.ttf` for a stable URL.

## Three.js

Three.js **0.180.0**, Copyright © 2010–2025 three.js authors, **MIT**. Full notice in `vendor/three/LICENSE`. Obtained from the npm `three@0.180.0` package (https://www.npmjs.com/package/three/v/0.180.0).

Vendored files: minified core/module builds, GLTFLoader, SkeletonUtils and BufferGeometryUtils. GLTFLoader's BufferGeometryUtils import path is adjusted to the local directory layout. No other modifications to third-party source.
