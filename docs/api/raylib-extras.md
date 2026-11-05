# helix.raylib.extras

[Back to the index](README.md)

## Audio

*class* in [`engines/raylib/src/helix/raylib/extras/Audio.hx`](../../engines/raylib/src/helix/raylib/extras/Audio.hx), `import helix.raylib.extras.Audio;`

Provides the async versions of raylib 5.5's sound, wave and music loads and wave writes (raudio), helix-raylib's own, as a page can't wait for a file and most formats are decoded off the main thread: `LoadSoundAsync` for `LoadSound`, `LoadMusicStreamAsync` for `LoadMusicStream` and the rest. raylib's own call doesn't compile and names the one here (docs/DECISIONS.md 24, 38). Imported apart: `import helix.raylib.extras.Audio.*;`.

Each answers at a later poll, never during the call: `done` or `loaded` once it is done, `failed` with the reason when it is refused, logged as raylib's warning would be when `failed` is omitted.

### audio: the sound, wave and music loads and wave writes in place of raudio's that wait

```haxe
static function LoadSoundAsync(fileName:String, loaded:Sound -> Void, ?failed:String -> Void):Void
static function LoadMusicStreamAsync(fileName:String, loaded:Music -> Void, ?failed:String -> Void):Void
static function ExportWaveAsync(wave:Wave, fileName:String, ?done:() -> Void, ?failed:String -> Void):Void
static function ExportWaveAsCodeAsync(wave:Wave, fileName:String, ?done:() -> Void, ?failed:String -> Void):Void
```

- `LoadSoundAsync`: Loads a sound file and decodes it, answering when it is ready to play at once: helix-raylib's own, in place of raylib's `LoadSound`. A file loaded again shares its first load's decoded sound. `InitAudioDevice` comes first.
  - `fileName`: The file, as the program names it.
  - `loaded`: Receives the sound.
  - `failed`: Optional. Receives why it couldn't be loaded; when omitted, it is logged.
- `LoadMusicStreamAsync`: Opens a music file, to be played as it is read (helix-services' `Audio.stream`), answering once enough of it has arrived to start: helix-raylib's own, in place of raylib's `LoadMusicStream`. Natively it is read from its file, in a page from the download as it arrives, never loaded whole. A FLAC file isn't opened, as raylib 5.5's default build leaves FLAC out (docs/DECISIONS.md 32). `InitAudioDevice` comes first.
  - `fileName`: The file, as the program names it, such as "assets/theme.ogg".
  - `loaded`: Receives the music, ready to play.
  - `failed`: Optional. Receives why it couldn't be opened; when omitted, it is logged.
- `ExportWaveAsync`: Writes a wave to a file through `SaveFileDataAsync`, as raylib's `ExportWave` does: ".wav" (8, 16 and 24 bits as integers, 32 as floats, as raylib's dr_wav writes them) or ".raw" (the samples as they are). raylib's ".qoa" isn't written here. helix-raylib's own, answering once the file is written; the file is kept as `SaveFileDataAsync` keeps it.
  - `wave`: The wave.
  - `fileName`: The file; its extension chooses the format.
  - `done`: Optional. Called once the file is written, at a later poll.
  - `failed`: Optional. Receives why it wasn't, such as a wave with no samples or another extension; when omitted, it is logged.
- `ExportWaveAsCodeAsync`: Writes a wave as a C header through `SaveFileTextAsync`, as raylib's `ExportWaveAsCode` does: its frames, rate, sample size and channels as defines, and its samples as an array: floats with 4 places for 32-bit samples, else bytes, 20 a line. helix-raylib's own, answering once the file is written.
  - `wave`: The wave.
  - `fileName`: The file; its name, upper case, names the defines and the array.
  - `done`: Optional. Called once the file is written, at a later poll.
  - `failed`: Optional. Receives why it wasn't; when omitted, it is logged.

### Macros, run as the program builds

```haxe
static macro function LoadWaveAsync(fileName:String, loaded:Wave -> Void, ?failed:String -> Void):Void
static macro function LoadWaveFromMemoryAsync(fileType:String, fileData:haxe.io.Bytes, dataSize:Int, loaded:Wave -> Void, ?failed:String -> Void):Void
```

- `LoadWaveAsync`: Loads a sound file's samples, answering when they are read: helix-raylib's own, in place of raylib's `LoadWave`. The formats are `LoadWaveFromMemoryAsync`'s, by the file's extension.
  - `fileName`: The file, as the program names it.
  - `loaded`: Receives the wave, its samples its own.
  - `failed`: Optional. Receives why it couldn't be loaded; when omitted, it is logged.

  The file's reader is chosen as the program builds when its name is a constant (a string, or constants joined with +), so a program naming only Ogg files carries no WAV or QOA reader; a name known only as the program runs brings every reader, the one its extension names chosen then.
- `LoadWaveFromMemoryAsync`: Reads a sound file's samples from its bytes, answering when they are read: helix-raylib's own, in place of raylib's `LoadWaveFromMemory`, as files other than WAV and QOA are decoded off the main thread. Each is read as raylib 5.5 reads it.
  - `fileType`: The file's extension with its dot: ".wav", ".qoa", ".ogg" or ".mp3", or the same in upper case.
  - `fileData`: The file's bytes.
  - `dataSize`: How many of them.
  - `loaded`: Receives the wave, its samples its own.
  - `failed`: Optional. Receives why it couldn't be read; when omitted, it is logged.

  A ".wav" file is read as dr_wav reads it, as 16-bit samples at the file's rate and channels (ADPCM and other compressed WAV encodings aren't read). A ".qoa" file is read as qoa.h reads it, as 16-bit samples, bit for bit. An ".ogg" file (Vorbis) is decoded by the platform at its own rate and made 16-bit as stb_vorbis makes its samples, its frames the stream's length, its last page's position. An ".mp3" file is decoded by the platform at its own rate, every frame of it, as raylib 5.5's dr_mp3 decodes it (a first Xing or Info frame is silence, and the encoder's delay and padding a LAME tag records are kept), and made 16-bit and then 32-bit float samples as that dr_mp3 makes them. Natively an MP3's samples are raylib's and an Ogg file's within 1 in 32768 of them; in a page the decoders are the browser's, so the samples differ in their last bits, and the frames Chromium leaves off an Ogg stream's end (tens of them) are silence. A file of more than 2 channels is mixed to stereo. A ".flac" file isn't read, as raylib 5.5's default build leaves FLAC out ("WAVE: Data format not supported"). As raylib's, the extension is lower or upper case. The answer comes at a later frame.

  The reader is chosen as the program builds when `fileType` is a constant, so a program reading only Ogg files carries no WAV or QOA reader; a type known only as the program runs brings every reader.

## Debug

*class* in [`engines/raylib/src/helix/raylib/extras/Debug.hx`](../../engines/raylib/src/helix/raylib/extras/Debug.hx), `import helix.raylib.extras.Debug;`

Provides drawing for looking at what a program does: a model's skeleton as posed, its posed bounds, and the frame's cost. helix-raylib's own. raylib's DrawModelWires, DrawBoundingBox, DrawGrid and DrawFPS draw the rest. Imported apart: `import helix.raylib.extras.Debug.*;`.

### debug: a model's skeleton and bounds as posed, and the frame's cost

```haxe
static function DrawModelSkeleton(model:Model, position:Vector3, scale:Float, color:Color):Void
static function DrawModelBoundingBoxPosed(model:Model, position:Vector3, scale:Float, color:Color):Void
static function DrawFrameStats(posX:Int, posY:Int, fontSize:Int):Void
static function DrawFrameStatsEx(position:Vector2, style:FrameStatsStyle):Void
static function MeasureFrameStats(style:FrameStatsStyle):Vector2
```

- `DrawModelSkeleton`: Draws a model's skeleton in the pose it has at the call, as DrawModel draws the model: a line from each bone to its parent, and a small cross at each joint, placed as DrawModel places the model. A model never posed draws its bind pose; one without bones draws nothing. Drawn in 3D mode (BeginMode3D), over what's drawn before it, as DrawLine3D is.
  - `model`: The model.
  - `position`: Where the model is drawn, as DrawModel's.
  - `scale`: Its scale, as DrawModel's.
  - `color`: The lines' color.

  One model drawn as several copies, each posed apart, is posed, drawn and looked at copy by copy:

  ```haxe
  for (i in 0...copies) {
  UpdateModelAnimation(model, anim, frame + i * 10);
  var at = new Vector3(i * 2, 0, 0);
  DrawModel(model, at, 1, WHITE);
  DrawModelSkeleton(model, at, 1, YELLOW);
  DrawModelBoundingBoxPosed(model, at, 1, RED);
  }
  ```
- `DrawModelBoundingBoxPosed`: Draws a model's bounds in the pose it has at the call, GetModelBoundingBoxPosed's box (helix.raylib.extras.Models), placed as DrawModel places the model. Drawn in 3D mode, as DrawBoundingBox is.
  - `model`: The model.
  - `position`: Where the model is drawn, as DrawModel's.
  - `scale`: Its scale, as DrawModel's.
  - `color`: The box's color.
