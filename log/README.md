# helix-log

A log: messages with a level and an optional tag, written to the browser's console or the process's output, and
`trace` through it once installed. It depends on nothing.

```haxe
import helix.log.Log;

Log.install();                                 // trace goes through the log from now on
Log.info("level 3 loaded");
Log.warn("no save yet", "saves");              // a tag says what it's about
Log.debug('ball at $x, $y', "physics");        // gone from a release build
Log.setTagLevel("physics", Warning);           // that tag's debug and info quieted
Log.listen((level, line) -> overlay.add(line)); // each line, for an in-program console
```

A line says where it was written, as `trace` does: `src/Game.hx:42: [physics] ball at 10, 4`, a file under the working directory named
from it. In the browser it goes to `console.debug`, `info`, `warn` or `error` by level, so the console's own filter works. Natively,
debug and info go to the standard output and warnings and errors to the standard error (`warning: `, `error: `), colored by level
unless the `NO_COLOR` environment variable is set.

`Log.level` is the least a message must matter to be written: Debug in a debug build, Info in a release, Off for nothing. A tag's own
level, set with `setTagLevel`, takes its place for that tag. `Log.install()` routes `trace` through the log as Info; `Log.uninstall()`
gives `trace` back, unless something else replaced it since; `Log.installed` says which.

It writes to the console or stdio itself, with one `#if js`, and depends on no other library.

Its tests, in `tests/`, build with `-lib helix-log` alone, on the interpreter and Node.
