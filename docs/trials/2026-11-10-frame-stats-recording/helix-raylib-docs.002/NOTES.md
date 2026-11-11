# Notes

## Compile errors
1. `Unknown identifier: rlPushMatrix / rlTranslatef / rlRotatef / rlPopMatrix` — I first spun the cubes with rlgl matrix calls;
   they aren't in `helix.raylib.Raylib.*`. Changed to one cube `Model` (`LoadModelFromMesh(GenMeshCube(...))`) drawn 400 times with `DrawModelEx`.
Compiled clean after that. (`Sys.args()` / `Sys.println` compile for the JS target without complaint; they need a node-like runtime.)

## Guesses / unclear
- **Draw calls for the readout**: `GetFrameStats()` is "the last half second's frames", so `drawCalls` is a mean over that window (a Float);
  I print it as an Int. Unclear whether raylib batching makes 400 DrawModelEx = 400 calls (each model draw is its own call, so I expect ~400).
- **Readout before any frames / at start**: unclear what GetFrameStats returns in the first half second (zeros? partial window?). I call it every frame without guarding.
- **Does recording affect GetFrameStats?** Unclear whether GetFrameStats still reports the rolling half second while a recording is running; I assumed yes (independent).
- **When to call StartFrameStatsRecording**: it records "each frame from here"; I assumed frames are delimited by EndDrawing, so calling it mid-frame
  (before BeginDrawing) starts with the next full frame. Likewise Stop returns after the frame in progress; I call it before BeginDrawing.
- **Units**: times are seconds (I multiply by 1000 for ms), memory in bytes (divided by 1048576 for MB; I assumed MB = MiB).
  The doc says `fps` is frames over total time, so it can differ slightly from 1/mean—I print it as given.
- **p95**: "least of the slowest 5%" — I take it as the 95th percentile frame time.
- **triangles / stateChanges**: means per frame; the task wants triangles a frame, so I print `triangles` directly. `stateChanges` unused.
- **Memory**: `memoryBytes` references `ISystem.getMemoryBytes`, which I couldn't look up; on JS target I don't know what it reports.
- **Timing of the 2s/10s phases** uses GetTime (wall clock), not the recording itself, so measured frames ≈ 600 at 60 fps but not exact.
- `--bench` read with `Sys.args()`; no helix-raylib helper for command-line args was visible.

## API suggestions
- Give `FrameStats` MB fields or a helper (`gpuTextureMB`), or document units in the name (`meanFrameTimeSec`); seconds vs ms and bytes vs MB invite conversion mistakes.
- Document what `GetFrameStats` returns before a half second has elapsed and whether it works during a recording.
- Document whether Start/Stop must be called outside BeginDrawing/EndDrawing and which frame is first/last.
- Offer a recording with a duration/frame count (`RecordFrameStats(seconds)`) or an `IsFrameStatsRecording()` query so programs needn't track state themselves.
- Add a built-in formatter/`ToString` for FrameStats, since printing a one-line report is the common use.
- Make `drawCalls`/`triangles` Int-friendly or state they are means (fractional) in the name.
- Say what `p95` is for few frames (<20), and whether `slowestFrameTime` includes the settle frames dropped by a restart.