- `DrawFrameStats`: Draws the frame's cost at a point on the screen, as DrawFPS draws the rate, in FrameStatsStyle's default look at a size: the frames a second, the frame time's mean and its slowest 5% (p95) over the last half second, in milliseconds, and the last frame's draw calls, a line each. It is `DrawFrameStatsEx(new Vector2(posX, posY), {fontSize: fontSize})`: every other field the style's default, so its color is judged against SetTargetFPS's target, or the monitor's refresh rate without one.
  - `posX`: The text's left, in pixels.
  - `posY`: The text's top, in pixels.
  - `fontSize`: The text's height, in pixels, as DrawText's; DrawFPS draws at 20.
- `DrawFrameStatsEx`: Draws the frame's cost at a point on the screen as a style says: which stats, in what font, size, spacing and colors, over what background. Each stat is a line, so the text's height follows what's shown (MeasureFrameStats). Each number keeps its place: it is right-aligned in a slot of a set width, so the stats don't move as the numbers change.
  - `position`: The text's top left, in pixels (its background's, padding around the text).
  - `style`: What to show and how; each field left out takes its default.

  ```haxe
  DrawFrameStatsEx(new Vector2(10, 10), {fontSize: 24, backgroundColor: Fade(BLACK, 0.5), triangles: true});
  ```
- `MeasureFrameStats`: Returns the size DrawFrameStatsEx draws in with a style, its padding included, sized for its widest values so it doesn't change from frame to frame, for placing it (at a corner, say).
  - `style`: What to show and how.
  - returns: The width and height, in pixels.

## Device

*class* in [`engines/raylib/src/helix/raylib/extras/Device.hx`](../../engines/raylib/src/helix/raylib/extras/Device.hx), `import helix.raylib.extras.Device;`

Provides what a game needs from the device and the page that raylib 5.5 has no call for, helix-raylib's own: the safe area around a notch, the options the program was started with, what the device is, whether the window can close or go fullscreen, the screen's orientation, and the device's tilt. Imported apart: `import helix.raylib.extras.Device.*;`.

Each is answered by helix-platform, on every target. Where a target has no such thing the answer says so (no tilt natively, the whole window as the safe area on a desktop) rather than the call failing to compile, so a game needs no `#if js` for any of them. Each `...Async` call answers at a later poll, never during the call.

```haxe
static inline var ORIENTATION_ANY:Int
static inline var ORIENTATION_LANDSCAPE:Int
static inline var ORIENTATION_PORTRAIT:Int
```

- `ORIENTATION_ANY`: The screen held as the player holds it, or released.
- `ORIENTATION_LANDSCAPE`: The screen held wider than tall.
- `ORIENTATION_PORTRAIT`: The screen held taller than wide.

### device: the safe area, run options, the device, the window's abilities, orientation and tilt

```haxe
static function GetWindowSafeArea():Rectangle
static function GetRunOption(name:String):Null<String>
static function IsPlatformWeb():Bool
static function GetPlatformOS():String
static function IsTouchScreenAvailable():Bool
static function IsFinePointerAvailable():Bool
static function IsWindowCloseable():Bool
static function IsFullscreenAvailable():Bool
static function SetScreenOrientationAsync(orientation:Int, ?done:() -> Void, ?failed:String -> Void):Void
static function GetScreenOrientation():Int
static function EnableTiltAsync(?done:() -> Void, ?failed:String -> Void):Void
static function DisableTilt():Void
static function GetTilt():Vector2
static function SetTiltRange(degrees:Float):Void
static function CalibrateTilt():Void
```

- `GetWindowSafeArea`: Returns the part of the window no notch, rounded corner or system bar covers, in the screen's coordinates (as `GetScreenWidth` measures): where a HUD and buttons go. On a desktop, or in a page without `viewport-fit=cover` in its viewport meta tag, it is the whole window.
  - returns: The safe area.
- `GetRunOption`: Returns an option the program was started with: in a page, the URL's query parameter of that name (`?level=3`); natively, the command line's `--level=3`, or else the environment variable `HELIX_` and the name in capitals (`HELIX_LEVEL=3`).
  - `name`: The option's name.
  - returns: Its value, or null when it isn't set.
- `IsPlatformWeb`: Returns whether the program runs in a browser page rather than natively.
  - returns: True in a page.
- `GetPlatformOS`: Returns the operating system, in lowercase: "windows", "macos", "linux", "android", "ios" or "chromeos"; "" where the platform names none.
  - returns: The system's name.
- `IsTouchScreenAvailable`: Returns whether the device has a touch screen. Always false natively. A laptop may have both a touch screen and a mouse, so touch controls also belong on the first touch, not on this alone.
  - returns: True with a touch screen.
- `IsFinePointerAvailable`: Returns whether the device has a fine pointer: a mouse, a trackpad or a pen. False on a phone or a tablet alone.
  - returns: True with a fine pointer.
- `IsWindowCloseable`: Returns whether the program can close its own window: false in a page, which can't close its tab, so a game hides its Quit there.
  - returns: True where `CloseWindow` ends the program's window.
- `IsFullscreenAvailable`: Returns whether the window can go fullscreen: false in a page that isn't allowed to (an iframe without permission, iOS Safari on an iPhone).
  - returns: True where `ToggleFullscreenAsync` can be granted.
- `SetScreenOrientationAsync`: Asks for the screen to be held one way up, or released. Only some browsers lock it, Chrome on Android only in fullscreen, so ask in `ToggleFullscreenAsync`'s `done`; natively and on iOS it is refused, and a game shows "turn your device" when the shape is wrong (`GetScreenWidth() < GetScreenHeight()`).
  - `orientation`: `ORIENTATION_LANDSCAPE`, `ORIENTATION_PORTRAIT`, or `ORIENTATION_ANY` to release a lock.
  - `done`: Optional. Called once the screen is held, at a later poll.
  - `failed`: Optional. Receives why it was refused; when omitted, it is logged.
- `GetScreenOrientation`: Returns how the screen is held for the program, as `SetScreenOrientationAsync` asked: `ORIENTATION_ANY` when it isn't held. A page loses the lock as it leaves fullscreen.
  - returns: `ORIENTATION_ANY`, `ORIENTATION_LANDSCAPE` or `ORIENTATION_PORTRAIT`.
- `EnableTiltAsync`: Asks for the device's tilt, for a game steered by tilting a phone. A page may need the player's permission, asked at their next tap, so ask before the tap that starts play; natively it is refused.
  - `done`: Optional. Called once readings arrive, at a later poll.
  - `failed`: Optional. Receives why there will be none: refused, the page isn't HTTPS, or no sensor; when omitted, it is logged.
- `DisableTilt`: Stops the tilt's readings. A permission granted stays granted.
- `GetTilt`: Returns the tilt from level, turned with the screen: x across and y down the screen, each -1 to 1 at `SetTiltRange`'s angle; 0 until readings arrive and the device has been held steady once (level is taken then).
  - returns: The tilt.
- `SetTiltRange`: Sets the angle, in degrees, that reads as a full tilt of 1 (30 until set).
  - `degrees`: The angle.
- `CalibrateTilt`: Takes how the device is held now as level.

## Files

*class* in [`engines/raylib/src/helix/raylib/extras/Files.hx`](../../engines/raylib/src/helix/raylib/extras/Files.hx), `import helix.raylib.extras.Files;`

Provides the async versions of raylib 5.5's file calls (rcore), helix-raylib's own, as a page can't wait for a file: `LoadFileTextAsync` for `LoadFileText`, `SaveFileTextAsync` for `SaveFileText`, `FileExistsAsync` for `FileExists` and the rest. raylib's own call doesn't compile and names the one here (docs/DECISIONS.md 24, 38). Imported apart: `import helix.raylib.extras.Files.*;`.

Each answers at a later poll, never during the call: `done` or `loaded` once it is done, `failed` with the reason when it is refused, logged as raylib's warning would be when `failed` is omitted.

### files: the file reads, writes and questions in place of rcore's that wait for a file

```haxe
static function LoadFileDataAsync(fileName:String, loaded:haxe.io.Bytes -> Void, ?failed:String -> Void):Void
static function LoadFileTextAsync(fileName:String, loaded:String -> Void, ?failed:String -> Void):Void
static function SaveFileDataAsync(fileName:String, data:haxe.io.Bytes, dataSize:Int, ?done:() -> Void, ?failed:String -> Void):Void
static function SaveFileTextAsync(fileName:String, text:String, ?done:() -> Void, ?failed:String -> Void):Void
static function FileExistsAsync(fileName:String, answer:Bool -> Void):Void
static function DirectoryExistsAsync(dirPath:String, answer:Bool -> Void):Void
static function IsPathFileAsync(path:String, answer:Bool -> Void):Void
static function GetFileLengthAsync(fileName:String, answer:Int -> Void):Void
static function GetFileModTimeAsync(fileName:String, answer:Int -> Void):Void
static function LoadDirectoryFilesAsync(dirPath:String, loaded:FilePathList -> Void):Void
static function LoadDirectoryFilesExAsync(basePath:String, filter:String, scanSubdirs:Bool, loaded:FilePathList -> Void):Void
static function ExportDataAsCodeAsync(data:haxe.io.Bytes, dataSize:Int, fileName:String, ?done:() -> Void, ?failed:String -> Void):Void
static function LoadAutomationEventListAsync(fileName:String, loaded:AutomationEventList -> Void, ?failed:String -> Void):Void
static function ExportAutomationEventListAsync(list:AutomationEventList, fileName:String, ?done:() -> Void, ?failed:String -> Void):Void
```

