# API trials

A trial of part of helix-raylib's API: fresh agents write one small program against it, and where they guess is read. A trial's inputs are
a folder made from one of the two kinds here, outside the repository (`../../README.md`, "Its inputs"):

- **native/** for an API that is built: the program is built natively and run (`native/Main`, a screenshot to look at), and its
  brief says how.
- **draft/** for an API not built yet, its types and doc comments alone: the program is compiled for JavaScript against them
  (`-cp docs/api`), not run.

The folder holds:

- `task.md`: what the program does, naming no function.
- `build.hxml`: the kind's, unchanged.
- `assets.txt`: the files of Wardens' assets it gives, one a line.
- A folder for each variant (`module`, `blind`, `fix`, …): its `brief.md`, from the kind's with its `<...>` filled in, and the docs it
  gives in `docs/` (helix-raylib's API pages, or a draft's sources in `docs/api`), and for a variant starting from a program, its
  `Main.hx`.

An entrant is made from a variant with `../../tools/run_entrant.py <entrant> --helix <checkout> --trial <trial>/<variant>`, and its
runs are pruned with `../../tools/prune_trial.py` once `../../results/<date>-<name>.md` says what they showed.
