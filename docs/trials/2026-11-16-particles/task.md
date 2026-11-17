# Task: a camp at night

Write a small raylib program in Haxe (helix-raylib): a 3D camp at night, in a 1280 x 720 window at 60 frames a second, every effect
below made with particles.

- **The camp:** `assets/models/floor_tile_large.glb` tiled into a ground about 12 x 12 meters, with `assets/models/barrel.glb`,
  `crates.glb` and `keg.glb` standing around a fire at the middle. A dark blue night sky.
- **The campfire:** flames licking up from the fire, bright yellow at the base and orange-red at their tips, flickering as they go. Glowing
  embers rising above them, drifting as they rise and winking out. Grey smoke above it all, growing as it rises and thinning to nothing,
  leaning away with a light breeze.
- **The light:** the fire lights the camp: a warm orange point light at the fire, flickering with it, lighting the props and the ground
  around it and leaving the edges of the camp dark.
- **Dust:** fine dust drifting slowly in the air around the fire, lit where the firelight reaches it and dim beyond it.
- **Fireflies:** a few dozen fireflies at the camp's edges, small yellow-green glows wandering slowly and pulsing, already there in the
  first frame.
- **A spell:** pressing Space casts a spell above the fire: one burst of bright blue sparks bursting outward, each a streak along the way
  it flies, slowing and falling as they fade. It casts one by itself 4 seconds after start, and every 5 seconds after.
- **Coins:** in the top right corner of the screen, in 2D over the scene, a coin count in `assets/ui/font.ttf`. It goes up by one every
  1.5 seconds, and each time a small burst of gold sparkles bursts from it and falls away.
- **The camera:** circling the fire slowly, 9 meters out and 4 meters up, looking at the fire.
- **Its shot:** 4.25 seconds after start, just after the first spell, it saves the screen as `shot.png`.
- **Done when:** it builds and runs, `shot.png` shows every effect, and it runs at 60 frames a second.