- `LoadFileDataAsync`: Reads a file's bytes, answering when they are read: helix-raylib's own, in place of raylib's `LoadFileData`. The program's `SetLoadFileDataCallback` answers first, then what `SaveFileData` wrote, then the program's files.
  - `fileName`: The file.
  - `loaded`: Receives its bytes.
  - `failed`: Optional. Receives why it couldn't be read; when omitted, it is logged.
- `LoadFileTextAsync`: Reads a text file, answering when it is read: helix-raylib's own, in place of raylib's `LoadFileText`. The program's `SetLoadFileTextCallback` answers first, then what `SaveFileText` wrote, then the program's files.
  - `fileName`: The file.
  - `loaded`: Receives its text.
  - `failed`: Optional. Receives why it couldn't be read; when omitted, it is logged.

  A file's text ends at its first NUL byte, as raylib's C string does, and a byte that isn't UTF-8 is read as U+FFFD: a file is never refused for what it holds.
- `SaveFileDataAsync`: Writes a file's bytes, answering once they are kept or refused: helix-raylib's own, in place of raylib's `SaveFileData`. They are written through the program's `SetSaveFileDataCallback` when it has one, else kept across runs as `SaveFileTextAsync`'s are. `LoadFileDataAsync` reads them back.
  - `fileName`: The file.
  - `data`: The bytes.
  - `dataSize`: How many of them.
  - `done`: Optional. Called once the file is written, at a later poll.
  - `failed`: Optional. Receives why it wasn't; when omitted, it is logged.
- `SaveFileTextAsync`: Writes a text file, answering once it is kept or refused: helix-raylib's own, in place of raylib's `SaveFileText`. It is written through the program's `SetSaveFileTextCallback` when it has one, during the call, answered by what that returned. Otherwise it is answered once the write has finished. The save file persists between runs, including both native and web builds. `LoadFileTextAsync` reads it back.
  - `fileName`: The file.
  - `text`: Its text.
  - `done`: Optional. Called once the file is written, at a later poll.
  - `failed`: Optional. Receives why it wasn't; when omitted, it is logged.
- `FileExistsAsync`: Answers whether a file exists: helix-raylib's own, in place of raylib's `FileExists`. One `SaveFileText` or `SaveFileData` wrote exists, as does one of the program's; finding one of the program's reads it, so a load of it after answers at once. The answer comes at a later frame, never during the call.
  - `fileName`: The file.
  - `answer`: Receives true when it exists.
- `DirectoryExistsAsync`: Answers whether a directory exists: helix-raylib's own, in place of raylib's `DirectoryExists`. Natively it is a directory of the program's files; `helix-raylib-dropped` and the directories under it hold the dropped files. A page's own files are on its server, which can't be listed, so there only its root ("", "." or "./") and the dropped files' directories exist. The answer comes at a later frame, never during the call.
  - `dirPath`: The directory.
  - `answer`: Receives true when it exists.
- `IsPathFileAsync`: Answers whether a path is a file, not a directory: helix-raylib's own, in place of raylib's `IsPathFile`. A file `SaveFileText` or `SaveFileData` wrote, a dropped file, and a file the program has, as `FileExistsAsync` finds them, are files. The answer comes at a later frame, never during the call.
  - `path`: The path.
  - `answer`: Receives true for a file; false for a directory or nothing there.
- `GetFileLengthAsync`: Answers a file's size: helix-raylib's own, in place of raylib's `GetFileLength`. A file `SaveFileText` or `SaveFileData` wrote, or the program's `SetLoadFileDataCallback` gives, is its bytes' size; a dropped file's is its own. Natively a file of the program's is its size on disk; in a page it is read from the server to be measured, so a load of it after answers at once. The answer comes at a later frame, never during the call.
  - `fileName`: The file.
  - `answer`: Receives its size in bytes; 0 when there is no file, as raylib's.
- `GetFileModTimeAsync`: Answers when a file was last written: helix-raylib's own, in place of raylib's `GetFileModTime`. Natively a file of the program's answers its time on disk; a file `SaveFileText` or `SaveFileData` wrote, when it was saved. A page's own files are on its server, and a dropped file or one the program's load callback gives has no time kept, so each answers 0. The answer comes at a later frame, never during the call.
  - `fileName`: The file.
  - `answer`: Receives the time, in whole seconds since the Unix epoch; 0 when there is no file or no time, as raylib's.
- `LoadDirectoryFilesAsync`: Lists a directory's files and subdirectories: helix-raylib's own, in place of raylib's `LoadDirectoryFiles`. Each path is the directory's followed by `/` and the name (`dirPath` "levels" gives "levels/1.json"), sorted by name, a subdirectory's without a slash at its end. The directories are `DirectoryExistsAsync`'s; a page lists only the dropped files. Files `SaveFileText` and `SaveFileData` wrote aren't listed. The answer comes at a later frame, never during the call.
  - `dirPath`: The directory.
  - `loaded`: Receives the list, its `capacity` its `count`; empty, with a warning, when the directory can't be listed, as raylib's.
- `LoadDirectoryFilesExAsync`: Lists a directory's files, those with some extensions, and with `scanSubdirs` its subdirectories' too: helix-raylib's own, in place of raylib's `LoadDirectoryFilesEx`. The paths are `LoadDirectoryFilesAsync`'s, a subdirectory's files right after it. As raylib's: a null filter keeps every file, and without `scanSubdirs` every subdirectory too; a filter is `IsFileExtension`'s list, and "DIR" in it keeps the subdirectories; at most 8192 paths are listed (`MAX_FILEPATH_CAPACITY`), with a warning when there are more. The answer comes at a later frame, never during the call.
  - `basePath`: The directory.
  - `filter`: The extensions kept, such as ".png;.jpg;DIR", or null for every file.
  - `scanSubdirs`: Whether the subdirectories' files are listed too.
  - `loaded`: Receives the list, its `capacity` 8192; a directory that can't be listed adds nothing, with a warning.
- `ExportDataAsCodeAsync`: Writes bytes as a C header through `SaveFileTextAsync`, as raylib's `ExportDataAsCode` does, byte for byte: their count as a define, and the bytes as an array, in hexadecimal, 20 a line. helix-raylib's own, answering once the file is written.
  - `data`: The bytes.
  - `dataSize`: How many of them.
  - `fileName`: The file; its name, upper case, names the define and the array, with `_` for `.`, `-`, `?`, `!` and `+`.
  - `done`: Optional. Called once the file is written, at a later poll.
  - `failed`: Optional. Receives why it wasn't; when omitted, it is logged.
- `LoadAutomationEventListAsync`: Loads an automation events list from a text file, answering when it is read: helix-raylib's own, in place of raylib's `LoadAutomationEventList` given a file. It reads the file as `LoadFileTextAsync` does, then as raylib's does: each line starting `c` sets the count, each starting `e` is an event, its frame, type and four parameters; other lines are skipped, and so is a last line with no newline at its end, as raylib's reading skips it. A count that isn't the events read warns, and the events read are the count.
  - `fileName`: The file, as `ExportAutomationEventList` writes it.
  - `loaded`: Receives the list, its capacity 16384.
  - `failed`: Optional. Receives why it couldn't be read; when omitted, it is logged.
- `ExportAutomationEventListAsync`: Writes a list's events as text through `SaveFileTextAsync`, as raylib's `ExportAutomationEventList` does, byte for byte: a header of comments, `c` and the count, then a line for each event, `e`, its frame, type and four parameters, and its type's name. helix-raylib's own, answering once the file is written.
  - `list`: The list.
  - `fileName`: The file.
  - `done`: Optional. Called once the file is written, at a later poll.
  - `failed`: Optional. Receives why it wasn't; when omitted, it is logged.

## Gui

*class* in [`engines/raylib/src/helix/raylib/extras/Gui.hx`](../../engines/raylib/src/helix/raylib/extras/Gui.hx), `import helix.raylib.extras.Gui;`

Provides the async versions of raygui's style and icon loads, helix-raylib's own, as a page can't wait for a file: `GuiLoadStyleAsync` for `GuiLoadStyle` and `GuiLoadIconsAsync` for `GuiLoadIcons`. raygui's own call doesn't compile and names the one here (docs/DECISIONS.md 38). Imported apart: `import helix.raylib.extras.Gui.*;`.

Each answers at a later poll, never during the call: `done` or `loaded` once it is done, `failed` with the reason when it is refused, logged as raylib's warning would be when `failed` is omitted.

### gui: the style and icon loads in place of raygui's that wait for a file

```haxe
static function GuiLoadStyleAsync(fileName:String, ?done:() -> Void, ?failed:String -> Void):Void
static function GuiLoadIconsAsync(fileName:String, loadIconsName:Bool, loaded:Array<String> -> Void, ?failed:String -> Void):Void
```

- `GuiLoadStyleAsync`: Loads a style file (.rgs) over the style, answering when it is loaded: helix-raylib's own, in place of raygui's `GuiLoadStyle`, as a page can't wait for a file. A text file (its first line starting with '#') sets each property its "p" lines name, and its "f" line loads the font it names, beside the style file, at its size and with the characters of its charmap file; a font that can't be loaded leaves raylib's default font at size 10. A binary file sets its properties and, when it holds one, its font, its atlas decompressed. The default style is loaded first if it isn't yet. As in raygui, a text file's last line is read only when a line break ends it.
  - `fileName`: The style file.
  - `done`: Optional. Called once the style is loaded, at a later poll.
  - `failed`: Optional. Receives why it couldn't be read; when omitted, it is logged.
