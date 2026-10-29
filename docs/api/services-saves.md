# helix.services.saves

[Back to the index](README.md)

## Saves

*class* in [`services/src/helix/services/saves/Saves.hx`](../../services/src/helix/services/saves/Saves.hx), `import helix.services.saves.Saves;`, implements `IPollable`

Provides small values a game keeps between runs, by key, in one file.

`load` reads the file once; after it the values are read and set at once, in memory. A change is kept at the next `poll`: everything set in a frame is written as one file, one write at a time, so a program that ends between frames loses at most that frame's changes.

A write never blocks and finishes in the file system's `poll`, so a program that ends keeps polling until it's done. Natively, at `CloseRequested` the program flushes and leaves its loop when the flush answers; in a page, which ends without a last frame, it flushes in `IWindow.onClose`, where a write started may not finish.

```haxe
saves.load(() -> {
x = saves.getFloat("x", 0);
y = saves.getFloat("y", 0);
});
saves.setFloat("x", x);

// natively, ending: the loop runs on until running is false
case CloseRequested: saves.flush(() -> running = false, error -> running = false);
// in a page
window.onClose = () -> saves.flush();
```

```haxe
function new(fileSystem:IFileSystem, ?name:String = "saves.json")
function load(loaded:() -> Void, ?failed:String -> Void):Void
var loaded(default, null):Bool
function has(key:String):Bool
function getString(key:String, fallback:String):String
function getInt(key:String, fallback:Int):Int
function getFloat(key:String, fallback:Float):Float
function getBool(key:String, fallback:Bool):Bool
function setString(key:String, value:String):Void
function setInt(key:String, value:Int):Void
function setFloat(key:String, value:Float):Void
function setBool(key:String, value:Bool):Void
function remove(key:String):Void
function clear():Void
var pending(get, never):Bool
function flush(?written:() -> Void, ?failed:String -> Void):Void
function poll():Void
function dispose():Void
```

- `new`: Creates the saves over a file system, holding nothing until `load`.
  - `fileSystem`: Where the file is kept: natively a `NativeFileSystemAdapter` over `ISystem.getDataDirectory`, in a page a `BrowserFileSystemAdapter` with its own name, apart from `Assets`' cache, which `Assets.clearCache` empties.
  - `name`: Optional. The file's path in it; "saves.json" by default.
- `load`: Reads the file. A file that isn't there yet loads as no values.
  - `loaded`: Called once the values can be read.
  - `failed`: Optional. Receives why the file can't be read or isn't saves; left out, it's logged.
- `loaded`: Gets a value indicating whether `load` has finished, so the values can be read and set.
- `has`: Returns whether a key has a value.
  - `key`: The key.
  - returns: True when one was set or loaded, and not removed.
- `getString`: Returns a key's value as a string.
  - `key`: The key.
  - `fallback`: What to return when it has none, or one that isn't a string.
  - returns: The value, or the fallback.
  - throws `String`: Before `load` has finished.
- `getInt`: Returns a key's value as a whole number.
  - `key`: The key.
  - `fallback`: What to return when it has none, or one that isn't a whole number.
  - returns: The value, or the fallback.
  - throws `String`: Before `load` has finished.
- `getFloat`: Returns a key's value as a number.
  - `key`: The key.
  - `fallback`: What to return when it has none, or one that isn't a number.
  - returns: The value, or the fallback.
  - throws `String`: Before `load` has finished.
- `getBool`: Returns a key's value as true or false.
  - `key`: The key.
  - `fallback`: What to return when it has none, or one that isn't true or false.
  - returns: The value, or the fallback.
  - throws `String`: Before `load` has finished.
- `setString`: Sets a key to a string, kept at the next `poll`.
  - `key`: The key.
  - `value`: The value.
  - throws `String`: Before `load` has finished.
- `setInt`: Sets a key to a whole number, kept at the next `poll`.
  - `key`: The key.
  - `value`: The value.
  - throws `String`: Before `load` has finished.
- `setFloat`: Sets a key to a number, kept at the next `poll`.
  - `key`: The key.
  - `value`: The value, finite.
  - throws `String`: Before `load` has finished, or for a value that isn't finite.
- `setBool`: Sets a key to true or false, kept at the next `poll`.
  - `key`: The key.
  - `value`: The value.
  - throws `String`: Before `load` has finished.
- `remove`: Removes a key's value, kept at the next `poll`; does nothing for a key with none.
  - `key`: The key.
  - throws `String`: Before `load` has finished.
- `clear`: Removes every value, kept at the next `poll`: a reset. The file system holds nothing else of the saves', so nothing else there changes.
  - throws `String`: Before `load` has finished.
- `pending`: Gets a value indicating whether a change isn't kept yet: set since the last write, or being written.
- `flush`: Starts writing what's set now, without waiting for the next `poll`; never blocks.
  - `written`: Optional. Called once it's kept; at once, at the next `IFileSystem.poll`, when nothing was pending.
  - `failed`: Optional. Receives why it can't be written; left out, it's logged.
- `poll`: Starts writing what was set since the last write, unless a write is still going; call once a frame.
- `dispose`: Lets go of the values; a write in flight still finishes.
