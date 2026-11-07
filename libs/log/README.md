# helix-log

A log: messages with a level and an optional tag, to the browser's console or the process's output.

```haxe
import helix.log.Log;

Log.install();                                 // trace goes through the log from now on
Log.info("level 3 loaded");
Log.warn("no save yet", "saves");              // a tag says what it's about
Log.debug('ball at $x, $y', "physics");        // gone from a release build
Log.setTagLevel("physics", Warning);           // that tag's debug and info quieted
Log.listen((level, line) -> overlay.add(line)); // each line, for an in-program console
```

## Using it

```
-lib helix-log
```

Until it is on haxelib, install it from GitHub:

```
haxelib git helix-log https://github.com/whirlinggizmo/helix main libs/log
```

The API reference is [api/](api/README.md). Its tests, in `tests/`,
build with `-lib helix-log` alone.