- `GuiLoadIconsAsync`: Loads an icon file (.rgi) over the icons, answering when it is loaded: helix-raylib's own, in place of raygui's `GuiLoadIcons`, as a page can't wait for a file. Its icons are read over raygui's from the first, as raygui reads them; a file that isn't an icon file changes nothing.
  - `fileName`: The icon file.
  - `loadIconsName`: Whether the icons' names are read.
  - `loaded`: Receives the icons' names, in order, or null when they weren't read or the file isn't an icon file.
  - `failed`: Optional. Receives why it couldn't be read; when omitted, it is logged.

## GuiSkins

*class* in [`engines/raylib/src/helix/raylib/extras/GuiSkins.hx`](../../engines/raylib/src/helix/raylib/extras/GuiSkins.hx), `import helix.raylib.extras.GuiSkins;`

Provides skins for raygui's controls, helix-raylib's own: a part of a control drawn from a texture, stretched as a nine-patch so its corners keep their shape, in place of its style's flat colors. The controls keep raygui's signatures, so a skinned button is still `GuiButton(bounds, text)`, and its text is still drawn in the style's text colors and font. Imported apart: `import helix.raylib.extras.GuiSkins.*;`. The skin's type, `GuiSkin`, is `helix.raylib`'s, with raylib's.

```haxe
// button.png: a cell of 190 x 49 for each state, top down (normal, focused, pressed, disabled), borders of 14.
LoadTextureAsync("assets/button.png", sheet -> GuiSetSkin(BUTTON, GUI_SKIN_BASE, GuiSkinFromSheet(sheet, 190, 49, 14, 14, 14, 14)));
...
if (GuiButton(new Rectangle(20, 20, 190, 49), "Play") != 0) ...
```

The parts each control draws:

| control | `GUI_SKIN_BASE` | `GUI_SKIN_FILL` | `GUI_SKIN_HANDLE` | `GUI_SKIN_ITEM` | |---|---|---|---|---| | `DEFAULT` | `GuiPanel`'s, `GuiWindowBox`'s and `GuiScrollPanel`'s body | | | | | `BUTTON` | `GuiButton`, and `GuiSpinner`'s arrows | | | | | `TOGGLE` | a toggle, each of a toggle group's, a toggle slider's box | a toggle slider's selection | | | | `SLIDER` | the box | `GuiSliderBar`'s bar | `GuiSlider`'s handle | | | `PROGRESSBAR` | the box | the progress | | | | `CHECKBOX` | the box | the check | | | | `COMBOBOX`, `TEXTBOX`, `VALUEBOX`, `STATUSBAR` | the box | | | | | `DROPDOWNBOX` | the box | | | an open list's focused and chosen items | | `LISTVIEW` | the box | | | the focused and active items | | `SCROLLBAR` | the bar and its track | | the thumb | |

A control draws its state's patch: `STATE_FOCUSED` with the pointer over it, `STATE_PRESSED` held down (and a toggle on), `STATE_DISABLED` between `GuiDisable` and `GuiEnable` or under `GuiSetState(STATE_DISABLED)`. A program that sets no skin links none of this.

```haxe
static inline var GUI_SKIN_BASE:Int
static inline var GUI_SKIN_FILL:Int
static inline var GUI_SKIN_HANDLE:Int
static inline var GUI_SKIN_ITEM:Int
```

- `GUI_SKIN_BASE`: A control's box: its border and background. Every control has one.
- `GUI_SKIN_FILL`: The part a control fills to show its value: a slider's or progress bar's bar, a check box's check.
- `GUI_SKIN_HANDLE`: The part a control is dragged by: a slider's handle, a scroll bar's thumb.
- `GUI_SKIN_ITEM`: One item of a list: a list view's row, a drop-down box's choice, a toggle group's toggle.

### gui skins: raygui's controls drawn from textures

```haxe
static function GuiSkinFromTexture(texture:Texture2D, normal:NPatchInfo, ?focused:NPatchInfo, ?pressed:NPatchInfo, ?disabled:NPatchInfo, ?tint:Color):GuiSkin
static function GuiSkinFromSheet(texture:Texture2D, cellWidth:Int, cellHeight:Int, left:Int, top:Int, right:Int, bottom:Int):GuiSkin
static function GuiSetSkin(control:Int, part:Int, skin:Null<GuiSkin>):Void
static function GuiGetSkin(control:Int, part:Int):Null<GuiSkin>
static function GuiClearSkins():Void
```

- `GuiSkinFromTexture`: Makes a skin from a texture and its patches, one for each state.
  - `texture`: The texture the patches are cut from.
  - `normal`: The patch drawn in `STATE_NORMAL`.
  - `focused`: Optional. The patch drawn in `STATE_FOCUSED`; `normal` when omitted.
  - `pressed`: Optional. The patch drawn in `STATE_PRESSED`; `focused` when omitted, or `normal` without it.
  - `disabled`: Optional. The patch drawn in `STATE_DISABLED`; `normal` when omitted.
  - `tint`: Optional. The color the patches are multiplied by; `WHITE` when omitted.
  - returns: The skin.
- `GuiSkinFromSheet`: Makes a skin from a sheet of a control's states, cells of one size in raygui's order of states: normal, focused, pressed and disabled, from the top down, or from the left across when the sheet is one cell high. A sheet of fewer than four cells leaves the rest to their fallbacks (`GuiSkin`). Each cell is cut as a nine-patch by the same borders.
  - `texture`: The sheet.
  - `cellWidth`: A cell's width, in texels.
  - `cellHeight`: A cell's height, in texels.
  - `left`: The left border's width, in texels, kept unstretched.
  - `top`: The top border's height.
  - `right`: The right border's width.
  - `bottom`: The bottom border's height.
  - returns: The skin.
- `GuiSetSkin`: Sets the skin a part of a control is drawn with, in place of its style's border and base colors. It is read as each control draws, so a skin set before one call and put back after it changes that call's control alone.
  - `control`: The control: `DEFAULT`, `BUTTON`, `SLIDER` and the rest of raygui's.
  - `part`: `GUI_SKIN_BASE`, `GUI_SKIN_FILL`, `GUI_SKIN_HANDLE` or `GUI_SKIN_ITEM`.
  - `skin`: The skin, or null to draw the part flat in its style's colors again.

  Set on `DEFAULT`, it is set on every control too, as raygui's `GuiSetStyle` sets `DEFAULT`'s base properties, so set it first and each control's own after. `DEFAULT`'s own `GUI_SKIN_BASE` is what `GuiPanel`, `GuiWindowBox` and `GuiScrollPanel` draw their body with.
- `GuiGetSkin`: Returns the skin a part of a control is drawn with, for putting it back after a change.
  - `control`: The control.
  - `part`: The part.
  - returns: The skin, or null when the part is drawn flat.
- `GuiClearSkins`: Removes every skin, so every control is drawn flat in its style's colors again. Loading a style leaves skins as they are.

## Lights

*class* in [`engines/raylib/src/helix/raylib/extras/Lights.hx`](../../engines/raylib/src/helix/raylib/extras/Lights.hx), `import helix.raylib.extras.Lights;`

Provides raylib's examples' lights, `rlights.h` as raylib's lighting examples include it, and the lit shader they light, built in: `LoadLightingShader` in place of loading the examples' `lighting.vs` and `lighting.fs`, so the examples' code runs as it is but for that load. Imported apart: `import helix.raylib.extras.Lights.*;`. The light's type, `Light`, is `helix.raylib`'s, with raylib's.

```haxe
var shader = LoadLightingShader();
SetShaderValue(shader, GetShaderLocation(shader, "ambient"), [0.1, 0.1, 0.1, 1.0], SHADER_UNIFORM_VEC4);
var light = CreateLight(LIGHT_POINT, new Vector3(-2, 1, -2), Vector3Zero(), YELLOW, shader);
model.materials[0].shader = shader;
// each frame
SetShaderValue(shader, shader.locs[SHADER_LOC_VECTOR_VIEW], [camera.position.x, camera.position.y, camera.position.z],
SHADER_UNIFORM_VEC3);
UpdateLightValues(shader, light);
```

A model posed by `UpdateModelAnimation` under the lit shader is skinned on the GPU. A program's own shader lights as it does by including `<helix/raylib/shaders/lights.glsl>`, whose head comment says what it declares. A program that calls none of this links none of it.

```haxe
static inline var MAX_LIGHTS:Int
static inline var LIGHT_DIRECTIONAL:Int
static inline var LIGHT_POINT:Int
```

- `MAX_LIGHTS`: The most lights a lit shader holds, rlights' `MAX_LIGHTS`.
- `LIGHT_DIRECTIONAL`: A light shining one way from far off, from its position toward its target, rlights' `LIGHT_DIRECTIONAL`.
- `LIGHT_POINT`: A light shining every way from its position, rlights' `LIGHT_POINT`.

### lights: raylib's examples' rlights and the lit shader built on them

```haxe
static function LoadLightingShader():Shader
static function CreateLight(type:Int, position:Vector3, target:Vector3, color:Color, shader:Shader):Light
static function UpdateLightValues(shader:Shader, light:Light):Void
```

