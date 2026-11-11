# Library trial: frame stats recording (2026-11-10)

Whether agents can measure a program's frame time with `extras.Debug`'s frame stats (`GetFrameStats`, `StartFrameStatsRecording`,
`StopFrameStatsRecording` and `FrameStats`), learning them from their doc comments alone. Two fresh Sonnet agents, each a `claude -p`
in a directory of its own outside any repository, in the blind trials' sandbox, were given [the brief](brief.md), [the task](task.md)
(400 spinning cubes, a live readout of the mean and p95 in milliseconds, and a benchmark that settles for 2 seconds, measures 10 and
prints one line) and the API as it was tried ([api-as-tried](api-as-tried)), its functions not yet built, compiling for JavaScript
([build.hxml](build.hxml)). Both compiled cleanly, in 7 and 5 turns, about 37 seconds and $0.15 each. Their programs and notes are in
`helix-raylib-docs.001/` and `helix-raylib-docs.002/`, named as the runs were. Neither misused the frame stats: both recorded after
the settle and stopped once, read the readout from `GetFrameStats` each frame, and turned seconds into milliseconds and bytes into
megabytes correctly.

## What it found, and what changed

| finding (both agents unless noted) | change |
|---|---|
| Which frames a Start or a Stop called mid-frame takes in, and where in the frame the draws are counted | a frame is recorded as its `EndDrawing` returns: a recording holds the frames that end after its Start and before its Stop |
| Whether `GetFrameStats` still reports while a recording runs | the docs say the two are apart: `GetFrameStats` always reports the last half second |
| What `GetFrameStats` returns before half a second has passed | the docs say it covers the frames drawn so far, all zero before the first |
| `memoryBytes` named `ISystem.getMemoryBytes`, which a raylib program can't see | the field says what it reads: natively the process's resident memory, in a page the script heap where the browser reports it, 0 where it doesn't |
| A recording left open when B cancels a run (helix-raylib-docs.001): every frame's time kept, growing | a recording keeps its latest 65536 frames, and the docs say so |
| rlgl's calls unknown in `helix.raylib.Raylib.*`: helix-raylib-docs.001 guessed `import helix.raylib.Rlgl.*;`, helix-raylib-docs.002 drew models instead | outside the frame stats, and the trial's own: its brief named `Raylib` and the types' imports alone, where the Wardens brief names each header's class (`rlgl.h` is `Rlgl`). The compiler can't add a hint, as an unknown identifier reaches no macro. helix-raylib's README now says each header is a class and how each is imported |
| Times in milliseconds, memory in megabytes, an `IsFrameStatsRecording`, a `RecordFrameStats(seconds)`, a formatter (suggested) | not taken: seconds are GetFrameTime's, bytes are what the graphics and the system count, and raylib's own recordings have no query |

Decided with the user before the trial: the stats a program can read, not only draw; `Start` and `Stop` named for raylib's
`StartAutomationEventRecording` and `StopAutomationEventRecording`, as recording spans frames where `Begin` and `End` bracket one; every
stat the overlay can show in one `FrameStats`, the draw counts a mean over the frames so a field means the same from both calls; the
bytes as `Float`, as the graphics and the system count them. A blind trial's frame times are taken by the scorer's build of the
entrant's program, not asked of the entrant.
