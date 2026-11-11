# Task: a benchmark mode

Write a small raylib program in Haxe (helix-raylib) that draws a busy scene and can measure how fast it runs.

- **Window:** 1280 x 720, targeting 60 frames a second.
- **Scene:** a grid of 400 spinning cubes under an orbiting camera, each a different color.
- **Live readout:** at the top left, in your own text (DrawText, not DrawFrameStats), the frame time's mean and p95 in milliseconds and
  the draw calls a frame, kept current as the program runs.
- **Benchmark:** pressing B, or starting with the command-line option `--bench`, runs a benchmark: the scene settles for 2 seconds, then
  10 seconds are measured. When it ends, the program prints one line to the console, with the frames measured, the frames a second, the
  mean, p95 and slowest frame times in milliseconds, the draw calls and triangles a frame, and the GPU's textures and buffers and the
  program's memory in megabytes. Started with `--bench`, the program then quits; started with B, it keeps running and the readout shows
  the result until B is pressed again.
- **Done when:** `haxe build.hxml` compiles it without errors. The frame stats' functions aren't built yet, so it isn't run.
