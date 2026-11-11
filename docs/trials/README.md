# Trials

A trial gives part of helix to fresh agents who know nothing of it, and reads where they guess. Each folder here is one trial's record,
and [jam-survivors](jam-survivors) holds the game the engine trials build.

## When

- **A library's API, before it's written.** Fresh agents write against its types and doc comments alone (AGENTS.md). A guess one
  makes is answered by changing the API, so the question can't come up again.
- **A departure from raylib, before it's pushed.** A change adding or moving a refusal, an extra or a build step in helix-raylib gets a
  blind trial. Each guess an entrant makes at the change is answered where the entrant met it: in the refusal's message, or in the
  doc of the call it reached for.

## A blind trial

- **Entrants.** Three, on Sonnet. Each is a fresh `claude -p` started in its own directory outside any git repository. None is a
  subagent of a session working on helix, as that session's commit messages would reach it.
- **What each is given.** A brief, the game's spec ([Wardens](jam-survivors/spec.md)), raylib 5.5's own headers and C examples, and
  the game's assets. Nothing of helix's docs or sources. Where helix-raylib differs from raylib, the compiler says so.
- **How it builds.** Natively, with `haxe build.hxml`, against one commit of helix (a worktree with its own haxelib, so nothing changes
  under the entrant). It runs `./native/Main` on a private display, with no sound and no session D-Bus, and its saves and cache in
  directories of its own. It sees its game through raylib's screenshots. Its brief says nothing of pages.
- **What it hands back.** The program, and `NOTES.md`: each compile error it hit and what it changed, each place raylib had no call for
  what the spec asks, and each guess.
- **Scoring.** Each program is built for the page as it stands and run there, its whole directory served, to see whether it works
  unchanged. Its notes are read against the change being tried.
- **Watching.** Each entrant's log is read every ten minutes while it runs. A harness fault stops the run early.

The harness (the template directory and the script that starts an entrant) is kept outside the repository, beside the entrants.
