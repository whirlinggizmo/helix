# Task: slashing on the run

Write a small raylib program in Haxe (helix-raylib) that shows a character swinging a sword while she runs.

- **Window:** 1280 x 720, targeting 60 frames a second, a camera looking at her from the front and a little to her side.
- **Model:** she is four models in `assets/characters/`, `Adventurer_Head.glb`, `Adventurer_Body.glb`, `Adventurer_Legs.glb` and
  `Adventurer_Feet.glb`, on one shared skeleton. Draw the four, each posed alike. Her animations are in `assets/characters/Animations.glb`,
  named with the armature's prefix (`CharacterArmature|Run`, `CharacterArmature|Sword_Slash`). She needs no sword in her hand.
- **Running:** she runs in place, `Run` looping.
- **Slashing:** pressing Space, or every 2 seconds when started with `--auto`, she plays `Sword_Slash` once. While she slashes, her
  legs and hips keep running exactly as before, in step, while everything from the waist up slashes. The slash eases in over 0.15
  seconds and out over 0.15 seconds back to running, with no snap at either end.
- **Readout:** at the top left, whether a slash is playing and how far through it is.
- **Exiting:** started with `--frames=N`, the program runs N frames and quits. Save screenshots to check she looks right: before a
  slash, in the middle of one, and as it eases out.
- **Done when:** it builds, runs, and the screenshots show her legs running and her upper body slashing.
