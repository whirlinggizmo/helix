# helix.services.saves

[Back to the index](README.md)

## Saves

*class* in [`services/src/helix/services/saves/Saves.hx`](../../services/src/helix/services/saves/Saves.hx), `import helix.services.saves.Saves;`, implements `IPollable`

Provides small values a game keeps between runs, by key, in one file.

`load` reads the file once. After that, values are read and set in memory, without waiting. A change is kept at the next `poll`. Everything set in a frame is written as one file, one write at a time, so a program that ends between frames loses at most that frame's changes.

A write never blocks, and it finishes in the file system's `poll`, so a program that is ending keeps polling until the write is done. Natively, the program flushes at `CloseRequested` and leaves its loop when the flush answers. A page ends without a last frame, so it flushes in `IWindow.onClose`, where a write that has started may not finish.

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
function deleteKey(key:String):Void
function deleteKeys():Void
var pending(get, never):Bool
function flush(?written:() -> Void, ?failed:String -> Void):Void
function poll():Void
function dispose():Void
```

- `new`: Creates the saves over a file system, holding nothing until `load`.
  - `fileSystem`: The file system the file is kept in. Make it over `ISystem.getDataDirectory`: a `NativeFileSystemAdapter` natively, and a `BrowserFileSystemAdapter` in a page.
  - `name`: Optional. The file's path in the file system. Defaults to "saves.json".
- `load`: Reads the file. A file that doesn't exist yet loads as no values.
  - `loaded`: Called once the values can be read.
  - `failed`: Optional. Receives why the file can't be read or doesn't hold saves. When omitted, the failure is logged.

  Calling it again answers too: with the first load's outcome while that is in flight, and at the next `poll` once it has finished.
- `loaded`: Gets a value indicating whether `load` has finished, so values can be read and set.
- `has`: Returns whether a key has a value.
  - `key`: The key.
  - returns: True when a value was set or loaded, and not deleted since.
- `getString`: Returns a key's value as a string.
  - `key`: The key.
  - `fallback`: The value to return when the key has no value, or one that isn't a string.
  - returns: The value, or the fallback.
  - throws `String`: Before `load` has finished.
- `getInt`: Returns a key's value as a whole number.
  - `key`: The key.
  - `fallback`: The value to return when the key has no value, or one that isn't a whole number in Int's range.
  - returns: The value, or the fallback.
  - throws `String`: Before `load` has finished.
- `getFloat`: Returns a key's value as a number.
  - `key`: The key.
  - `fallback`: The value to return when the key has no value, or one that isn't a finite number.
  - returns: The value, or the fallback.
  - throws `String`: Before `load` has finished.
- `getBool`: Returns a key's value as true or false.
  - `key`: The key.
  - `fallback`: The value to return when the key has no value, or one that isn't true or false.
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
  - `value`: The value. Must be finite.
  - throws `String`: Before `load` has finished, or when the value isn't finite.
- `setBool`: Sets a key to true or false, kept at the next `poll`.
  - `key`: The key.
  - `value`: The value.
  - throws `String`: Before `load` has finished.
- `deleteKey`: Deletes a key and its value, kept at the next `poll`. Does nothing for a key with no value.
  - `key`: The key.
  - throws `String`: Before `load` has finished.
- `deleteKeys`: Deletes every key, kept at the next `poll`, resetting the saves.
  - throws `String`: Before `load` has finished.

  Only the saves file changes. Nothing else in the file system belongs to the saves.
- `pending`: Gets a value indicating whether a change isn't kept yet, because it was set since the last write or is being written.
- `flush`: Starts writing the current values without waiting for the next `poll`. Never blocks.
  - `written`: Optional. Called once the values are kept, or at the next `poll` when nothing was pending.
  - `failed`: Optional. Receives why the values can't be written. When omitted, the failure is logged.

  Before `load`, nothing is pending. A write that has started still finishes when the saves or their file system are disposed straight after, as in a page's `IWindow.onClose`, but then nothing is called.
- `poll`: Starts writing what was set since the last write, unless a write is still in flight.
  Call it once a frame. After a failed write, it waits for another change before trying again.
- `dispose`: Releases the values. A write in flight still finishes.
  Call it before disposing the file system it was given.
