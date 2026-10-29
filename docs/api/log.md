# helix.log

[Back to the index](README.md)

## Log

*class* in [`log/src/helix/log/Log.hx`](../../log/src/helix/log/Log.hx), `import helix.log.Log;`

Provides the log: messages for whoever is developing the program, each with how much it matters and, optionally, a tag saying what it's about.

A line says where it was written from, as trace does (`Game.hx:42: [physics] ball at 10, 4`). In the browser it goes to the console (console.debug, info, warn and error, so the console's own filter works); natively, debug and info lines go to the standard output and warnings and errors to the standard error, colored by level unless the `NO_COLOR` environment variable is set.

What's written is what's at or above `Log.level`, or a tag's own level when it has one. `Log.debug` is gone from a release build, so it can be left in freely. `trace` goes through the log as Info once `install` is called.

```haxe
Log.install();
Log.info("level 3 loaded");
Log.warn("no save yet", "saves");
Log.setTagLevel("physics", Warning);
```

```haxe
static var level:LogLevel
static var installed(get, never):Bool
static function debug(message:Dynamic, ?tag:String, ?pos:haxe.PosInfos):Void
static function info(message:Dynamic, ?tag:String, ?pos:haxe.PosInfos):Void
static function warn(message:Dynamic, ?tag:String, ?pos:haxe.PosInfos):Void
static function error(message:Dynamic, ?tag:String, ?pos:haxe.PosInfos):Void
static function write(level:LogLevel, message:Dynamic, ?tag:String, ?pos:haxe.PosInfos):Void
static function isWritten(level:LogLevel, ?tag:String):Bool
static function setTagLevel(tag:String, level:Null<LogLevel>):Void
static function listen(listener:(LogLevel, String) -> Void):Void
static function unlisten(listener:(LogLevel, String) -> Void):Void
static function install():Void
static function uninstall():Void
```

- `level`: Gets or sets the least a message must matter to be written, unless its tag has a level of its own.
  It starts as Debug in a debug build and Info in a release. Off writes nothing.
- `installed`: Gets whether `trace` goes through the log: true from `install` until `uninstall`.
- `debug`: Writes a message as Debug: detail for finding a fault.
  - `message`: The message: anything, written as a string.
  - `tag`: Optional. What it's about.

  A release build leaves the call out.
- `info`: Writes a message as Info: what happened, worth knowing.
  - `message`: The message: anything, written as a string.
  - `tag`: Optional. What it's about.
- `warn`: Writes a message as Warning: something went wrong and the program carried on.
  - `message`: The message: anything, written as a string.
  - `tag`: Optional. What it's about.
- `error`: Writes a message as Error: something failed that the program may not recover from.
  - `message`: The message: anything, written as a string.
  - `tag`: Optional. What it's about.
- `write`: Writes a message at a level, when `isWritten` lets it through.
  - `level`: How much it matters.
  - `message`: The message: anything, written as a string.
  - `tag`: Optional. What it's about.

  Each listener receives the line, then the console or the process's output.
- `isWritten`: Returns whether a message would be written, to skip building a costly one that wouldn't be.
  - `level`: How much it would matter.
  - `tag`: Optional. What it would be about.
  - returns: True when the level is at or above the tag's own level, or `Log.level` for a tag without one.
- `setTagLevel`: Sets a tag's own level, in place of `Log.level` for its messages.
  - `tag`: The tag.
  - `level`: The least its messages must matter to be written: Off silences it, and null gives it `Log.level` again.
- `listen`: Adds a listener that receives each line written, for an in-program console, an overlay or a test.
  - `listener`: Receives the line's level and the line as written.

  Adding the same listener again does nothing.
- `unlisten`: Removes a listener that `listen` added.
  - `listener`: The listener.
- `install`: Routes `trace` through the log as Info, its extra values after the first.
  Calling it again while installed does nothing.
- `uninstall`: Gives `trace` back what it was before `install`.
  If something else replaced `trace` after `install`, that replacement is kept, and the log stops being installed all the same.

## LogLevel

*abstract* in [`log/src/helix/log/LogLevel.hx`](../../log/src/helix/log/LogLevel.hx), `import helix.log.LogLevel;`

Specifies how much a log message matters.

`Log.level` and a tag's own level let through what's at or above them. A level reads as its name when traced or interpolated.

- `LogLevel.Debug`: Detail for finding a fault, written in debug builds and gone from a release build.
- `LogLevel.Info`: What happened, worth knowing.
- `LogLevel.Warning`: Something went wrong and the program carried on.
- `LogLevel.Error`: Something failed that the program may not recover from.
- `LogLevel.Off`: As a level to let through: nothing.

```haxe
function toString():String
```

- `toString`: Returns the level's name.
  - returns: "Debug", "Info", "Warning", "Error" or "Off".
