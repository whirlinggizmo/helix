Grade one run of Wardens, the game in `{HELIX}/docs/trials/wardens/spec.md`, against the items in
`{HELIX}/docs/trials/wardens/grading.md`. Read both first.

The run is `{RUN}`. Read its program's own source (its `.c` and `.h` files, or its `.hx` files, and its shaders), and look at every
screenshot in `{RUN}/grading/` (title, play, move, pause, play-later, late, title-crowd, crowd). Don't read its `NOTES.md`,
`brief.md`, `docs/`, `result.json` or logs, and don't build or run anything.

For each of the 37 items, give one grade: **met**, **wrong** (there, but not as the spec says), **missing**, or **can't tell**, and
one line saying what you saw and where (a file and line, or a screenshot). Judge only what the item asks, as the spec words it. A thing
written in the code that the screenshots show isn't working is **wrong**. Where the code is the judge, read it closely enough to be
sure: a constant matching the spec isn't enough if the code using it doesn't do what the spec says. Look closely at the warden and the
enemies in every screenshot (`title.png` shows her large): a body posed wrongly, stretched, bent where it shouldn't be or missing a
part, or a weapon out of her hand, makes items 2, 8, 12, 16 or 21 **wrong** whatever the code says.

Write the grades to `{RUN}/grading/grades.md` as a table (`| # | item | grade | seen |`), then a line with the counts of each grade.
Reply with that line only.
