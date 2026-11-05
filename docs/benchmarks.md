# Benchmarks

Two pages, each written by a tool from the numbers it keeps.

- **[sizes.md](sizes.md)**, from `tools/measure_sizes.py --write` and `sizes.json`: each library's and engine's web size ladder, a
  program a rung, each adding one feature to the one before, so a rung's increment is what the feature costs, gzip and brotli. The
  baseline CI holds to: a rung more than 1% and 1 KB larger fails `helix.py test`. helix-raylib's window is 31 KB gzip, its game rung
  (a skinned model, textures, a font, audio, input, a save, a shader, a render texture, raygui) 129 KB, and everything it has 281 KB.
- **[speed.md](speed.md)**, from `tools/compare/compare.py --write` and `speed.json`: helix-raylib against raylib C, Godot, three.js
  and HeliX on two programs, raylib's bunnymark and its robots, in a page over Vulkan and over GL and natively, with each contender's
  size. Each contender's row keeps the date it was measured.

What they say together: helix-raylib's page is a third of raylib wasm's download and two thirds of a three.js game's. On the bunnymark
it draws within 20 to 30% of raylib wasm in a page, matches raylib C natively on SDL_GPU, and both are far behind three's instanced
sprites. On the robots it is ahead of three.js by a third and behind raylib wasm's GPU skinning by a fifth in a page, and ahead of
raylib C natively.
