# Notes

## Compile errors
1. `Unknown identifier : rlPushMatrix / rlTranslatef / rlRotatef / rlPopMatrix`. The rlgl functions aren't in `Raylib.*`. I guessed `import helix.raylib.Rlgl.*;` and it compiled. (I did not verify the module name by reading the library, since I was told to read nothing outside the directory.)

No errors came from the frame stats API itself. `FrameStatsStyle` is referenced in Debug.hx but not defined in api/, so I avoided DrawFrameStatsEx / MeasureFrameStats.

## Guesses / unsure
- **When to call GetFrameStats**: I call it every frame after EndMode3D, before EndDrawing, for the readout. Unsure whether it should come after EndDrawing, since the last frame's draw calls may only be final then. Also unsure whether it's cheap enough to call every frame.
- **Window**: "last half second" for GetFrameStats. It's unclear whether this is half a second of frame time or a fixed number of frames, and whether it's empty (all zero) in the first frames.
- **Recording and GetFrameStats**: I assumed GetFrameStats keeps working while a recording is running and doesn't disturb it, so the readout stays live during the benchmark.
- **Units**: frame times are seconds (I multiply by 1000 for ms). gpuTextureBytes, gpuBufferBytes and memoryBytes are bytes (divided by 1024*1024 for "megabytes"; unclear if MB means 10^6 or 2^20). drawCalls and triangles are Floats because they're means; I print them rounded to 2 decimals.
- **p95FrameTime**: "least of the slowest 5%". I took this to be the 95th percentile, not the mean of the slowest 5%.
- **GPU/memory fields**: "at the call". For a benchmark, I assumed they're read at StopFrameStatsRecording, not averaged over the run.
- **Settling phase**: I start recording after 2 s, using GetFrameTime to count. I didn't know if frames in that period would be included by a call to Start; I assumed not.
- **Quit with --bench**: I call StopFrameStatsRecording once at the end and print with Sys.println. I read args with `Sys.args()`.
- **B pressed during a run**: I abort the run, without calling StopFrameStatsRecording (the recording stays open until the next Start, which restarts it). Unsure whether leaving a recording open costs anything.
- **Cube spin**: with rlPushMatrix/rlRotatef around DrawCube. This may affect draw-call counts in ways I can't verify.

## API changes I'd suggest
- Define `FrameStatsStyle` in api/ (or point to where it lives) so the docs are complete.
- Have FrameStats store milliseconds (or add helpers), since every display needs ms; and MB for memory.
- Say what GetFrameStats returns with no frames, and whether it's valid mid-recording.
- Say which point in the frame (before/after EndDrawing) the draw calls are counted for.
- Round the counts: `drawCalls` and `triangles` as Float are odd to print; document that they're means.
- Add a way to abandon a recording without a Stop call (or document that Stop is optional).
- Document that p95 is a percentile, with the exact definition.
