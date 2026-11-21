# Departure trial: native screenshots in the data directory (2026-11-21)

Whether agents writing a raylib program find a screenshot that helix-raylib writes to the data directory, where raylib writes it
to the working directory (`bdc96e4`). Three fresh Sonnet agents, each a `claude -p` in a directory of its own outside any
repository, in the blind trials' sandbox (`run_entrant.py --trial`), built natively against helix at `bdc96e4`. Each was given the
API trial's native brief with helix-raylib's types page and no extras pages, its sentence naming the data directory left out, and a
task: a 640 x 360 window, a red square on dark blue, a screenshot `shot.png` of the last frame read back and its centre printed, and
the file looked at. The inputs were made outside the repository beside the runs.

| entrant | cost | time | turns | tokens in | tokens out | found the file |
|---|---|---|---|---|---|---|
| 1 | $0.13 | 1.3 min | 9 | 247,626 | 2,389 | yes, in the data directory, and viewed it |
| 2 | $0.12 | 1.2 min | 9 | 178,581 | 2,117 | yes, in the data directory |
| 3 | $0.14 | 1.3 min | 9 | 262,364 | 2,416 | yes, in the data directory, and viewed it |

Each built on its first try, printed `centre: 230 41 55` (raylib's `RED`) and said the task was done.

## What it found

| finding | what changed |
|---|---|
| Each saw the screenshot isn't in the working directory and found it in the data directory (3 of 3). `LoadImage("shot.png")` read it back with the plain name (3 of 3) | nothing: the move stands |
| `TakeScreenshot` after `EndDrawing` (3 of 3), each moved before it by the warning | nothing: as DECISIONS 73 |
