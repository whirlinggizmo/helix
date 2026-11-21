# Departure trial: a path outside every asset host (2026-11-21)

Whether agents writing a raylib program get past helix-raylib refusing a path outside every asset host, where raylib reads any
path the OS does. Nine fresh Sonnet agents, three a round, each a `claude -p` in a directory of its own outside any repository, in
the blind trials' sandbox (`run_entrant.py --trial`), built natively against helix's `assets-paths` branch. Each was given the API
trial's native brief with helix-raylib's types page and no extras pages, and a task: an 800 x 450 title card, "Lanternholm" in DejaVu
Serif, named by its system path `/usr/share/fonts/truetype/dejavu/DejaVuSerif.ttf`, over the line "Running on <name>", the first
line of `/etc/hostname`, and a screenshot of the last frame. The build's one host is the entrant's directory
(`-D helix-raylib-asset-hosts=..`). The inputs were made outside the repository beside the runs.

| round | entrant | cost | time | turns | tokens in | tokens out | the font | the hostname |
|---|---|---|---|---|---|---|---|---|
| 1 | 1 | $0.18 | 1.7 min | 12 | 334,568 | 4,440 | copied in, "a workaround" | fallback |
| 1 | 2 | $0.16 | 1.5 min | 8 | 227,430 | 3,718 | the default font | fallback |
| 1 | 3 | $0.14 | 1.4 min | 8 | 246,089 | 3,074 | the default font | fallback |
| 2 | 4 | $0.15 | 1.4 min | 9 | 224,122 | 3,300 | the default font, asked | fallback, asked |
| 2 | 5 | $0.25 | 1.5 min | 10 | 412,249 | 3,465 | the default font, asked | fallback, asked |
| 2 | 6 | $0.18 | 1.7 min | 13 | 362,608 | 4,124 | copied in | copied in, "a snapshot" |
| 3 | 7 | $0.14 | 1.4 min | 9 | 244,510 | 3,400 | the shipped copy | fallback |
| 3 | 8 | $0.14 | 1.4 min | 9 | 242,754 | 3,213 | the shipped copy | fallback |
| 3 | 9 | $0.19 | 1.7 min | 13 | 388,783 | 4,852 | the shipped copy | fallback |

Each built and saved its screenshot. Round 1 ran at `13ad00b`, rounds 2 and 3 at `87bfa23`. Round 3's directory also contained
the font, in `assets/`, with the task unchanged.

## What it found

| round | finding | what changed |
|---|---|---|
| 1 | Each took "Invalid file path: … is outside every asset source's root" for a guard (3 of 3), and none knew where its files are read from | the refusal names the hosts: "is outside every asset host (/home/…/sonnet-4/)" (`87bfa23`) |
| 2 | Each named its own directory as the host (3 of 3). Two left the font out, calling a copy "sidestepping the restriction", and asked | nothing: a program ships its font, and the message names no remedy, which would invite copying `/etc/hostname` too |
| 3 | With the font shipped, each loaded it after the refusal (3 of 3), and each showed a fallback name for the hostname | nothing: the jail refuses what it should |
| all | `/etc/hostname` stayed unread (8 of 9). One copied it in as a snapshot. Two tried `sys.io.Process`, refused | nothing: applications stay within their hosts |
| all | `TakeScreenshot` after `EndDrawing` (8 of 9), each moved before it by the warning | nothing: as DECISIONS 73 |
| 3 | `ExportImage(image, "shot.png")` wrote to the data directory, where `TakeScreenshot("shot.png")` writes to the working directory (1 of 3) | to be decided: raylib writes both relative to the working directory |

The refusal stands. helix-raylib reads only under the program's asset hosts, natively and in a page, and a path outside them
is missing, logged with the hosts it is outside.
