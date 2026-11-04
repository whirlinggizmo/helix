# Wardens (3D, top-down, survive the waves)

A small 3D game: a warden in a walled arena, holding out against waves of enemies, wearing the gear she finds. It names no
engine and no function.

## Window and screens
- **Window:** 1280 x 720, resizable. The view keeps the arena framed when the window is resized, and the HUD keeps to the window's edges.
- **Title:** "Wardens", the best time survived saved from an earlier run ("Best: 3:12"), and two buttons: Play and Quit (Quit only
  where quitting means anything; in a page it isn't shown). The warden stands in the middle, playing her idle animation, turning slowly.
- **Pause:** Escape or P pauses play. A panel shows Resume, Restart and Title buttons, and a slider for the volume, 0 to 100%,
  saved with the best time.
- **Game over:** "Time survived: 2:47", "Level 7", "Enemies defeated: 214", a new best called out, and Restart and Title buttons.

## The arena
- **Ground and walls:** a square 40 x 40 meters, a ground plane with a grid drawn on it, and low walls around its edge that nothing passes.
- **Models:** `assets/models/` holds optional dungeon pieces as GLB (a floor tile, a wall, a pillar, barrels, boxes, crates, a keg and a
  chest, see `assets/README.md`). The walls may use the wall model, and props may stand about. Nothing here changes the rules above.
- **Camera:** looks down at about 55 degrees from 14 meters, following the warden smoothly. Lit by one sun (a directional light),
  with a soft fill from above.

## The warden
- **Model:** built from the modular character's parts in `assets/characters/`: a head, a body, legs and feet, each a separate model
  on one shared skeleton, animated together by `assets/characters/Animations.glb`. She starts in the Adventurer outfit (the four
  `Adventurer_*.glb` parts).
- **Moving:** WASD, the arrow keys or a gamepad's left stick, at 5 meters a second whatever the frame rate, no faster on a diagonal. She
  faces where she moves. Walls stop her.
- **Animations:**
  - `Idle` standing.
  - `Run` moving.
  - `Sword_Slash` when the sword strikes, or `Gun_Shoot` when the gun fires.
  - `HitRecieve` when hit.
  - `Death` at the end.
  - Changes between them blend over 0.2 seconds.
- **Weapons:** held in her right hand, on the `Wrist.R` bone, following the hand through every animation. She starts with the
  sword (`Sword.glb`).
  - **The sword** strikes on its own every 0.8 seconds, hitting every enemy within 2 meters in front of her (a 120 degree arc) for 10
    damage.
  - **The gun** (`Gun.glb`), once found, fires on its own every 0.5 seconds at the nearest enemy within 12 meters. Its shot is a small
    glowing sphere flying at 20 meters a second, hitting the first enemy it meets for 6 damage.
  - **Holding both:** with both, she holds the one picked last, and switches with Q or a gamepad's shoulder button.
- **Health:** 100. A health bar is drawn above her head in the world, facing the camera.

## Enemies
- **Who:** the other outfits' parts dressed as enemies (the same parts and animations as the warden), tinted red, playing `Run`.
- **Spawning:** they come at the arena's edge, outside the view where they can, and walk at 2.5 meters a second straight at the warden,
  pushing apart from each other so they don't overlap.
- **Contact:** touching her deals 8 damage a second while touching. Each has 20 health, rising by 5 every minute, and plays
  `HitRecieve` when hit and `Death` when killed, then sinks into the ground and is gone.
- **Waves:** 5 at once at the start, more over time: every 30 seconds the most alive at once rises by 10, up to 200. There must be
  no stutter with 200 alive.
- **Gems:** each killed enemy drops a gem, a small spinning green crystal, which flies to the warden when she's within 3 meters and
  gives 1 experience.

## Levels and choices
- **Levels:** experience fills a bar along the top of the window. Level 2 takes 5 gems, and each level after takes 5 more than the last.
- **Choosing:** at each level up, play stops and three cards are offered, drawn from the list below, each with its name, a picture
  (its icon from `assets/ui/icons.png`) and what it does. The player picks one with a click, a tap, the arrow keys and Enter, or a
  gamepad.
- **The cards:**
  - **Sharper blade:** sword damage +5.
  - **Quick hands:** every weapon's time between attacks -15%.
  - **Long reach:** the sword's reach +0.5 meters.
  - **Gun (once):** adds the gun.
  - **More bullets:** the gun fires one more shot at the next nearest enemy.
  - **Gear:** a new outfit part, its icon the part's outfit. Named "Witch Head", "Soldier Body", "SciFi Legs" and so on, a random
    part from an outfit she isn't wearing. Picking it swaps that part on her at once, keeping the animation playing without a jump,
    and gives its bonus: a head +10 max health, a body +10% armor (damage taken), legs +0.5 meters a second, feet +1 meter to the gem
    pull.
- **Skins:** the cards and every button are drawn from the UI art in `assets/ui/` (`panel.png` and `button.png`, nine-slice images
  whose corners mustn't stretch), not flat rectangles.

## HUD
- **Top:** the experience bar along the top, with the level's number at its left.
- **Top left:** the time survived.
- **Top right:** enemies defeated, and frames a second.
- **Bottom:** the warden's gear as four small icons (head, body, legs, feet) and her weapons' icons.
- **Text:** none of it turns or moves with the camera.

## Sound
- **Effects:** `assets/sound/slash.wav` on a strike, `shot.wav` on a shot, `hit.wav` when she's hit, `gem.wav` for a gem, `level.wav`
  at a level up.
- **Music:** `assets/sound/music.ogg` loops during play, ducked to half while paused.
- **Volume:** everything follows the volume slider.

## Run options
- **`enemies=N`:** starts with N enemies alive at once and the cap held there, for measuring.
- **`seed=N`:** spawns from seed N, so two runs with the same seed play the same enemies, on the page and natively.
- **`quit_after_frame=N`:** quits after frame N, printing the frames' mean time.
- **Where they come from:** a page reads them from its URL (`?enemies=200`), a native build from its command line (`--enemies=200`).
