# Task: raylib's shadowmap example

Port raylib's own example `shaders_shadowmap` (`docs/examples/shaders/shaders_shadowmap.c`, its shaders in
`docs/examples/shaders/resources/shaders/glsl330/shadowmap.vs` and `shadowmap.fs`, its robot in
`docs/examples/shaders/resources/models/robot.glb`) to Haxe with helix-raylib, doing what it does: a cube and the animated robot lit
by a directional light the arrow keys turn, casting shadows through a shadow map, in an 800 x 450 window.

- **Done when:** it compiles. The shadow map's calls aren't built yet, so it isn't run.
