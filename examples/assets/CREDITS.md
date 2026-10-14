# Asset credits

The files under `examples/assets/` that HeliX didn't make, with each one's source and license. Every build copies this folder as it is, so a credit here goes with the files.

| File | Work | Author | Source | License |
| --- | --- | --- | --- | --- |
| `music/a_hero_is_born.mp3` | "A Hero Is Born", its first 90 s | HoliznaCC0 | [Free Music Archive](https://freemusicarchive.org/music/holiznacc0/retro-gamer-soundtrack/a-hero-is-born/) | [CC0](https://creativecommons.org/publicdomain/zero/1.0/) |
| `fonts/JetBrainsMono/JetBrainsMono-Regular.ttf` | JetBrains Mono | JetBrains | [jetbrains.com/mono](https://www.jetbrains.com/lp/mono/) | [SIL OFL 1.1](fonts/JetBrainsMono/OFL.txt) |
| `fonts/Komika/KOMIKAH_.ttf` | Komika Hand | Apostrophic Laboratories | the font's [readme](fonts/Komika/readme.txt) | freeware, redistributed unmodified ([readme](fonts/Komika/readme.txt)) |
| `models/car-kit/sedan-sports.glb`, `models/car-kit/Textures/colormap.png` | Car Kit 3.1, its sports car and the kit's shared texture | Kenney | [kenney.nl](https://kenney.nl/assets/car-kit) | [CC0](https://creativecommons.org/publicdomain/zero/1.0/) |
| `models/car-kit/sedan-sports-headlights.gltf`, `.bin` | the same sports car with two headlight spot lights added (Whirling Gizmo, in Blender 5.1; exported as .gltf with a separate buffer, KHR_lights_punctual) | Kenney | [kenney.nl](https://kenney.nl/assets/car-kit) | [CC0](https://creativecommons.org/publicdomain/zero/1.0/) |
| `sounds/click_004.ogg` | UI Audio | Kenney | [kenney.nl](https://kenney.nl) | [CC0](https://creativecommons.org/publicdomain/zero/1.0/) |

CC0 asks for no credit; they're credited anyway.

## Whirling Gizmo's own

- `sprites/logo/wg-logo-bw-alpha.png`, `sprites/logo/wg-logo-white-alpha.png`: the Whirling Gizmo logo, black and white.
- `textures/flame.png`: a generated soft flame, MIT.
- `sprites/logo/wg-logo-bw-alpha.{bc7,astc,etc2}.ktx`, `textures/flame.{bc7,astc,etc2}.ktx`: the PNGs compressed, with their mipmaps, as KTX 1 by Basis Universal 1.16.4 (UASTC level 2, transcoded to BC7, ASTC 4x4 and ETC2 RGBA8).
- `textures/noise.png`: a generated noise texture (the dissolve shader's), MIT.
- `textures/tiles.png`: a generated 16-pixel tile sheet (terrain, props, a coin at 42, 22), MIT.
- `textures/tiles_normal.png`: a generated normal map of bevelled tiles, tangent space (green up), MIT.
- `models/toy_car.glb`: the unit tests' glTF fixture, a generated toy car (a checkered body, a see-through cabin, four wheels, emissive headlights with a spot light each), MIT.
