# Task: a character viewer

Write a small raylib program in Haxe (helix-raylib): a 3D character viewer, in a 1280 x 720 window at 60 frames a second.

- **The warden:** `assets/characters/Adventurer_Body.glb`, `Adventurer_Head.glb`, `Adventurer_Legs.glb` and `Adventurer_Feet.glb`,
  posed together by `assets/characters/Animations.glb`'s `CharacterArmature|Idle` clip, playing, standing at the middle of a gray floor,
  under a camera 6 meters out and 3 up, orbiting her slowly.
- **Panel:** `assets/ui/panel.png` drawn as a 360 x 120 box at the bottom left, and in it "THE WARDEN" in `assets/ui/font.ttf` at 40
  pixels.
- **Sound:** `assets/sound/music.ogg` playing as music, looping, from the start; pressing Space plays `assets/sound/slash.wav`.
- **Stopping:** `--frames=N` closes it after N frames, saving `shot.png` (raylib's screenshot call) on the last.
- **Done when:** it builds, runs with `--frames=180`, and `shot.png` shows the warden, the panel and its title.
