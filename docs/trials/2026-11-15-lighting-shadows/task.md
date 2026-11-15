# Task: a lantern-lit yard

Write a small raylib program in Haxe (helix-raylib): a 3D yard at dusk, in a 1280 x 720 window at 60 frames a second.

- **Ground:** a 20 x 20 meter plane, and three crates (1 meter cubes) standing on it.
- **The warden:** `assets/characters/Adventurer_Body.glb`, `Adventurer_Head.glb`, `Adventurer_Legs.glb` and `Adventurer_Feet.glb`, posed
  together by `assets/characters/Animations.glb`'s `CharacterArmature|Run` clip, playing in place at the yard's middle.
- **Light:** the PBR shader for everything, a low orange sun casting soft shadows over the yard (two cascades, reaching 30 meters), and a
  lantern (a point light, warm yellow, range 6 meters) hanging 2.5 meters up beside the crates, casting shadows every way.
- **Grass:** 2,000 grass blades over the ground (thin triangles, 20 to 40 centimeters tall), swaying in the wind in their own vertex
  shader, their shadows swaying with them.
- **A hedge:** a row of leaf cards along one edge, each a quad textured with a leaf image made in code (a green leaf shape on a clear
  background), its clear parts cut out, in the picture and in their shadows.
- **Hit flash:** pressing Space flashes the warden white for 0.15 seconds, as a hit in a game does.
- **Camera:** orbiting the yard slowly, 12 meters out, 5 meters up.
- **Done when:** it compiles. The new calls aren't built yet, so it isn't run.