- `LoadLightingShader`: Returns helix-raylib's lit shader: raylib's examples' `lighting.vs` and `lighting.fs`, built in, so a program needs no shader files. Its locations are set as raylib's lighting example sets them: `locs[SHADER_LOC_VECTOR_VIEW]` is `viewPos`, which the program sets to the camera's position each frame; `GetShaderLocation(shader, "ambient")` finds the ambient color. Lights are added with `CreateLight`. A model posed by `UpdateModelAnimation` under it is skinned on the GPU. Its stages are `helix/raylib/shaders/lit.vs` and `lit.fs`, over `<helix/raylib/shaders/lights.glsl>`, which a program's own shader can include.
  - returns: The shader, the program's until `UnloadShader`.

  ```haxe
  var shader = LoadLightingShader();
  var ambientLoc = GetShaderLocation(shader, "ambient");
  SetShaderValue(shader, ambientLoc, [0.1, 0.1, 0.1, 1.0], SHADER_UNIFORM_VEC4);
  model.materials[0].shader = shader;
  var light = CreateLight(LIGHT_POINT, new Vector3(-2, 1, -2), Vector3Zero(), YELLOW, shader);
  ```
- `CreateLight`: Makes a light and sets it in a lit shader, as rlights' `CreateLight`: the next of the shader's `lights`, its locations found by name (`lights[0].enabled` and the rest). Past `MAX_LIGHTS` lights it makes a light that is off and sets nothing. The count is the program's, as rlights' is, not the shader's.
  - `type`: `LIGHT_DIRECTIONAL` or `LIGHT_POINT`.
  - `position`: Where it is.
  - `target`: Where it points, for a directional light.
  - `color`: Its color.
  - `shader`: The lit shader.
  - returns: The light.
- `UpdateLightValues`: Sets a light's values in a lit shader, as rlights' `UpdateLightValues`: whether it is on, its type, position, target and color, for the draws after it.
  - `shader`: The lit shader.
  - `light`: The light.

## Models

*class* in [`engines/raylib/src/helix/raylib/extras/Models.hx`](../../engines/raylib/src/helix/raylib/extras/Models.hx), `import helix.raylib.extras.Models;`

Provides the async versions of raylib 5.5's model, material and animation loads and mesh writes (rmodels), helix-raylib's own, as a page can't wait for a file: `LoadModelAsync` for `LoadModel`, `LoadModelAnimationsAsync` for `LoadModelAnimations` and the rest. raylib's own call doesn't compile and names the one here (docs/DECISIONS.md 24, 38). Imported apart: `import helix.raylib.extras.Models.*;`.

Each answers at a later poll, never during the call: `done` or `loaded` once it is done, `failed` with the reason when it is refused, logged as raylib's warning would be when `failed` is omitted.

And a model's bounds as posed, which raylib's `GetModelBoundingBox` leaves at the bind pose: `GetModelBoundingBoxPosed`.

### models: the model, material and animation loads and mesh writes in place of rmodels' that wait

```haxe
static function LoadModelAnimationsAsync(fileName:String, loaded:Array<ModelAnimation> -> Void, ?failed:String -> Void):Void
static function LoadMaterialsAsync(fileName:String, loaded:Array<Material> -> Void, ?failed:String -> Void):Void
static function ExportMeshAsync(mesh:Mesh, fileName:String, ?done:() -> Void, ?failed:String -> Void):Void
static function ExportMeshAsCodeAsync(mesh:Mesh, fileName:String, ?done:() -> Void, ?failed:String -> Void):Void
```

- `LoadModelAnimationsAsync`: Loads a glTF or GLB file's animations, answering when they are read: helix-raylib's own, in place of raylib's `LoadModelAnimations`. They are read as raylib 6.2 reads them, of the file's first skin: each sampled 60 times a second, with (int)(duration * 60) + 1 frames, each frame's pose its bones' transforms in the model. A file without skins gives none. IQM and M3D animations aren't read (docs/DECISIONS.md 27).
  - `fileName`: The file, as the program names it.
  - `loaded`: Receives the animations, as many as the file has; their count is its length.
  - `failed`: Optional. Receives why they couldn't be loaded; when omitted, it is logged.
- `LoadMaterialsAsync`: Loads the materials of an .mtl file, with the textures they name, answering when they are ready: helix-raylib's own, in place of raylib's `LoadMaterials`. Each is made as raylib's `ProcessMaterialsOBJ` makes it: raylib's default material, then its diffuse texture (`map_Kd`), or with none its diffuse color (`Kd`, alpha 255); its specular texture (`map_Ks`) and color (`Ks`); the normal map its bump texture (`bump` or `map_bump`), white, its value the specular exponent (`Ns`); its emission color (`Ke`); the height map its displacement texture (`disp`). What a material doesn't give is tinyobj_loader_c's default, as raylib has it: each color black, the specular exponent 1. A texture that can't be read is none (id 0, logged). The program holds each material until `UnloadMaterial`. Where raylib's reading is broken, helix-raylib reads the file as the format has it (a texture's path resolved against the file's directory among them), and a file that breaks the format fails (docs/DECISIONS.md 28).
  - `fileName`: The file, as the program names it: an .mtl file.
  - `loaded`: Receives the materials, in the file's order; their count is its length.
  - `failed`: Optional. Receives why they couldn't be loaded (the file isn't an .mtl file, can't be found or can't be read); when omitted, it is logged.
- `ExportMeshAsync`: Writes a mesh as an OBJ file through `SaveFileTextAsync`, as raylib's `ExportMesh` does: its positions and texture coordinates to 6 places, its normals to 4, and a face a triangle. helix-raylib's own, answering once the file is written.
  - `mesh`: The mesh, with positions, texture coordinates and normals.
  - `fileName`: The file; only ".obj" is written.
  - `done`: Optional. Called once the file is written, at a later poll.
  - `failed`: Optional. Receives why it wasn't, such as another extension; when omitted, it is logged.
- `ExportMeshAsCodeAsync`: Writes a mesh as a C header through `SaveFileTextAsync`, as raylib's `ExportMeshAsCode` does: its counts as defines, and each array it has, 20 values a line, floats to 3 places. helix-raylib's own, answering once the file is written.
  - `mesh`: The mesh.
  - `fileName`: The file; its name, upper case, names the defines and the arrays.
  - `done`: Optional. Called once the file is written, at a later poll.
  - `failed`: Optional. Receives why it wasn't; when omitted, it is logged.

### models: a skinned model's bounds as posed

```haxe
static function GetModelBoundingBoxPosed(model:Model):BoundingBox
```

- `GetModelBoundingBoxPosed`: Returns a model's bounds as its last `UpdateModelAnimation` (or `UpdateModelAnimationEx`) posed it: `GetModelBoundingBox`'s box, each skinned mesh bounded by its vertices where its bones put them rather than where the skin was bound. A mesh never posed, or without bones, counts as it is, and so does a vertex no bone weights. It is exact whatever shader draws the mesh, as it works the positions out from the pose itself, allocating nothing; that is each skinned vertex moved by its bones, on the CPU, each call. As `GetModelBoundingBox`, its least and most corners are then moved by the model's transform (a turned model's box is not its bounds).
  - `model`: The model.
  - returns: The box.

### Macros, run as the program builds

```haxe
static macro function LoadModelAsync(fileName:String, loaded:Model -> Void, ?failed:String -> Void):Void
```

- `LoadModelAsync`: Loads a model from a glTF, GLB or OBJ file, with the files it points to (a glTF file's images and buffers, an OBJ file's material library and its textures), answering when it is ready: helix-raylib's own, in place of raylib's `LoadModel`. A file loaded again, while a load of it lives, shares its meshes' GPU buffers and its textures, with materials of its own.
  - `fileName`: The file, as the program names it.
  - `loaded`: Receives the model.
  - `failed`: Optional. Receives why it couldn't be loaded; when omitted, it is logged.

  An OBJ file is read as raylib 6.2's `LoadOBJ` reads it: its polygons split into fans of triangles; a new mesh at each `g` or `o` line with faces after it, and where a face's material differs from the face before's, unless that face had none (faces before any `usemtl` join the next material's mesh); its vertices its triangles' corners, unindexed; a corner without a normal, or naming one the file doesn't have, given (0, 1, 0), one without texture coordinates (0, 0), the others' v turned (1 - v), and one naming a position the file doesn't have (0, 0, 0); every vertex's color white, whatever colors the file gives; each mesh's material its last face's, or 0 when that is no material of the library. Its materials are the library's, read as `LoadMaterialsAsync` reads them, of the file's last `mtllib` line; with no library, or one that can't be read (logged), the model has raylib's default material alone. raylib counts the start of each group in the file's `f` lines against the triangles it has made, so a polygon, or a face of 1 or 2 corners, before a group moves the group's first mesh; helix-raylib does too. An empty file fails to load, as one raylib can't read. Where raylib's reading is broken, helix-raylib reads the file as the format has it, and a file that breaks the format fails to load (docs/DECISIONS.md 28). IQM, VOX and M3D models aren't read (docs/DECISIONS.md 27).

  The file's reader is chosen as the program builds when its name is a constant (a string, or constants joined with +), so a program naming only glTF files carries no OBJ reader, and one naming only OBJ files no glTF reader; a name known only as the program runs brings both, the reader chosen by its extension then.

## Text

*class* in [`engines/raylib/src/helix/raylib/extras/Text.hx`](../../engines/raylib/src/helix/raylib/extras/Text.hx), `import helix.raylib.extras.Text;`

