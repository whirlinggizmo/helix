# Library trial: the assets service's paths, reads, writes and listings (2026-11-20)

Whether agents writing against a proposed `Assets` API, from its doc comments alone, can tell how a path is read, what a read
answers when no source has the file, and what the listings return. Nine fresh Sonnet agents, three a round, each a `claude -p` in a
directory of its own outside any repository, in the blind trials' sandbox (`run_entrant.py --trial`), against helix at `7b0b153`.
Each was given a brief, a task and the proposal, made outside the repository beside the runs. The brief gave the platform's and the
services' API pages, and the proposed classes (`Assets`, `AssetSource`, `FileSystemSource`, `ServerSource`) as doc comments over
stubs that compile, and asked for notes on each guess. The task was a level browser for a page: it follows each level's `next`
path (`"2.json"`, `"../custom/1.json"`), writes the player's first level, lists the player's levels and the kept downloads, reads
a level again when the development server names its URL, and empties the kept downloads. The program was compiled, not run.
The proposal changed between rounds, by what the round before found.

| round | entrant | cost | time | turns | tokens in | tokens out |
|---|---|---|---|---|---|---|
| 1 | 1 | $0.27 | 0.7 min | 14 | 469,998 | 5,339 |
| 1 | 2 | $0.27 | 0.6 min | 13 | 499,893 | 4,773 |
| 1 | 3 | $0.27 | 0.7 min | 12 | 423,679 | 5,235 |
| 2 | 4 | $0.24 | 0.5 min | 9 | 344,991 | 3,740 |
| 2 | 5 | $0.25 | 0.6 min | 12 | 389,660 | 4,967 |
| 2 | 6 | $0.26 | 0.6 min | 12 | 450,278 | 4,719 |
| 3 | 7 | $0.27 | 0.7 min | 15 | 456,278 | 5,121 |
| 3 | 8 | $0.25 | 0.6 min | 10 | 369,669 | 4,796 |
| 3 | 9 | $0.25 | 0.7 min | 14 | 476,942 | 5,259 |

Each compiled on its first build.

## What it found

| round | finding | what changed |
|---|---|---|
| 1 | None passed `../custom/1.json` to Assets: each joined `next` onto the level's directory itself (3 of 3), unsure whether `levels/../custom/1.json` reads `custom/1.json` | the class doc says it does, and `Assets.join(from, path)` makes the path a file names relative to it |
| 1 | Whether `list` of a directory no source has fails or answers `[]` (3 of 3) | it answers `[]`, and the doc says so |
| 1 | Whether `listCache`'s paths are from the directory asked for or from the root (3 of 3) | from the source's root, `levels/1.json` for `listCache("levels")` |
| 1 | Whether a page's full URL passed to `notifyChanged` reaches a watch of `levels/2.json` (2 of 3) | the doc shows a URL, a path from the server's root and a name each reaching it |
| 1 | A read of a file the program hasn't written yet asks the server too (3 of 3) | the class doc says so |
| 2 | `join` keeps `..`, and whether a watch of `levels/../custom/1.json` hears a change of `custom/1.json` (3 of 3) | `watch`'s doc gives that example. `join` keeps `..`: only a source follows it, by its own root's rules |
| 2 | A missing file and a failure can't be told apart (3 of 3, and 1 in round 1) | `read` accepts an optional `missing`, called when no source has the file |
| 2 | What `notifyChanged` does for a file only the data directory has, or no source has (2 of 3) | the doc says a file system source's file is read again from it, and a file no source has is logged |
| 3 | A copy might not be listed straight after its `read` (1 of 3) | a server source's `read` answers once its copy is written to the cache |
| 3 | A tidier path than `levels/../custom/1.json` in a trace (3 of 3) | nothing: a preference, the watch's key answered by round 2 |
| 3 | Which base `listCache`'s paths are from (1 of 3), and whether `list`'s `[]` is certain (1 of 3) | nothing: the doc says both |

Round 3 left no guess at what a call does. A path outside every source's root was made a missing file, logged with its reason,
after the rounds, for the same reason a 404 is one. The API was built as the proposal ended (`993a10a`, `6ff0906`).
