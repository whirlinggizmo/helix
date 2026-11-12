# Benchmarks

Two pages, each written by a tool from the numbers it keeps.

- **[sizes.md](sizes.md)**, from `tools/measure_sizes.py --write` and `sizes.json`: each library's and engine's web size ladder, a
  program a rung, each adding one feature to the one before, so a rung's increment is what the feature costs, gzip and brotli. The
  baseline CI holds to: a rung more than 1% and 1 KB larger fails `helix.py test`. helix-raylib's window is 34.5 KB gzip, its game rung
  (a skinned model, textures, a font, audio, input, a save, a shader, a render texture, raygui) 134.6 KB, and everything it has 308.1 KB.
- **[speed.md](speed.md)**, from `tools/compare/compare.py --write` and `speed.json`: helix-raylib against raylib C, Godot, three.js
  and helix-legacy on two programs, raylib's bunnymark and its robots, in a page over Vulkan and over GL and natively, with each contender's
  size. Each contender's row keeps the date it was measured.

What they say together: helix-raylib's pages are under half of raylib wasm's download, and two fifths to a half of a three.js
game's. On the bunnymark it draws about three times as fast as raylib C, in a page and natively, and a fifth slower than three.js's
instanced sprites in a page. On the robots it is twice as fast as three.js in a page and level with raylib wasm's GPU skinning, and
twice as fast as raylib C natively.
