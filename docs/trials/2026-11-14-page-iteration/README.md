# Wardens built in a page (2026-11-14)

Whether an agent builds Wardens cheaper or quicker when it builds and runs its program in a page as it works, with the native build
as its last step. Three fresh Sonnet agents (`helix-raylib-page.001` to `.003`) built [Wardens](../wardens/spec.md) as
[the runs with the extras](../2026-11-13-wardens-extras) did, against helix at `2bae477`, with two changes:

- **How it builds and runs.** `node run.cjs [arguments]` type-checks the native build, builds the page and runs it in headless
  Chromium, printing what the program logs and saving its screenshots. `haxe build.hxml` builds it natively, once the game is done.
- **What the brief says of it.** The game is a desktop program, and the page is only the quicker way to build and run it. Write
  nothing for the page or for one target: no `#if js`, no emscripten calls, no `js` or `cpp` package. The build had
  `-D helix-raylib-portable-host`, which refuses those in the program's own code.

The define, the brief and `run.cjs` (`run_entrant.py --page`, `docs/trials/wardens/page`) are on the branch `page-iteration` at
`2bae477`. They aren't in main, as the trial found no use for them.

## Runs

Started together on coinspinner, 3 hours each at most.

| run | cost | time | turns | lines | page runs | native builds |
|---|---:|---:|---:|---:|---:|---|
| page.001 | $2.25 | 21.0 min | 67 | 1,619 | 24 | 2, at 18.2 and 19.9 min |
| page.002 | $1.96 | 18.6 min | 60 | 1,789 | 20 | 1, at 18.2 min |
| page.003 | $2.63 | 25.1 min | 81 | 1,699 | 32 | 2, at 23.3 and 24.7 min |

All three built natively and in a page. Each built natively only at its end, as the brief asked. page.003 also type-checked the
native build twice on its own as it worked (`haxe build.hxml --no-output`).

| | cost | time | turns |
|---|---:|---:|---:|
| in a page (three runs) | $2.28 | 21.6 min | 69 |
| natively throughout (the fifteen runs with the extras) | $2.17 | 18.4 min | 66 |
| three.js (three runs) | $1.39 | 11.3 min | 33 |

## What it found

**The page made no difference to cost or time.** It didn't shorten the wait for a build and a run:

- **Natively** (docs.013 to .015): the first build took 33 to 43 s, and a rebuild and a run 10 to 25 s after it. Each entrant waited
  360 to 440 s in all.
- **In a page:** a run took 11 to 18 s with little on screen and 45 to 120 s with many enemies, as the sandbox's browser draws in
  software. Each entrant waited 555 to 770 s in all.

The brief's "the native build takes most of a minute" was true of the first native build alone. What separates these runs from
three.js's is turns and reading, not the time a build takes.

**The brief kept the programs to one target.** None of the three wrote `#if`, an emscripten call, `js.`, `cpp.`, `untyped` or an
`extern` class, and none met a refusal from `-D helix-raylib-portable-host`. The trial says nothing of the refusals' messages.

**The page hid a native crash.** page.001's program crashed natively where it cast an anonymous object to `VirtualButtonOptions`.
The page ran it, and the entrant met the crash 18 minutes in, at its first native build. It wrote the buttons as object literals
in `EnableVirtualGamepad`'s options instead.

**The page's software GL drew a grid wrong.** page.003 redrew its grid with `rlgl`, as `DrawGrid` lost lines in the sandbox's
browser.

## Scoring

Each program was built for the page as it stood and run in headless Chromium on the GPU (`score_page.py`). All three ran at the
title and in play. Each was also run natively for 1,200 frames at 200 enemies on a private display (`score_frames.py`), and each
recorded its frames. page.002's program ignores `WindowShouldClose` past its loading screen, so it ran on after the stats closed the
window and was stopped by hand.
