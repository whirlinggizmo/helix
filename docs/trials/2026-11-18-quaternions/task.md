# Task: a gyroscope of keyed turns

Write a small raylib program in Haxe (helix-raylib): three shapes turning through keyed orientations, in an 800 x 450 window at 60
frames a second.

- **The keys:** four orientations, held in one array: level; tipped a quarter turn forward; turned half a turn about the vertical;
  and tipped 30 degrees to the right and turned 45 degrees about the vertical.
- **The shapes:** three cubes 1.5 meters apart, each a different colour, on a grey ground. Each steps through the four keys in order,
  2 seconds a key, and starts over:
  - the left one blends between keys along the shortest arc;
  - the middle one blends the keys' four numbers straight and normalizes the result;
  - the right one snaps to each key.
- **The shader:** each cube is drawn by a shader of your own that tints it by its orientation: it takes the cube's orientation as one
  vec4 uniform (x, y, z, w) and adds the absolute values of x, y and z to the red, green and blue of its colour.
- **The readout:** under each cube, its orientation's four numbers, two decimals each.
- **The camera:** fixed, 8 meters out and 4 meters up, looking at the middle cube.
- **Its shot:** 3 seconds after start it saves the screen as `shot.png`.
- **Done when:** it builds and runs, and `shot.png` shows the three cubes turned and tinted, with their readouts.
