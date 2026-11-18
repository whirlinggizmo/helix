# Task: a lit room of shapes

Write a small raylib program in Haxe (helix-raylib): a 3D scene lit by two lights, in an 800 x 450 window at 60 frames a second.

- **The scene:** a grey ground 10 x 10 meters with a cube, a sphere and a torus standing on it, each a different colour, every mesh made
  in code. A dark sky.
- **The lights:** two point lights. A white one circles the scene 3 meters up, once every 6 seconds. A red one stays at one corner, 2
  meters up. Each shows as a small sphere of its own colour where it is.
- **The lighting:** the ground and the shapes are lit per pixel by both lights: brighter where a surface faces a light, with a highlight
  on the sphere and the torus, and a dim light from all around so no side is black.
- **Switches:** pressing W turns the white light on and off, and R the red one. A light that is off lights nothing and its sphere is
  drawn as an outline.
- **The ball:** a yellow ball 1 meter above the ground crosses from one side of the scene to the other in 2 seconds, falling into place
  with a few bounces as a dropped ball settles. It waits a second, goes back in 2 seconds starting slowly, fastest at the middle and
  slowing to a stop, waits a second, and starts over.
- **The camera:** fixed, 12 meters out and 7 meters up, looking at the middle of the scene.
- **Its shot:** 1.5 seconds after start it saves the screen as `shot.png`.
- **Done when:** it builds and runs, and `shot.png` shows the shapes lit by both lights and the ball on its way.