Provides the async versions of raylib 5.5's font loads and writes (rtext), helix-raylib's own, as a page can't wait for a file and glyphs are rasterized off the main thread: `LoadFontAsync` for `LoadFont`, `LoadFontExAsync` for `LoadFontEx` and the rest. raylib's own call doesn't compile and names the one here (docs/DECISIONS.md 24, 38). Imported apart: `import helix.raylib.extras.Text.*;`.

Each answers at a later poll, never during the call: `done` or `loaded` once it is done, `failed` with the reason when it is refused, logged as raylib's warning would be when `failed` is omitted.

### text: the font loads and writes in place of rtext's that wait

```haxe
static function LoadFontExAsync(fileName:String, fontSize:Int, codepoints:Array<Int>, codepointCount:Int, loaded:Font -> Void, ?failed:String -> Void):Void
static function LoadFontFromMemoryAsync(fileType:String, fileData:haxe.io.Bytes, dataSize:Int, fontSize:Int, codepoints:Array<Int>, codepointCount:Int, loaded:Font -> Void, ?failed:String -> Void):Void
static function LoadFontDataAsync(fileData:haxe.io.Bytes, dataSize:Int, fontSize:Int, codepoints:Array<Int>, codepointCount:Int, type:Int, loaded:Array<GlyphInfo> -> Void, ?failed:String -> Void):Void
static function ExportFontAsCodeAsync(font:Font, fileName:String, ?done:() -> Void, ?failed:String -> Void):Void
```

- `LoadFontExAsync`: Loads a TrueType or OpenType font file at a size, answering when its glyphs are ready: helix-raylib's own, in place of raylib's `LoadFontEx`.
  - `fileName`: The file, as the program names it.
  - `fontSize`: The glyphs' size: the height of a line, in pixels.
  - `codepoints`: The characters, or null for those from the space on.
  - `codepointCount`: How many characters; 0 for 95, the printable ASCII when `codepoints` is null.
  - `loaded`: Receives the font.
  - `failed`: Optional. Receives why it couldn't be loaded; when omitted, it is logged.

  The font holds only the characters the file has, so `glyphCount` may be fewer than asked for and a character it lacks draws as its '?'; each Unicode space it has (U+0020, U+00A0, U+2000 to U+200A, U+3000 and the others) is a blank glyph as wide as its advance.
- `LoadFontFromMemoryAsync`: Makes a font from a TrueType or OpenType file's bytes, answering when its glyphs are ready: helix-raylib's own, in place of raylib's `LoadFontFromMemory`, as the glyphs are rasterized off the main thread.
  - `fileType`: The file's extension, ".ttf" or ".otf".
  - `fileData`: The file's bytes.
  - `dataSize`: How many of them.
  - `fontSize`: The glyphs' size: the height of a line, in pixels.
  - `codepoints`: The characters, or null for those from the space on.
  - `codepointCount`: How many characters; 0 for 95.
  - `loaded`: Receives the font.
  - `failed`: Optional. Receives why it couldn't be made; when omitted, it is logged.

  The font holds only the characters the file has, as `LoadFontExAsync`'s does; with none of them, it is the default font.
- `LoadFontDataAsync`: Rasterizes a TrueType or OpenType font's glyphs, answering when they are ready: helix-raylib's own, in place of raylib's `LoadFontData`. Each glyph has its own image, 8-bit grayscale, for `GenImageFontAtlas`; `FONT_SDF` makes them signed distances, with 4 texels of padding, 128 on the outline and 64 a texel.
  - `fileData`: The font file's bytes.
  - `dataSize`: How many of them.
  - `fontSize`: The glyphs' size: the height of a line, in pixels.
  - `codepoints`: The characters, or null for those from the space on.
  - `codepointCount`: How many characters; 0 for 95.
  - `type`: `FONT_DEFAULT` for antialiased glyphs, `FONT_BITMAP` for glyphs with no gray, `FONT_SDF` for signed distances.
  - `loaded`: Receives the glyphs.
  - `failed`: Optional. Receives why the font couldn't be read; when omitted, it is logged.
- `ExportFontAsCodeAsync`: Writes a font as a C header through `SaveFileTextAsync`, the text raylib 5.5's `ExportFontAsCode` writes: its texture's pixels in the texture's format (gray and alpha for the default font and a TrueType font's), compressed as `CompressData` compresses them, 20 bytes a line; each glyph's rectangle and its character, offsets and advance; and a function loading it. The file's name, in Pascal case, names them. The pixels are those the font's texture was made from, or the texture's own while it hasn't been drawn; one made otherwise and already on the GPU (a render texture's) is written as an empty image, as raylib writes a texture it can't read back. helix-raylib's own, answering once the file is written.
  - `font`: The font.
  - `fileName`: The file.
  - `done`: Optional. Called once the file is written, at a later poll.
  - `failed`: Optional. Receives why it wasn't; when omitted, it is logged.

### Macros, run as the program builds

```haxe
static macro function LoadFontAsync(fileName:String, loaded:Font -> Void, ?failed:String -> Void):Void
```

- `LoadFontAsync`: Loads a font file, answering when its glyphs are ready: helix-raylib's own, in place of raylib's `LoadFont`. A TrueType or OpenType file gives its printable ASCII at 32 pixels; a BMFont (.fnt, the text format) its characters and pages, the pages stacked onto one texture, as raylib's; an image (PNG, JPEG, BMP, TGA, QOI, or a GIF file's first frame) its glyphs on a `MAGENTA` key from the space on, as `LoadFontFromImage` reads them; each drawn with `TEXTURE_FILTER_POINT`. The GIF reader is chosen as the program builds as `LoadImageAsync`'s is.
  - `fileName`: The file, as the program names it.
  - `loaded`: Receives the font.
  - `failed`: Optional. Receives why it couldn't be loaded; when omitted, it is logged.

## Textures

*class* in [`engines/raylib/src/helix/raylib/extras/Textures.hx`](../../engines/raylib/src/helix/raylib/extras/Textures.hx), `import helix.raylib.extras.Textures;`

Provides the async versions of raylib 5.5's image and texture loads and writes (rtextures), helix-raylib's own, as a page can't wait for a file or the GPU: `LoadTextureAsync` for `LoadTexture`, `LoadImageAsync` for `LoadImage`, `ExportImageAsync` for `ExportImage` and the rest. raylib's own call doesn't compile and names the one here (docs/DECISIONS.md 24, 38). Imported apart: `import helix.raylib.extras.Textures.*;`.

Each answers at a later poll, never during the call: `done` or `loaded` once it is done, `failed` with the reason when it is refused, logged as raylib's warning would be when `failed` is omitted.

### textures: the image and texture loads and writes in place of rtextures' that wait

```haxe
static function LoadImageRawAsync(fileName:String, width:Int, height:Int, format:Int, headerSize:Int, loaded:Image -> Void, ?failed:String -> Void):Void
static function LoadImageFromTextureAsync(texture:Texture2D, loaded:Image -> Void, ?failed:String -> Void):Void
static function LoadImageFromScreenAsync(loaded:Image -> Void, ?failed:String -> Void):Void
static function ExportImageAsync(image:Image, fileName:String, ?done:() -> Void, ?failed:String -> Void):Void
static function ExportImageAsCodeAsync(image:Image, fileName:String, ?done:() -> Void, ?failed:String -> Void):Void
```

- `LoadImageRawAsync`: Loads an image's raw pixels from a file, answering when they are read: helix-raylib's own, in place of raylib's `LoadImageRaw`. The file holds the pixels in a format, after a header of some bytes; a file too small for them fails.
  - `fileName`: The file.
  - `width`: The width, in pixels.
  - `height`: The height, in pixels.
  - `format`: The pixel format (`PIXELFORMAT_*`).
  - `headerSize`: The bytes before the pixels, skipped when the file holds them and the pixels.
  - `loaded`: Receives the image.
  - `failed`: Optional. Receives why it couldn't be loaded; when omitted, it is logged.
