# Task: an animation inspector

Write a small raylib program in Haxe that loads an animated character and lets a developer look at how it moves.

- **Window:** 1280 x 720, a dark gray background, a grid on the ground, and the camera orbiting the character slowly.
- **Character:** `assets/robot.glb` and its animations. It plays one animation, and the number keys 1 to 9 choose which.
- **Views, each toggled by a key:**
  - **S:** the character's skeleton as it moves, in yellow, drawn over the character.
  - **B:** the character's bounds as it moves (not as it was modeled), in red.
  - **W:** the character as wires instead of solid.
  - **H:** hides the character itself, so only what the other views draw is left.
- **Stats:** the frame's cost at the top left, sized to read comfortably at this window's size; the program targets 30 frames a second, and the stats should be judged against that.
- **Three characters:** press C to show five copies side by side, each at a different point in the animation, each with its own skeleton and bounds when those views are on.
