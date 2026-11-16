# Lanternholm, ported

`lanternholm/` is a small program written in TypeScript on three.js: a floating island under a turning sky, with trees to plant and
nubbins to poke. Its `README.md` says what it does, and its `src/` is the whole program. Everything in it is made in code: its
geometry, its textures (drawn on a 2D canvas) and its sound (synthesized). `reference/` holds screenshots of it at 1280 x 720: at dawn,
noon, dusk and night, and close up at noon.

Port it to helix-raylib, as a native program at 1280 x 720. It needn't match it pixel for pixel. Someone who knows the original
should recognise it and find everything it does: the island and what grows on it, the water and the waterfall, the hut and the dock,
the sky with the sun, the moon and the stars, the day passing into night and the light changing with it, the fireflies and dust,
the three tools and their panel, orbiting and zooming the camera, and the sound.

What this is for: finding where raylib's API and helix-raylib's extras fall short for a program like this. So:

- **Port it as raylib allows.** Where raylib or an extra has a call for what three.js does, use it. Where neither has, write what
  the port needs yourself, as a raylib programmer would.
- **NOTES.md is the main result.** Keep it as you go:
  - **Gaps:** each thing three.js gave Lanternholm that raylib and the extras didn't. For each: what three.js gave (its class or
    call), what you wrote in its place, and about how many lines that took. Group them by kind (scene and transforms, materials and
    shaders, lights and shadows, post-processing, geometry, textures, particles and instancing, camera and controls, input, UI,
    sound, other).
  - **Left out or changed:** what you didn't port, or ported differently, and why.
  - **Compile errors:** each one you hit, in order, and what you changed for it.
  - **Guesses:** each place you were left guessing about raylib or an extra, and what you guessed.
- **Options for looking at it:** give the program arguments to start at a time of day (as `--hour=0.5`, 0.25 sunrise, 0.5 noon, 0.75
  sunset), to place the camera, to run a number of frames and to save screenshots, so you can compare it with `reference/`.