- `LoadImageFromTextureAsync`: Reads a texture's pixels, answering when they are read: helix-raylib's own, in place of raylib's `LoadImageFromTexture`, as the GPU answers later. A texture on the GPU (one drawn, or a render texture) is read back from it as the frames drawn so far left it; a render texture's rows come bottom first, as raylib's do, so it reads upside down as raylib's does. A texture updated this frame (`UpdateTexture`) is read once the frame is drawn, so the update shows. One not drawn yet is read from memory (raylib's default texture is its white pixel). The image is RGBA, whatever the texture's format. A cubemap's can't be read.
  - `texture`: The texture.
  - `loaded`: Receives the image, `PIXELFORMAT_UNCOMPRESSED_R8G8B8A8`.
  - `failed`: Optional. Receives why it couldn't be read; when omitted, it is logged.
- `LoadImageFromScreenAsync`: Reads the screen, answering as the next frame ends: helix-raylib's own, in place of raylib's `LoadImageFromScreen`, as the GPU answers later. The image is the framebuffer's size, as raylib 6.2's is (5.5 scaled the screen's size by its DPI instead), rows top first, its alpha opaque.
  - `loaded`: Receives the image, `PIXELFORMAT_UNCOMPRESSED_R8G8B8A8`.
  - `failed`: Optional. Receives why it couldn't be read; when omitted, it is logged.
- `ExportImageAsync`: Writes an image to a file through `SaveFileDataAsync`, as raylib's default build's `ExportImage` writes it: ".png" (any uncompressed format; a format other than 8-bit grayscale, grayscale and alpha, RGB or RGBA is written as RGBA), ".qoi" (RGB or RGBA alone) or ".raw" (the pixels as they are). helix-raylib's own, answering once the file is written. The file is kept as `SaveFileDataAsync` keeps it; `TakeScreenshotAsync` writes a real file.
  - `image`: The image.
  - `fileName`: The file; its extension chooses the format.
  - `done`: Optional. Called once the file is written, at a later poll.
  - `failed`: Optional. Receives why it wasn't, such as an empty image or another extension; when omitted, it is logged.
- `ExportImageAsCodeAsync`: Writes an image as a C header through `SaveFileTextAsync`, as raylib's `ExportImageAsCode` does: its size and format as defines, and its pixels (the first level's) as an array of bytes, 20 a line. helix-raylib's own, answering once the file is written.
  - `image`: The image.
  - `fileName`: The file; its name, upper case, names the defines and the array.
  - `done`: Optional. Called once the file is written, at a later poll.
  - `failed`: Optional. Receives why it wasn't; when omitted, it is logged.

### Macros, run as the program builds

```haxe
static macro function LoadImageAsync(fileName:String, loaded:Image -> Void, ?failed:String -> Void):Void
static macro function LoadImageFromMemoryAsync(fileType:String, fileData:haxe.io.Bytes, dataSize:Int, loaded:Image -> Void, ?failed:String -> Void):Void
static macro function LoadTextureAsync(fileName:String, loaded:Texture2D -> Void, ?failed:String -> Void):Void
static macro function LoadFontAsync(fileName:String, loaded:Font -> Void, ?failed:String -> Void):Void
static macro function LoadImageAnimAsync(fileName:String, frames:Array<Int>, loaded:Image -> Void, ?failed:String -> Void):Void
static macro function LoadImageAnimFromMemoryAsync(fileType:String, fileData:haxe.io.Bytes, dataSize:Int, frames:Array<Int>, loaded:Image -> Void, ?failed:String -> Void):Void
```

- `LoadImageAsync`: Loads an image file, answering when it is decoded: helix-raylib's own, in place of raylib's `LoadImage`, as a page can't wait for a file. A PNG, JPEG, BMP or TGA file is decoded by the platform, so it gives `PIXELFORMAT_UNCOMPRESSED_R8G8B8A8` whatever its channels, where raylib's gives a grayscale file grayscale; a QOI file gives its own channels, RGB or RGBA, as raylib's. A GIF file gives its first frame, `PIXELFORMAT_UNCOMPRESSED_R8G8B8A8`, as `LoadImageAnimAsync` gives it, and nothing after it is read; one with no frames, or broken before its first frame ends, fails to load.
  - `fileName`: The file, as the program names it.
  - `loaded`: Receives the image, its pixels its own.
  - `failed`: Optional. Receives why it couldn't be loaded; when omitted, it is logged.

  The file's reader is chosen as the program builds when its name is a constant (a string, or constants joined with +), so a program naming no GIF file carries no GIF reader; a name known only as the program runs brings both, the reader chosen by its extension then. The answer comes at a later frame, never during the call.
- `LoadImageFromMemoryAsync`: Decodes an image file's bytes, answering when it is decoded: helix-raylib's own, in place of raylib's `LoadImageFromMemory`, as images are decoded asynchronously. The formats and channels are `LoadImageAsync`'s, a GIF file's when the type is ".gif" or ".GIF". The reader is chosen as the program builds when the type is a constant, as `LoadImageAsync`'s is by the name.
  - `fileType`: The file's extension: ".png", ".jpg", ".jpeg", ".bmp", ".tga", ".qoi", ".gif" or ".GIF".
  - `fileData`: The file's bytes.
  - `dataSize`: How many of them.
  - `loaded`: Receives the image.
  - `failed`: Optional. Receives why it couldn't be decoded; when omitted, it is logged.
- `LoadTextureAsync`: Loads an image file as a texture, answering when it is ready: helix-raylib's own, in place of raylib's `LoadTexture`, as a page can't wait for a file. The file is read as `LoadImageAsync` reads it, a GIF file's first frame among them, its reader chosen as the program builds as `LoadImageAsync`'s is. A file loaded again shares its first load's texture, and the image goes to the GPU when first drawn. The answer comes at a later frame, never during the call.
  - `fileName`: The file, as the program names it.
  - `loaded`: Receives the texture.
  - `failed`: Optional. Receives why it couldn't be loaded; when omitted, it is logged.
- `LoadFontAsync`: Loads a font file, answering when its glyphs are ready: helix-raylib's own, in place of raylib's `LoadFont`. A TrueType or OpenType file gives its printable ASCII at 32 pixels; a BMFont (.fnt, the text format) its characters and pages, the pages stacked onto one texture, as raylib's; an image (PNG, JPEG, BMP, TGA, QOI, or a GIF file's first frame) its glyphs on a `MAGENTA` key from the space on, as `LoadFontFromImage` reads them; each drawn with `TEXTURE_FILTER_POINT`. The GIF reader is chosen as the program builds as `LoadImageAsync`'s is.
  - `fileName`: The file, as the program names it.
  - `loaded`: Receives the font.
  - `failed`: Optional. Receives why it couldn't be loaded; when omitted, it is logged.
- `LoadImageAnimAsync`: Loads an animated image's frames, answering when they are decoded: helix-raylib's own, in place of raylib's `LoadImageAnim`. The frames are one image, `PIXELFORMAT_UNCOMPRESSED_R8G8B8A8`, the file's screen size, each frame's pixels after the last's (`GetPixelDataSize(width, height, format)` bytes each), and `frames[0]` is set to how many before `loaded` is called. Their delays and loop count aren't kept.
  - `fileName`: The file, as the program names it.
  - `frames`: Receives the frame count, in its first element.
  - `loaded`: Receives the frames.
  - `failed`: Optional. Receives why they couldn't be loaded; when omitted, it is logged.

  A GIF file's frames are composited as raylib 5.5's are: the screen starts transparent; each frame is drawn over the last, its transparent pixels not drawn; a frame disposed of to the background, or to the previous frame, has its rectangle put back as it was before it was drawn; and when the file's background index isn't 0, what the first frame doesn't cover is the global table's background color, opaque, its red and blue swapped (black with no such color). A GIF file broken after some frames gives the frames before the break, as raylib's does; one with no frames, or broken before its first frame ends, fails to load. Any other file loads as `LoadImageAsync` loads it, as one frame.

  The file's reader is chosen as the program builds when its name is a constant (a string, or constants joined with +), so a program naming no GIF file carries no GIF reader; a name known only as the program runs brings both, the reader chosen by its extension then. The answer comes at a later frame, never during the call.
- `LoadImageAnimFromMemoryAsync`: Decodes an animated image file's bytes, answering when they are decoded: helix-raylib's own, in place of raylib's `LoadImageAnimFromMemory`. The frames and their count are `LoadImageAnimAsync`'s, of a GIF file when the type is ".gif" or ".GIF"; any other type is decoded as `LoadImageFromMemoryAsync` decodes it, as one frame. The reader is chosen as the program builds when the type is a constant, as `LoadImageAnimAsync`'s is by the name.
  - `fileType`: The file's extension: ".gif", or one `LoadImageFromMemoryAsync` takes.
  - `fileData`: The file's bytes.
  - `dataSize`: How many of them.
  - `frames`: Receives the frame count, in its first element.
  - `loaded`: Receives the frames.
  - `failed`: Optional. Receives why they couldn't be decoded; when omitted, it is logged.

## Window

*class* in [`engines/raylib/src/helix/raylib/extras/Window.hx`](../../engines/raylib/src/helix/raylib/extras/Window.hx), `import helix.raylib.extras.Window;`

Provides the async versions of raylib 5.5's window, cursor, clipboard and screenshot calls (rcore), helix-raylib's own, so a page needn't wait for them: `SetWindowSizeAsync` for `SetWindowSize`, `ToggleFullscreenAsync` for `ToggleFullscreen`, `GetClipboardTextAsync` for `GetClipboardText` and the rest. raylib's own call doesn't compile and names the one here (docs/DECISIONS.md 24, 38). Imported apart: `import helix.raylib.extras.Window.*;`.

Each answers at a later poll, never during the call: `done` or `loaded` once it is done, `failed` with the reason when it is refused, logged as raylib's warning would be when `failed` is omitted.

### window: the window, cursor, clipboard and screenshot requests in place of rcore's that wait for the window

```haxe
static function ToggleFullscreenAsync(?done:() -> Void, ?failed:String -> Void):Void
static function ToggleBorderlessWindowedAsync(?done:() -> Void, ?failed:String -> Void):Void
static function SetWindowSizeAsync(width:Int, height:Int, ?done:() -> Void, ?failed:String -> Void):Void
static function SetWindowPositionAsync(x:Int, y:Int, ?done:() -> Void, ?failed:String -> Void):Void
static function SetWindowMonitorAsync(monitor:Int, ?done:() -> Void, ?failed:String -> Void):Void
static function MaximizeWindowAsync(?done:() -> Void, ?failed:String -> Void):Void
static function MinimizeWindowAsync(?done:() -> Void, ?failed:String -> Void):Void
static function RestoreWindowAsync(?done:() -> Void, ?failed:String -> Void):Void
static function SetWindowFocusedAsync(?done:() -> Void, ?failed:String -> Void):Void
static function SetWindowOpacityAsync(opacity:Float, ?done:() -> Void, ?failed:String -> Void):Void
static function SetWindowMinSizeAsync(width:Int, height:Int, ?done:() -> Void, ?failed:String -> Void):Void
static function SetWindowMaxSizeAsync(width:Int, height:Int, ?done:() -> Void, ?failed:String -> Void):Void
static function DisableCursorAsync(?done:() -> Void, ?failed:String -> Void):Void
static function EnableCursorAsync(?done:() -> Void, ?failed:String -> Void):Void
static function SetClipboardTextAsync(text:String, ?done:() -> Void, ?failed:String -> Void):Void
static function GetClipboardTextAsync(read:String -> Void, ?failed:String -> Void):Void
static function GetClipboardImageAsync(loaded:Image -> Void, ?failed:String -> Void):Void
static function TakeScreenshotAsync(fileName:String, ?done:() -> Void, ?failed:String -> Void):Void
```

