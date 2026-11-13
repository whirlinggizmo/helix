# Task: aiming on the run

Write a small raylib program in Haxe (helix-raylib) that shows a character running sideways while she aims straight ahead.

- **Window:** 1280 x 720, targeting 60 frames a second, a camera in front of her, looking at her.
- **Model:** she is four models in `assets/characters/`, `Adventurer_Head.glb`, `Adventurer_Body.glb`, `Adventurer_Legs.glb` and
  `Adventurer_Feet.glb`, on one shared skeleton. Draw the four, each posed alike. Her animations are in `assets/characters/Animations.glb`.
- **Running:** she runs to her left in place, `CharacterArmature|Run_Left` looping.
- **Aiming:** pressing Space, or every 2 seconds when started with `--auto`, toggles her aim, `CharacterArmature|Idle_Gun_Pointing`.
  While she aims, her legs and hips keep running to her left exactly as before, in step, while everything from the waist up holds the
  aim with her chest and arm facing the camera, as the aim does on its own. The aim eases in and out over 0.2 seconds, with no snap at
  either end. She needs no gun in her hand.
- **Readout:** at the top left, whether she is aiming.
- **Exiting:** started with `--frames=N`, the program runs N frames and quits. Save screenshots to check she looks right: running
  without the aim, aiming, and the aim alone with her legs still (its own pose, to compare her chest and arm against).
- **Done when:** it builds, runs, and the screenshots show her legs running to her left and her upper body aiming at the camera.