- `ToggleFullscreenAsync`: Asks for fullscreen, or back to the window, the size and place it had, answering once it is granted or refused: helix-raylib's own, in place of raylib's `ToggleFullscreen`. In a page the browser grants it only soon after a key press, click or tap; without one, it waits for the player's next, or refuses. `IsWindowFullscreen` says the new state once the window has changed, not when the call returns.
  - `done`: Optional. Called once the window has changed, at a later poll.
  - `failed`: Optional. Receives why it was refused; when omitted, it is logged.
- `ToggleBorderlessWindowedAsync`: Asks for the window to fill the screen without borders, or back to the window, answering once it is granted or refused: helix-raylib's own, in place of raylib's `ToggleBorderlessWindowed`. The screen is asked for fullscreen, as a fullscreen window natively is borderless and the size of the desktop. As in raylib, `IsWindowState(FLAG_BORDERLESS_WINDOWED_MODE)` is true while it is, and `IsWindowFullscreen` false.
  - `done`: Optional. Called once the window has changed, at a later poll.
  - `failed`: Optional. Receives why it was refused; when omitted, it is logged.
- `SetWindowSizeAsync`: Asks for the window's size, answering once the window manager has resized it or refused: helix-raylib's own, in place of raylib's `SetWindowSize`. The window manager may give another size, which `GetScreenWidth` and `GetScreenHeight` say once it has. A fullscreen or maximized window keeps its size, and a page's canvas follows the page, so those are refused.
  - `width`: The width, in pixels.
  - `height`: The height, in pixels.
  - `done`: Optional. Called once the window has a size from the request, at a later poll.
  - `failed`: Optional. Receives why it wasn't resized; when omitted, it is logged.
- `SetWindowPositionAsync`: Asks for the window's place on the desktop, answering once it has moved or the move is refused: helix-raylib's own, in place of raylib's `SetWindowPosition`. Where the window can't be moved (in a page, or under Wayland), or while it is fullscreen or maximized, it is refused.
  - `x`: The left edge, in pixels.
  - `y`: The top edge, in pixels.
  - `done`: Optional. Called once the window has moved, at a later poll.
  - `failed`: Optional. Receives why it didn't move; when omitted, it is logged.
- `SetWindowMonitorAsync`: Asks for the window on another monitor, answering once it is there or the move is refused: helix-raylib's own, in place of raylib's `SetWindowMonitor`. Where the window can't be moved, a monitor other than its own is refused.
  - `monitor`: The monitor, 0 to `GetMonitorCount() - 1`.
  - `done`: Optional. Called once the window is on the monitor, at a later poll.
  - `failed`: Optional. Receives why it isn't, such as a monitor that isn't there; when omitted, it is logged.
- `MaximizeWindowAsync`: Asks for the window maximized, answering once it is or the window manager refuses: helix-raylib's own, in place of raylib's `MaximizeWindow`. A page can't maximize its window, so it is refused there.
  - `done`: Optional. Called once the window is maximized, at a later poll.
  - `failed`: Optional. Receives why it wasn't; when omitted, it is logged.
- `MinimizeWindowAsync`: Asks for the window minimized, answering once it is or the window manager refuses: helix-raylib's own, in place of raylib's `MinimizeWindow`. A page can't minimize its window, so it is refused there.
  - `done`: Optional. Called once the window is minimized, at a later poll.
  - `failed`: Optional. Receives why it wasn't; when omitted, it is logged.
- `RestoreWindowAsync`: Asks for the window back to its size from minimized or maximized, answering once it is or the window manager refuses: helix-raylib's own, in place of raylib's `RestoreWindow`.
  - `done`: Optional. Called once the window is restored, at a later poll.
  - `failed`: Optional. Receives why it wasn't; when omitted, it is logged.
- `SetWindowFocusedAsync`: Asks for the window brought to the front with the keyboard, answering once it has the keyboard or the window manager keeps it elsewhere: helix-raylib's own, in place of raylib's `SetWindowFocused`. A window manager may only flash it; in a page the canvas takes the keyboard.
  - `done`: Optional. Called once the window has the keyboard, at a later poll.
  - `failed`: Optional. Receives why it hasn't; when omitted, it is logged.
- `SetWindowOpacityAsync`: Asks for the window see-through, answering once it is or it is refused: helix-raylib's own, in place of raylib's `SetWindowOpacity`. In a page the canvas fades; a desktop without a compositor refuses it.
  - `opacity`: From 0 (clear) to 1 (opaque).
  - `done`: Optional. Called once the window has the opacity, at a later poll.
  - `failed`: Optional. Receives why it hasn't; when omitted, it is logged.
- `SetWindowMinSizeAsync`: Asks for the smallest size the player can make the window, answering once it has it or it is refused: helix-raylib's own, in place of raylib's `SetWindowMinSize`. A page's canvas follows the page, so it is refused there.
  - `width`: The width, in the screen's pixels.
  - `height`: The height.
  - `done`: Optional. Called once the window has the limit, at a later poll.
  - `failed`: Optional. Receives why it hasn't; when omitted, it is logged.
- `SetWindowMaxSizeAsync`: Asks for the largest size the player can make the window, answering once it has it or it is refused: helix-raylib's own, in place of raylib's `SetWindowMaxSize`. A page's canvas follows the page, so it is refused there.
  - `width`: The width, in the screen's pixels.
  - `height`: The height.
  - `done`: Optional. Called once the window has the limit, at a later poll.
  - `failed`: Optional. Receives why it hasn't; when omitted, it is logged.
- `DisableCursorAsync`: Locks the mouse to the window and hides the cursor, for looking around, answering once it is locked or refused: helix-raylib's own, in place of raylib's `DisableCursor`. `GetMouseDelta` keeps coming while the position goes on past the window's edges. In a page the browser locks it only soon after a click or key press, so without one it locks at the player's next, and Escape lets it go. `IsCursorHidden` is true from the call.
  - `done`: Optional. Called once the mouse is locked, at a later poll.
  - `failed`: Optional. Receives why it wasn't; when omitted, it is logged.
- `EnableCursorAsync`: Lets go of the mouse that `DisableCursorAsync` locked, and shows the cursor, answering once it is let go: helix-raylib's own, in place of raylib's `EnableCursor`.
  - `done`: Optional. Called once the mouse is let go, at a later poll.
  - `failed`: Optional. Receives why it wasn't; when omitted, it is logged.
- `SetClipboardTextAsync`: Puts text on the system's clipboard, answering once it is there or refused: helix-raylib's own, in place of raylib's `SetClipboardText`. A page writes it only while it has the keyboard, soon after a press.
  - `text`: The text.
  - `done`: Optional. Called once the text is on the clipboard, at a later poll.
  - `failed`: Optional. Receives why it isn't; when omitted, it is logged.
- `GetClipboardTextAsync`: Reads the clipboard's text, answering at a later poll: helix-raylib's own, in place of raylib's `GetClipboardText`, as a page's clipboard answers later. A page reads it only with the player's permission, which the browser may ask for.
  - `read`: Receives the text; "" when the clipboard holds none.
  - `failed`: Optional. Receives why it couldn't be read; when omitted, it is logged.
- `GetClipboardImageAsync`: Reads the clipboard's image, answering at a later poll once it is decoded: helix-raylib's own, in place of raylib's `GetClipboardImage`. A page reads it only with the player's permission.
  - `loaded`: Receives the image, `PIXELFORMAT_UNCOMPRESSED_R8G8B8A8`.
  - `failed`: Optional. Receives why there is none, or why it couldn't be read; when omitted, it is logged.
- `TakeScreenshotAsync`: Takes a screenshot of the next frame and hands it to the user as a file, as `ExportImageAsync` writes it by the name's extension (".png", ".qoi" or ".raw"), answering once it is saved or refused: helix-raylib's own, in place of raylib's `TakeScreenshot`. In a page it is downloaded under the name's file name, as raylib's web build does; natively it is written where the name says, as raylib 6.2 writes it: a relative name under the working directory, its directories kept, and an absolute one where it is. A directory that isn't there isn't made, and the screenshot isn't saved. raylib's is taken from the frame drawn last, before it is shown; this one is taken as the next frame ends, when its pixels can be read back. Its alpha is opaque, as raylib's is.
  - `fileName`: The file's name, or its path; a name with `'` is refused, as raylib's is.
  - `done`: Optional. Called once the file is written or downloaded, at a later poll.
  - `failed`: Optional. Receives why it wasn't; when omitted, it is logged.
