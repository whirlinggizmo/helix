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

- `LoadSoundAsync`: Asynchronously loads and decodes a sound file, ready to play at once. See `LoadMusicStreamAsync` for playing a file as it is read.
  - `fileName`: The file, as the program names it.
  - `loaded`: Receives the sound.
  - `failed`: Optional. Receives why it couldn't be loaded; when omitted, it is logged.

  It replaces raylib's `LoadSound`.

  `InitAudioDevice` must come first.

  A file loaded again shares its first load's decoded sound.
- `LoadMusicStreamAsync`: Asynchronously opens a music file to be played as it is read. See `LoadSoundAsync` for decoding a file whole first.
  - `fileName`: The file, as the program names it, such as "assets/theme.ogg".
  - `loaded`: Receives the music, ready to play, once enough of the file has arrived to start.
  - `failed`: Optional. Receives why it couldn't be opened; when omitted, it is logged.

  It replaces raylib's `LoadMusicStream`.

  `InitAudioDevice` must come first.

  A FLAC file is refused, as raylib 5.5's default build leaves FLAC out.

  It is never loaded whole. Natively it is read from its file, and in a page from the download as it arrives (helix-services' `Audio.stream`).
- `ExportWaveAsync`: Asynchronously writes a wave to a sound file. See `ExportWaveAsCodeAsync` for writing a C header.
  - `wave`: The wave.
  - `fileName`: The file; its extension chooses the format.
  - `done`: Optional. Called once the file is written, or once it is refused, at a later poll.
  - `failed`: Optional. Receives why it wasn't, such as a wave with no samples or another extension; when omitted, it is logged.

  It replaces raylib's `ExportWave`.

  The extension chooses the format:

  - ".wav": 8, 16 and 24-bit samples as integers, 32-bit as floats, as raylib's dr_wav writes them. - ".raw": the samples unchanged.

  A ".qoa" file is refused, though raylib writes one.

  The file is written and kept by `SaveFileDataAsync`.
- `ExportWaveAsCodeAsync`: Asynchronously writes a wave as a C header. See `ExportWaveAsync` for writing a sound file.
  - `wave`: The wave.
  - `fileName`: The file; its name, upper case, names the defines and the array.
  - `done`: Optional. Called once the file is written, or once it is refused, at a later poll.
  - `failed`: Optional. Receives why it wasn't; when omitted, it is logged.

  It replaces raylib's `ExportWaveAsCode`.

  The header holds:

  - the frame count, sample rate, sample size and channel count, as defines. - the samples, as an array of floats with 4 places for 32-bit samples, else of bytes, 20 a line.

  The file is written by `SaveFileTextAsync`.

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

- `DrawModelSkeleton`: Draws a model's skeleton in the pose it has at the call, placed as DrawModel places the model. See `DrawModelBoundingBoxPosed` for drawing its bounds.
  - `model`: The model.
  - `position`: Where the model is drawn, as DrawModel's.
  - `scale`: Its scale, as DrawModel's.
  - `color`: The lines' color.

  Each bone is a line to its parent, and each joint a small cross.

  A model never posed draws its bind pose. A model without bones draws nothing.

  It draws in 3D mode (BeginMode3D), over what is drawn before it, as DrawLine3D does.

  A model drawn as several copies, each posed apart, is posed and drawn copy by copy:

  ```haxe
  for (i in 0...copies) {
  UpdateModelAnimation(model, anim, frame + i * 10);
  var at = new Vector3(i * 2, 0, 0);
  DrawModel(model, at, 1, WHITE);
  DrawModelSkeleton(model, at, 1, YELLOW);
  DrawModelBoundingBoxPosed(model, at, 1, RED);
  }
  ```
- `DrawModelBoundingBoxPosed`: Draws a model's bounds in the pose it has at the call, placed as DrawModel places the model. See `DrawModelSkeleton` for drawing its bones.
  - `model`: The model.
  - `position`: Where the model is drawn, as DrawModel's.
  - `scale`: Its scale, as DrawModel's.
  - `color`: The box's color.

  The box is GetModelBoundingBoxPosed's (helix.raylib.extras.Models).

  It draws in 3D mode, as DrawBoundingBox does.
- `DrawFrameStats`: Draws the frame's cost at a point on the screen in FrameStatsStyle's default look at a size, as DrawFPS draws the rate. See `DrawFrameStatsEx` for choosing the stats and their look.
  - `posX`: The text's left, in pixels.
  - `posY`: The text's top, in pixels.
  - `fontSize`: The text's height, in pixels, as DrawText's; DrawFPS draws at 20.

  It draws a line each for: - the frames a second - the frame time's mean and its slowest 5% (p95) over the last half second, in milliseconds - the last frame's draw calls

  The text's color is judged against SetTargetFPS's target, or the monitor's refresh rate without one.

  It is `DrawFrameStatsEx(new Vector2(posX, posY), {fontSize: fontSize})`, every other field the style's default.
- `DrawFrameStatsEx`: Draws the frame's cost at a point on the screen in a style's stats, font, size, spacing, colors and background. See `DrawFrameStats` for drawing the default look at a size.
  - `position`: The text's top left, in pixels (its background's, padding around the text).
  - `style`: What to show and how; each field left out takes its default.

  Each stat is a line, so the text's height follows the stats shown. `MeasureFrameStats` returns the size.

  Each number is right-aligned in a slot of a fixed width, so the stats stay in place as the numbers change.

  ```haxe
  DrawFrameStatsEx(new Vector2(10, 10), {fontSize: 24, backgroundColor: Fade(BLACK, 0.5), triangles: true});
  ```
- `MeasureFrameStats`: Returns the size DrawFrameStatsEx draws a style's stats in, for placing them (at a corner, say).
  - `style`: What to show and how.
  - returns: The width and height, in pixels.

  The size includes the padding.

  It is sized for the widest values, so it is the same from frame to frame.

## Device

*class* in [`engines/raylib/src/helix/raylib/extras/Device.hx`](../../engines/raylib/src/helix/raylib/extras/Device.hx), `import helix.raylib.extras.Device;`

Provides what a game needs from the device and the page that raylib 5.5 has no call for, helix-raylib's own: the safe area around a notch, the options the program was started with, what the device is, whether the window can close or go fullscreen, the screen's orientation, and the device's tilt. Imported apart: `import helix.raylib.extras.Device.*;`.

Each is answered by helix-platform, on every target. Where a target has no such thing the answer says so (no tilt natively, the whole window as the safe area on a desktop) rather than the call failing to compile, so a game needs no `#if js` for any of them. Each `...Async` call answers at a later poll, never during the call.

```haxe
static inline var ORIENTATION_ANY:Int
static inline var ORIENTATION_LANDSCAPE:Int
static inline var ORIENTATION_PORTRAIT:Int
```

- `ORIENTATION_ANY`: The screen held as the device is held, or released.
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

- `GetWindowSafeArea`: Returns the part of the window no notch, rounded corner or system bar covers, in the screen's coordinates as `GetScreenWidth` measures them.
  - returns: The safe area.

  A HUD and buttons go inside it.

  On a desktop it is the whole window. In a page it is the whole window unless the viewport meta tag has `viewport-fit=cover`.
- `GetRunOption`: Returns an option the program was started with, or null when it isn't set.
  - `name`: The option's name.
  - returns: Its value, or null when it isn't set.

  In a page it is the URL's query parameter of that name (`?level=3`).

  Natively it is the command line's `--level=3`, or else the environment variable `HELIX_` and the name in capitals (`HELIX_LEVEL=3`).
- `IsPlatformWeb`: Returns whether the program runs in a browser page rather than natively. See `GetPlatformOS` for naming the operating system.
  - returns: True in a page.
- `GetPlatformOS`: Returns the operating system's name in lowercase, or "" where the platform names none. See `IsPlatformWeb` for whether the program runs in a page.
  - returns: The system's name.

  The names are "windows", "macos", "linux", "android", "ios" and "chromeos".
- `IsTouchScreenAvailable`: Returns whether the device has a touch screen. See `IsFinePointerAvailable` for whether there is a mouse, a trackpad or a pen.
  - returns: True with a touch screen.

  Always false natively.

  A laptop may have both a touch screen and a mouse. Touch controls also belong on the first touch, not on this alone.
- `IsFinePointerAvailable`: Returns whether the device has a fine pointer, such as a mouse, a trackpad or a pen. See `IsTouchScreenAvailable` for whether there is a touch screen.
  - returns: True with a fine pointer.

  False on a phone or a tablet alone.
- `IsWindowCloseable`: Returns whether the program can close its own window.
  - returns: True where `CloseWindow` ends the program's window.

  False in a page, which can't close its tab. A game hides its Quit there.
- `IsFullscreenAvailable`: Returns whether the window can go fullscreen. See `ToggleFullscreenAsync` for asking for it.
  - returns: True where `ToggleFullscreenAsync` can be granted.

  False in a page that isn't allowed to, such as an iframe without permission or iOS Safari on an iPhone.
- `SetScreenOrientationAsync`: Asynchronously asks for the screen to be held one way up, or released. See `GetScreenOrientation` for reading how it is held.
  - `orientation`: `ORIENTATION_LANDSCAPE`, `ORIENTATION_PORTRAIT`, or `ORIENTATION_ANY` to release a lock.
  - `done`: Optional. Called once the screen is held, or once it is refused, at a later poll.
  - `failed`: Optional. Receives why it was refused; when omitted, it is logged.

  Natively and on iOS it is refused.

  Only some browsers lock it. Chrome on Android locks it only in fullscreen, so a program asks in `ToggleFullscreenAsync`'s `done`.

  Where the lock is refused, a game shows "turn your device" when the shape is wrong (`GetScreenWidth() < GetScreenHeight()`).

  A value that isn't an `ORIENTATION_` value is refused.
- `GetScreenOrientation`: Returns how the screen is held for the program, as `SetScreenOrientationAsync` asked, or `ORIENTATION_ANY` when it isn't held.
  - returns: `ORIENTATION_ANY`, `ORIENTATION_LANDSCAPE` or `ORIENTATION_PORTRAIT`.

  A page loses the lock as it leaves fullscreen.
- `EnableTiltAsync`: Asynchronously asks for the device's tilt readings, for a game steered by tilting a phone. See `GetTilt` for reading them and `DisableTilt` for stopping them.
  - `done`: Optional. Called once readings arrive, at a later poll.
  - `failed`: Optional. Receives why there will be none: refused, the page isn't HTTPS, or no sensor; when omitted, it is logged.

  Natively it is refused.

  A page may need permission, which the browser asks for at the next tap. A game asks before the tap that starts play.
- `DisableTilt`: Stops the tilt's readings. See `EnableTiltAsync` for asking for them.
  A permission granted stays granted.
- `GetTilt`: Returns the tilt from level, turned with the screen, each axis -1 to 1. See `CalibrateTilt` for setting what reads as level.
  - returns: The tilt.

  x is across the screen and y is down it.

  A full tilt of 1 is `SetTiltRange`'s angle.

  It is 0 until readings arrive and the device has been held steady once. Level is taken then.
- `SetTiltRange`: Sets the angle, in degrees, that reads as a full tilt of 1. It defaults to 30.
  - `degrees`: The angle.
- `CalibrateTilt`: Takes how the device is held now as level. See `GetTilt` for reading the tilt from it.

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

- `LoadFileDataAsync`: Asynchronously reads a file's bytes, in place of raylib's `LoadFileData`. See `LoadFileTextAsync` for reading a text file.
  - `fileName`: The file.
  - `loaded`: Receives its bytes.
  - `failed`: Optional. Receives why it couldn't be read; when omitted, it is logged.

  It reads the first of these that has the file: - the program's `SetLoadFileDataCallback` - what `SaveFileData` wrote - the program's files
- `LoadFileTextAsync`: Asynchronously reads a text file, in place of raylib's `LoadFileText`. See `LoadFileDataAsync` for reading a file's bytes.
  - `fileName`: The file.
  - `loaded`: Receives its text.
  - `failed`: Optional. Receives why it couldn't be read; when omitted, it is logged.

  It reads the first of these that has the file: - the program's `SetLoadFileTextCallback` - what `SaveFileText` wrote - the program's files

  The text ends at the file's first NUL byte, as raylib's C string does.

  A byte that isn't UTF-8 is read as U+FFFD. A file is never refused for what it holds.

  In a page, reading a file that hasn't been saved yet asks the server for it and logs a 404 in the browser's console before `failed` answers. A program reading a save on its first run sees one.
- `SaveFileDataAsync`: Asynchronously writes a file's bytes, in place of raylib's `SaveFileData`. See `SaveFileTextAsync` for writing text.
  - `fileName`: The file.
  - `data`: The bytes.
  - `dataSize`: How many of them.
  - `done`: Optional. Called once the file is written, or once it is refused, at a later poll.
  - `failed`: Optional. Receives why it wasn't; when omitted, it is logged.

  They are written through the program's `SetSaveFileDataCallback` when it has one. Otherwise they are kept across runs, as `SaveFileTextAsync`'s are.

  `LoadFileDataAsync` reads them back.
- `SaveFileTextAsync`: Asynchronously writes a text file, in place of raylib's `SaveFileText`. See `SaveFileDataAsync` for writing bytes.
  - `fileName`: The file.
  - `text`: Its text.
  - `done`: Optional. Called once the file is written, or once it is refused, at a later poll.
  - `failed`: Optional. Receives why it wasn't; when omitted, it is logged.

  It is written through the program's `SetSaveFileTextCallback` when it has one, during the call, and answered by what that returned.

  Otherwise it is kept across runs, natively and in a page, and answered once the write has finished.

  `LoadFileTextAsync` reads it back.
- `FileExistsAsync`: Asynchronously answers whether a file exists, in place of raylib's `FileExists`. See `DirectoryExistsAsync` for a directory.
  - `fileName`: The file.
  - `answer`: Receives true when it exists.

  The answer comes at a later frame, never during the call.

  A file exists when `SaveFileText` or `SaveFileData` wrote it, or when it is one of the program's.

  Finding one of the program's files reads it, so a load of it after answers at once.
- `DirectoryExistsAsync`: Asynchronously answers whether a directory exists, in place of raylib's `DirectoryExists`. See `FileExistsAsync` for a file.
  - `dirPath`: The directory.
  - `answer`: Receives true when it exists.

  The answer comes at a later frame, never during the call.

  Natively it is a directory of the program's files.

  `helix-raylib-dropped` and the directories under it hold the dropped files.

  A page's own files are on its server, which can't be listed. There only its root ("", "." or "./") and the dropped files' directories exist.
- `IsPathFileAsync`: Asynchronously answers whether a path is a file, not a directory, in place of raylib's `IsPathFile`. See `DirectoryExistsAsync` for a directory.
  - `path`: The path.
  - `answer`: Receives true for a file; false for a directory or nothing there.

  The answer comes at a later frame, never during the call.

  These are files, as `FileExistsAsync` finds them: - a file `SaveFileText` or `SaveFileData` wrote - a dropped file - a file the program has
- `GetFileLengthAsync`: Asynchronously answers a file's size, in place of raylib's `GetFileLength`.
  - `fileName`: The file.
  - `answer`: Receives its size in bytes; 0 when there is no file, as raylib's.

  The answer comes at a later frame, never during the call.

  The size is: - for a file `SaveFileText` or `SaveFileData` wrote, or the program's `SetLoadFileDataCallback` gives, its bytes' size - for a dropped file, its own - for a file of the program's, natively its size on disk

  In a page, a file of the program's is read from the server to be measured, so a load of it after answers at once.
- `GetFileModTimeAsync`: Asynchronously answers when a file was last written, in place of raylib's `GetFileModTime`.
  - `fileName`: The file.
  - `answer`: Receives the time, in whole seconds since the Unix epoch; 0 when there is no file or no time, as raylib's.

  The answer comes at a later frame, never during the call.

  The time is: - for a file of the program's, natively its time on disk - for a file `SaveFileText` or `SaveFileData` wrote, when it was saved - 0 for a page's own file, a dropped file and one the program's load callback gives, which have no time kept
- `LoadDirectoryFilesAsync`: Asynchronously lists a directory's files and subdirectories, in place of raylib's `LoadDirectoryFiles`. See `LoadDirectoryFilesExAsync` for a filter by extension and the subdirectories' files.
  - `dirPath`: The directory.
  - `loaded`: Receives the list, its `capacity` its `count`; empty, with a warning, when the directory can't be listed, as raylib's.

  The answer comes at a later frame, never during the call.

  Each path is the directory's followed by `/` and the name (`dirPath` "levels" gives "levels/1.json"). A subdirectory's has no slash at its end.

  The paths are sorted by name.

  The directories are `DirectoryExistsAsync`'s. A page lists only the dropped files.

  Files `SaveFileText` and `SaveFileData` wrote aren't listed.
- `LoadDirectoryFilesExAsync`: Asynchronously lists a directory's files with some extensions, and with `scanSubdirs` its subdirectories' too, in place of raylib's `LoadDirectoryFilesEx`. See `LoadDirectoryFilesAsync` for listing one directory's every file and subdirectory.
  - `basePath`: The directory.
  - `filter`: The extensions kept, such as ".png;.jpg;DIR", or null for every file.
  - `scanSubdirs`: Whether the subdirectories' files are listed too.
  - `loaded`: Receives the list, its `capacity` 8192; a directory that can't be listed adds nothing, with a warning.

  The answer comes at a later frame, never during the call.

  The paths are `LoadDirectoryFilesAsync`'s, a subdirectory's files right after it.

  A filter is `IsFileExtension`'s list. "DIR" in it keeps the subdirectories.

  A null filter keeps every file, and without `scanSubdirs` every subdirectory too.

  At most 8192 paths are listed (`MAX_FILEPATH_CAPACITY`), with a warning when there are more.
- `ExportDataAsCodeAsync`: Asynchronously writes bytes as a C header, the text raylib's `ExportDataAsCode` writes. See `SaveFileDataAsync` for the bytes as they are.
  - `data`: The bytes.
  - `dataSize`: How many of them.
  - `fileName`: The file; its name, upper case, names the define and the array, with `_` for `.`, `-`, `?`, `!` and `+`.
  - `done`: Optional. Called once the file is written, or once it is refused, at a later poll.
  - `failed`: Optional. Receives why it wasn't; when omitted, it is logged.

  The header is raylib's, byte for byte: - the bytes' count, as a define - the bytes, as an array in hexadecimal, 20 a line

  It is written through `SaveFileTextAsync`.
- `LoadAutomationEventListAsync`: Asynchronously loads an automation events list from a text file, in place of raylib's `LoadAutomationEventList` given a file. See `ExportAutomationEventListAsync` for writing one.
  - `fileName`: The file, as `ExportAutomationEventList` writes it.
  - `loaded`: Receives the list, its capacity 16384.
  - `failed`: Optional. Receives why it couldn't be read; when omitted, it is logged.

  The file is read as `LoadFileTextAsync` reads it.

  It reads these lines, as raylib's does: - a line starting `c`, the count - a line starting `e`, an event: its frame, type and four parameters

  Other lines are skipped. So is a last line with no newline at its end, as raylib's reading skips it.

  A count that isn't the number of events read warns, and the count becomes the events read.
- `ExportAutomationEventListAsync`: Asynchronously writes a list's events as text, the text raylib's `ExportAutomationEventList` writes. See `LoadAutomationEventListAsync` for reading it back.
  - `list`: The list.
  - `fileName`: The file.
  - `done`: Optional. Called once the file is written, or once it is refused, at a later poll.
  - `failed`: Optional. Receives why it wasn't; when omitted, it is logged.

  The text is raylib's, byte for byte: - a header of comments - `c` and the count - a line for each event: `e`, its frame, type and four parameters, and its type's name

  It is written through `SaveFileTextAsync`.

## Gui

*class* in [`engines/raylib/src/helix/raylib/extras/Gui.hx`](../../engines/raylib/src/helix/raylib/extras/Gui.hx), `import helix.raylib.extras.Gui;`

Provides the async versions of raygui's style and icon loads, helix-raylib's own, as a page can't wait for a file: `GuiLoadStyleAsync` for `GuiLoadStyle` and `GuiLoadIconsAsync` for `GuiLoadIcons`. raygui's own call doesn't compile and names the one here (docs/DECISIONS.md 38). Imported apart: `import helix.raylib.extras.Gui.*;`.

Each answers at a later poll, never during the call: `done` or `loaded` once it is done, `failed` with the reason when it is refused, logged as raylib's warning would be when `failed` is omitted.

### gui: the style and icon loads in place of raygui's that wait for a file

```haxe
static function GuiLoadStyleAsync(fileName:String, ?done:() -> Void, ?failed:String -> Void):Void
static function GuiLoadIconsAsync(fileName:String, loadIconsName:Bool, loaded:Array<String> -> Void, ?failed:String -> Void):Void
```

- `GuiLoadStyleAsync`: Asynchronously loads a style file (.rgs) over the current style, in place of raygui's `GuiLoadStyle`.
  - `fileName`: The style file.
  - `done`: Optional. Called once the style is loaded, at a later poll.
  - `failed`: Optional. Receives why it couldn't be read; when omitted, it is logged.

  The default style is loaded first if it isn't yet.

  A text file's first line starts with '#'. It reads: - each `p <control> <property> 0x<value>` line, which sets that property. - the `f <size> <charmap> <font>` line, which loads the font at its size with the charmap file's characters. Both files are beside the style file.

  A font that can't be loaded leaves raylib's default font at size 10.

  A text file's last line is read only when a line break ends it, as in raygui.

  A binary file sets its properties, and its font when it holds one.
- `GuiLoadIconsAsync`: Asynchronously loads an icon file (.rgi) over raygui's icons, in place of raygui's `GuiLoadIcons`.
  - `fileName`: The icon file.
  - `loadIconsName`: Whether the icons' names are read.
  - `loaded`: Receives the icons' names, in order, or null when they weren't read or the file isn't an icon file.
  - `failed`: Optional. Receives why it couldn't be read; when omitted, it is logged.

  The file's icons replace raygui's from the first, as raygui reads them.

  A file that isn't an icon file changes nothing.

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

- `GuiSkinFromTexture`: Returns a skin cut from a texture by one patch for each state. See `GuiSkinFromSheet` for cutting the patches from a sheet of equal cells.
  - `texture`: The texture the patches are cut from.
  - `normal`: The patch drawn in `STATE_NORMAL`.
  - `focused`: Optional. The patch drawn in `STATE_FOCUSED`; `normal` when omitted.
  - `pressed`: Optional. The patch drawn in `STATE_PRESSED`; `focused` when omitted, or `normal` without it.
  - `disabled`: Optional. The patch drawn in `STATE_DISABLED`; `normal` when omitted.
  - `tint`: Optional. The color the patches are multiplied by; `WHITE` when omitted.
  - returns: The skin.
- `GuiSkinFromSheet`: Returns a skin cut from a sheet of a control's states, one cell of one size each. See `GuiSkinFromTexture` for cutting a patch per state from one texture.
  - `texture`: The sheet.
  - `cellWidth`: A cell's width, in texels.
  - `cellHeight`: A cell's height, in texels.
  - `left`: The left border's width, in texels, kept unstretched.
  - `top`: The top border's height.
  - `right`: The right border's width.
  - `bottom`: The bottom border's height.
  - returns: The skin.

  The cells are in raygui's order of states: normal, focused, pressed, disabled.

  They run from the top down, or from the left across when the sheet is less than two cells high.

  A sheet of fewer than four cells leaves the rest to their fallbacks (`GuiSkin`).

  Each cell is cut as a nine-patch by the same borders.
- `GuiSetSkin`: Sets the skin a part of a control is drawn with, in place of its style's border and base colors. See `GuiGetSkin` for reading the skin set, and `GuiClearSkins` for removing every one.
  - `control`: The control: `DEFAULT`, `BUTTON`, `SLIDER` and the rest of raygui's.
  - `part`: `GUI_SKIN_BASE`, `GUI_SKIN_FILL`, `GUI_SKIN_HANDLE` or `GUI_SKIN_ITEM`.
  - `skin`: The skin, or null to draw the part flat in its style's colors again.

  A skin set on `DEFAULT` is set on every control too, as `GuiSetStyle` sets `DEFAULT`'s base properties. Set `DEFAULT`'s first and each control's own after.

  The skin is read as each control draws. A skin set before one call and put back after it changes that call's control alone.

  `GuiPanel`, `GuiWindowBox` and `GuiScrollPanel` draw their body with `DEFAULT`'s own `GUI_SKIN_BASE`.
- `GuiGetSkin`: Returns the skin a part of a control is drawn with, to put back after a change. See `GuiSetSkin` for setting it.
  - `control`: The control.
  - `part`: The part.
  - returns: The skin, or null when the part is drawn flat.
- `GuiClearSkins`: Removes every skin, so every control is drawn flat in its style's colors again. See `GuiSetSkin` with null for removing one.
  Loading a style leaves the skins unchanged.

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

Beside it, `LoadPbrShader` draws a glTF's materials as authored, metallic-roughness under the same lights, where the lit shader shines every material alike. A model posed by `UpdateModelAnimation` under either is skinned on the GPU. A program's own shader lights as the lit one does by including `<helix/raylib/shaders/lights.glsl>`: rlights' uniforms and `vec4 helixLight(vec4 texelColor, vec4 tint, vec3 fragPosition, vec3 fragNormal)`, called as `helixLight(texture(texture0, fragTexCoord), colDiffuse*fragColor, fragPosition, fragNormal)`; and as the PBR one does by including `<helix/raylib/shaders/pbr.glsl>`, `vec4 helixPbr(vec4 baseColor, float metallic, float roughness, float occlusion, vec3 emissive, vec3 fragPosition, vec3 normal)`. A program that calls none of this links none of it.

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
static function LoadPbrShader():Shader
static function CreateLight(type:Int, position:Vector3, target:Vector3, color:Color, shader:Shader):Light
static function UpdateLightValues(shader:Shader, light:Light):Void
```

- `LoadLightingShader`: Returns raylib's examples' lighting shader (`lighting.vs` and `lighting.fs`), built in. It shines every material alike, one Phong highlight whatever the material says. See `LoadPbrShader` for drawing a glTF's materials as authored.
  - returns: The shader, the program's until `UnloadShader`.

  Set up as raylib's lighting example does: `locs[SHADER_LOC_VECTOR_VIEW]` is `viewPos`, set to the camera's position each frame; `GetShaderLocation(shader, "ambient")` finds the ambient color; lights come from `CreateLight`. A model posed by `UpdateModelAnimation` under it is skinned on the GPU. A program's own shader lights the same way by including `<helix/raylib/shaders/lights.glsl>`.

  ```haxe
  var shader = LoadLightingShader();
  SetShaderValue(shader, GetShaderLocation(shader, "ambient"), [0.1, 0.1, 0.1, 1.0], SHADER_UNIFORM_VEC4);
  model.materials[0].shader = shader;
  var light = CreateLight(LIGHT_POINT, new Vector3(-2, 1, -2), Vector3Zero(), YELLOW, shader);
  ```
- `LoadPbrShader`: Returns helix-raylib's PBR shader, built in: a glTF's materials drawn as authored, metallic-roughness under the same lights as `LoadLightingShader`, which shines every material alike.
  - returns: The shader, the program's until `UnloadShader`.

  Set up as that one: `locs[SHADER_LOC_VECTOR_VIEW]` is `viewPos`, set to the camera's position each frame; `GetShaderLocation(shader, "ambient")` finds the ambient color; lights come from `CreateLight`, a light's color what a white surface facing it shows. A model posed by `UpdateModelAnimation` under it is skinned on the GPU. A material marked `unlit` (glTF's `KHR_materials_unlit`) draws its base color and no light.

  What each draw reads from the material: its maps, bound at `locs[SHADER_LOC_MAP_ALBEDO]`, `METALNESS`, `ROUGHNESS`, `NORMAL`, `OCCLUSION` and `EMISSION` (the samplers `albedoMap`, `metalnessMap`, `roughnessMap`, `normalMap`, `occlusionMap` and `emissiveMap`, each set to its map's unit), a missing map reading white and a missing normal map a flat normal; and its values, `maps[MATERIAL_MAP_ALBEDO].color` times the tint as `colDiffuse`, `maps[MATERIAL_MAP_METALNESS].value` as `metallicValue`, `maps[MATERIAL_MAP_ROUGHNESS].value` as `roughnessValue` and `maps[MATERIAL_MAP_EMISSION].color` as `emissiveColor`. Colors are taken as linear, as a glTF's factors are, and an image's texels decoded from sRGB. A material from `LoadMaterialDefault` is a smooth non-metal, both values 0, until set. A mesh without tangents under a normal map gets them with its first draw (`GenMeshTangents`). A program's own shader draws the same way by including `<helix/raylib/shaders/pbr.glsl>`.

  ```haxe
  var pbr = LoadPbrShader();
  SetShaderValue(pbr, GetShaderLocation(pbr, "ambient"), [0.2, 0.2, 0.2, 1.0], SHADER_UNIFORM_VEC4);
  CreateLight(LIGHT_DIRECTIONAL, new Vector3(2, 4, 2), Vector3Zero(), WHITE, pbr);
  for (m in model.materials)
  m.shader = pbr;
  // each frame
  SetShaderValue(pbr, pbr.locs[SHADER_LOC_VECTOR_VIEW], [camera.position.x, camera.position.y, camera.position.z],
  SHADER_UNIFORM_VEC3);
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

- `LoadModelAnimationsAsync`: Asynchronously loads a glTF or GLB file's animations, in place of raylib's `LoadModelAnimations`.
  - `fileName`: The file, as the program names it.
  - `loaded`: Receives the animations, as many as the file has; their count is its length.
  - `failed`: Optional. Receives why they couldn't be loaded; when omitted, it is logged.

  A file without skins gives none. Only the file's first skin is read.

  IQM and M3D animations are refused, as is any file but glTF and GLB.

  Each animation is sampled 60 times a second, as raylib 6.2 samples it, with (int)(duration * 60) + 1 frames.

  Each frame's pose is its bones' transforms in the model.
- `LoadMaterialsAsync`: Asynchronously loads an .mtl file's materials with the textures they name, in place of raylib's `LoadMaterials`. See `LoadModelAsync` for loading an OBJ file with the materials its `mtllib` names.
  - `fileName`: The file, as the program names it: an .mtl file.
  - `loaded`: Receives the materials, in the file's order; their count is its length.
  - `failed`: Optional. Receives why they couldn't be loaded (the file isn't an .mtl file, can't be found or can't be read); when omitted, it is logged.

  The program holds each material until `UnloadMaterial`.

  Each starts as raylib's default material, and reads these fields as raylib's `ProcessMaterialsOBJ` does:

  - `map_Kd`, the diffuse texture, or with none `Kd`, the diffuse color (alpha 255). - `map_Ks` and `Ks`, the specular texture and color. - `bump` or `map_bump`, the normal map's texture. The normal map's color is white and its value is `Ns`, the specular exponent. - `Ke`, the emission color. - `disp`, the height map's texture.

  A field a material doesn't give defaults to tinyobj_loader_c's default, as raylib has it. Each color is black and the specular exponent is 1.

  A texture's path is resolved against the file's directory. A texture that can't be read is none (id 0) and is logged.

  A file that breaks the format fails.
- `ExportMeshAsync`: Asynchronously writes a mesh as an OBJ file through `SaveFileTextAsync`, in place of raylib's `ExportMesh`. See `ExportMeshAsCodeAsync` for writing a C header.
  - `mesh`: The mesh, with positions, texture coordinates and normals.
  - `fileName`: The file; only ".obj" is written.
  - `done`: Optional. Called once the file is written, or once it is refused, at a later poll.
  - `failed`: Optional. Receives why it wasn't, such as another extension; when omitted, it is logged.

  Positions and texture coordinates are written to 6 places, normals to 4, and each face as a triangle, as raylib's `ExportMesh` writes them.
- `ExportMeshAsCodeAsync`: Asynchronously writes a mesh as a C header through `SaveFileTextAsync`, in place of raylib's `ExportMeshAsCode`. See `ExportMeshAsync` for writing an OBJ file.
  - `mesh`: The mesh.
  - `fileName`: The file; its name, upper case, names the defines and the arrays.
  - `done`: Optional. Called once the file is written, or once it is refused, at a later poll.
  - `failed`: Optional. Receives why it wasn't; when omitted, it is logged.

  Its counts are written as defines, and each array it has as 20 values a line, floats to 3 places, as raylib's `ExportMeshAsCode` writes them.

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

## Sprites

*class* in [`engines/raylib/src/helix/raylib/extras/Sprites.hx`](../../engines/raylib/src/helix/raylib/extras/Sprites.hx), `import helix.raylib.extras.Sprites;`

Provides helix-raylib's instanced texture draw, `DrawTextureInstanced`: many copies of one part of a texture, each placed by a matrix, in one call, as three.js's InstancedMesh, Godot's MultiMesh and Unity's instancing draw many of one thing (docs/DECISIONS.md 47). Imported apart: `import helix.raylib.extras.Sprites.*;`.

```haxe
var copies = [for (i in 0...100) MatrixMultiply(MatrixRotateZ(i * 0.1), MatrixTranslate(i * 8, 100, 0))];
DrawTextureInstanced(texture, new Rectangle(0, 0, 32, 32), copies, WHITE);
```

### sprites: many copies of one part of a texture, each placed by a matrix, in one call

```haxe
static function DrawTextureInstanced(texture:Texture2D, source:Rectangle, transforms:Array<Matrix>, tint:Color):Void
```

- `DrawTextureInstanced`: Draws one part of a texture many times in one call, each copy placed by its own matrix. See `DrawTexturePro` for drawing a single copy.
  - `texture`: The texture.
  - `source`: The part of it, in pixels.
  - `transforms`: Each copy's matrix.
  - `tint`: The tint, every copy's.

  Each copy is what `DrawTexturePro` draws, in the batch's order, so the copies join the frame's sprite run and cost what the same draws would.

  A copy is the part, `source.width` by `source.height` pixels with its top left at the origin, taken through its matrix as `Vector2Transform` applies one. The fields read are `m0`, `m4` and `m12` across, and `m1`, `m5` and `m13` down.

  `MatrixTranslate` places a copy, `MatrixRotateZ` turns it about its top left and `MatrixScale` sizes it. Their products do all three.

  A negative `source.width` or `source.height` flips the part.

  Nothing is drawn when the texture's id, width or height is 0.

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

- `LoadFontExAsync`: Asynchronously loads a TrueType or OpenType font file at a size. See `LoadFontFromMemoryAsync` for making a font from bytes already loaded.
  - `fileName`: The file, as the program names it.
  - `fontSize`: The glyphs' size: the height of a line, in pixels.
  - `codepoints`: The characters, or null for those from the space on.
  - `codepointCount`: How many characters; 0 for 95, the printable ASCII when `codepoints` is null.
  - `loaded`: Receives the font once its glyphs are ready.
  - `failed`: Optional. Receives why it couldn't be loaded; when omitted, it is logged.

  It replaces raylib's `LoadFontEx`.

  The font holds only the characters the file has. `glyphCount` may be fewer than asked for, and a character it lacks draws as its '?'.

  Each Unicode space the file has (U+0020, U+00A0, U+2000 to U+200A, U+3000 and the others) is a blank glyph as wide as its advance.
- `LoadFontFromMemoryAsync`: Asynchronously makes a font from a TrueType or OpenType file's bytes. See `LoadFontExAsync` for loading a file by its name.
  - `fileType`: The file's extension, ".ttf" or ".otf". Any other is refused.
  - `fileData`: The file's bytes.
  - `dataSize`: How many of them.
  - `fontSize`: The glyphs' size: the height of a line, in pixels.
  - `codepoints`: The characters, or null for those from the space on.
  - `codepointCount`: How many characters; 0 for 95.
  - `loaded`: Receives the font once its glyphs are ready.
  - `failed`: Optional. Receives why it couldn't be made; when omitted, it is logged.

  It replaces raylib's `LoadFontFromMemory`. The glyphs are rasterized off the main thread.

  The font holds only the characters the file has, as `LoadFontExAsync`'s does. With none of them, it is the default font.
- `LoadFontDataAsync`: Asynchronously rasterizes a TrueType or OpenType font's glyphs, each with its own image. See `LoadFontFromMemoryAsync` for a font ready to draw.
  - `fileData`: The font file's bytes.
  - `dataSize`: How many of them.
  - `fontSize`: The glyphs' size: the height of a line, in pixels.
  - `codepoints`: The characters, or null for those from the space on.
  - `codepointCount`: How many characters; 0 for 95.
  - `type`: `FONT_DEFAULT` for antialiased glyphs, `FONT_BITMAP` for glyphs with no gray, `FONT_SDF` for signed distances. Any other is taken as `FONT_DEFAULT`.
  - `loaded`: Receives the glyphs once they are ready.
  - `failed`: Optional. Receives why the font couldn't be read; when omitted, it is logged.

  It replaces raylib's `LoadFontData`.

  Each glyph's image is 8-bit grayscale, for `GenImageFontAtlas`.

  Under `FONT_SDF` the images hold signed distances, with 4 texels of padding, 128 on the outline and 64 for each texel.
- `ExportFontAsCodeAsync`: Asynchronously writes a font as a C header, the text raylib 5.5's `ExportFontAsCode` writes.
  - `font`: The font.
  - `fileName`: The file.
  - `done`: Optional. Called once the file is written, or once it is refused, at a later poll.
  - `failed`: Optional. Receives why it wasn't; when omitted, it is logged.

  It replaces raylib's `ExportFontAsCode`. The file is written through `SaveFileTextAsync`.

  The header holds the texture's pixels, each glyph's rectangle, character, offsets and advance, and a function loading the font. The file's name, in Pascal case, names them.

  The pixels are in the texture's format (gray and alpha for the default font and a TrueType font's), compressed as `CompressData` compresses them, 20 bytes a line.

  The pixels are those the font's texture was made from, or the texture's own while it hasn't been drawn.

  A texture made otherwise and already on the GPU (a render texture's) is written as an empty image, as raylib writes a texture it can't read back.

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

- `LoadImageRawAsync`: Asynchronously loads an image's raw pixels from a file, in place of raylib's `LoadImageRaw`. See `LoadImageAsync` for an encoded image file.
  - `fileName`: The file.
  - `width`: The width, in pixels.
  - `height`: The height, in pixels.
  - `format`: The pixel format (`PIXELFORMAT_*`).
  - `headerSize`: The bytes before the pixels, skipped when the file holds them and the pixels.
  - `loaded`: Receives the image.
  - `failed`: Optional. Receives why it couldn't be loaded; when omitted, it is logged.

  A file with fewer bytes than the pixels need fails.

  A file too small for the header and the pixels is read from its first byte.
- `LoadImageFromTextureAsync`: Asynchronously reads a texture's pixels into an RGBA image, in place of raylib's `LoadImageFromTexture`. See `LoadImageFromScreenAsync` for the screen.
  - `texture`: The texture.
  - `loaded`: Receives the image, `PIXELFORMAT_UNCOMPRESSED_R8G8B8A8`.
  - `failed`: Optional. Receives why it couldn't be read; when omitted, it is logged.

  The image is RGBA, whatever the texture's format.

  A texture on the GPU (one drawn, or a render texture) is read as the frames drawn so far left it.

  A render texture's rows come bottom first, as raylib's do, so its image is upside down.

  A texture updated this frame (`UpdateTexture`) is read once the frame is drawn, so the update shows.

  A texture not drawn yet is read from memory. raylib's default texture is its white pixel.

  A cubemap is read from the image it was made from while that is kept in memory. Its faces on the GPU aren't read.
- `LoadImageFromScreenAsync`: Asynchronously reads the screen into an RGBA image as the next frame ends, in place of raylib's `LoadImageFromScreen`. See `TakeScreenshotAsync` for saving the screen to a file.
  - `loaded`: Receives the image, `PIXELFORMAT_UNCOMPRESSED_R8G8B8A8`.
  - `failed`: Optional. Receives why it couldn't be read; when omitted, it is logged.

  The image is the framebuffer's size, not the screen's, rows top first, its alpha opaque.

  A call before `InitWindow` fails.
- `ExportImageAsync`: Asynchronously writes an image to a PNG, QOI or raw file through `SaveFileDataAsync`, in place of raylib's `ExportImage`. See `ExportImageAsCodeAsync` for writing a C header.
  - `image`: The image.
  - `fileName`: The file; its extension chooses the format.
  - `done`: Optional. Called once the file is written, or once it is refused, at a later poll.
  - `failed`: Optional. Receives why it wasn't, such as an empty image or another extension; when omitted, it is logged.

  The file's extension chooses the format:

  - ".png": any uncompressed format. A format other than 8-bit grayscale, grayscale and alpha, RGB or RGBA is written as RGBA. - ".qoi": RGB or RGBA alone. - ".raw": the pixels as they are.

  The file is kept as `SaveFileDataAsync` keeps it. `TakeScreenshotAsync` writes a real file.
- `ExportImageAsCodeAsync`: Asynchronously writes an image as a C header through `SaveFileTextAsync`, in place of raylib's `ExportImageAsCode`. See `ExportImageAsync` for writing a PNG, QOI or raw file.
  - `image`: The image.
  - `fileName`: The file; its name, upper case, names the defines and the array.
  - `done`: Optional. Called once the file is written, or once it is refused, at a later poll.
  - `failed`: Optional. Receives why it wasn't; when omitted, it is logged.

  The header holds:

  - the image's size and format, as defines. - its first level's pixels, as an array of bytes, 20 a line.

### Macros, run as the program builds

```haxe
static macro function LoadImageAsync(fileName:String, loaded:Image -> Void, ?failed:String -> Void):Void
static macro function LoadImageFromMemoryAsync(fileType:String, fileData:haxe.io.Bytes, dataSize:Int, loaded:Image -> Void, ?failed:String -> Void):Void
static macro function LoadTextureAsync(fileName:String, loaded:Texture2D -> Void, ?failed:String -> Void):Void
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

- `ToggleFullscreenAsync`: Asynchronously asks for fullscreen, or for the window back at the size and place it had. See `ToggleBorderlessWindowedAsync` for the borderless window.
  - `done`: Optional. Called once the window has changed, or once it is refused, at a later poll.
  - `failed`: Optional. Receives why it was refused; when omitted, it is logged.

  It replaces raylib's `ToggleFullscreen`.

  In a page the browser grants it only soon after a key press, click or tap. Without one, it waits for the next, or refuses.

  Called while borderless, it only switches to fullscreen.

  `IsWindowFullscreen` reports the new state once the window has changed, not when the call returns.
- `ToggleBorderlessWindowedAsync`: Asynchronously asks for the window to fill the screen without borders, or back to the window. See `ToggleFullscreenAsync` for fullscreen.
  - `done`: Optional. Called once the window has changed, or once it is refused, at a later poll.
  - `failed`: Optional. Receives why it was refused; when omitted, it is logged.

  It replaces raylib's `ToggleBorderlessWindowed`.

  The screen goes fullscreen. Natively a fullscreen window is borderless and the size of the desktop.

  In a page it waits for a key press, click or tap, as `ToggleFullscreenAsync` does.

  Called while fullscreen, it only switches to borderless.

  As in raylib, `IsWindowState(FLAG_BORDERLESS_WINDOWED_MODE)` is true while it is, and `IsWindowFullscreen` false.
- `SetWindowSizeAsync`: Asynchronously asks for the window's size. See `SetWindowMinSizeAsync` and `SetWindowMaxSizeAsync` for limiting the sizes it can be resized to.
  - `width`: The width, in pixels.
  - `height`: The height, in pixels.
  - `done`: Optional. Called once the window has a size from the request, or once it is refused, at a later poll.
  - `failed`: Optional. Receives why it wasn't resized; when omitted, it is logged.

  It replaces raylib's `SetWindowSize`.

  The window manager may give another size. `GetScreenWidth` and `GetScreenHeight` report it once it has.

  It is refused while the window is fullscreen or maximized, and in a page, whose canvas follows the page.

  A size under 1 pixel is refused.
- `SetWindowPositionAsync`: Asynchronously asks for the window's place on the desktop. See `SetWindowMonitorAsync` for moving it to another monitor.
  - `x`: The left edge, in pixels.
  - `y`: The top edge, in pixels.
  - `done`: Optional. Called once the window has moved, or once it is refused, at a later poll.
  - `failed`: Optional. Receives why it didn't move; when omitted, it is logged.

  It replaces raylib's `SetWindowPosition`.

  It is refused in a page, under Wayland, and while the window is fullscreen or maximized.
- `SetWindowMonitorAsync`: Asynchronously asks for the window on another monitor. See `SetWindowPositionAsync` for placing it on the desktop.
  - `monitor`: The monitor, 0 to `GetMonitorCount() - 1`.
  - `done`: Optional. Called once the window is on the monitor, or once it is refused, at a later poll.
  - `failed`: Optional. Receives why it isn't, such as a monitor that isn't there; when omitted, it is logged.

  It replaces raylib's `SetWindowMonitor`.

  Where the window can't be moved, a monitor other than its own is refused.
- `MaximizeWindowAsync`: Asynchronously asks for the window maximized. See `RestoreWindowAsync` for bringing it back.
  - `done`: Optional. Called once the window is maximized, or once it is refused, at a later poll.
  - `failed`: Optional. Receives why it wasn't; when omitted, it is logged.

  It replaces raylib's `MaximizeWindow`.

  It is refused in a page, which can't maximize its window.
- `MinimizeWindowAsync`: Asynchronously asks for the window minimized. See `RestoreWindowAsync` for bringing it back.
  - `done`: Optional. Called once the window is minimized, or once it is refused, at a later poll.
  - `failed`: Optional. Receives why it wasn't; when omitted, it is logged.

  It replaces raylib's `MinimizeWindow`.

  It is refused in a page, which can't minimize its window.
- `RestoreWindowAsync`: Asynchronously asks for the window back to its size from minimized or maximized. See `MaximizeWindowAsync` and `MinimizeWindowAsync` for changing it.
  - `done`: Optional. Called once the window is restored, or once it is refused, at a later poll.
  - `failed`: Optional. Receives why it wasn't; when omitted, it is logged.

  It replaces raylib's `RestoreWindow`.

  A minimized window is restored from minimized, any other from maximized.
- `SetWindowFocusedAsync`: Asynchronously asks for the window brought to the front with the keyboard.
  - `done`: Optional. Called once the window has the keyboard or the window manager keeps it elsewhere, at a later poll.
  - `failed`: Optional. Receives why it hasn't; when omitted, it is logged.

  It replaces raylib's `SetWindowFocused`.

  A window manager may only flash it.

  In a page the canvas takes the keyboard.
- `SetWindowOpacityAsync`: Asynchronously asks for the window's opacity.
  - `opacity`: From 0 (clear) to 1 (opaque).
  - `done`: Optional. Called once the window has the opacity, or once it is refused, at a later poll.
  - `failed`: Optional. Receives why it hasn't; when omitted, it is logged.

  It replaces raylib's `SetWindowOpacity`.

  In a page the canvas fades.

  A desktop without a compositor refuses it.
- `SetWindowMinSizeAsync`: Asynchronously asks for the smallest size the window can be resized to. See `SetWindowMaxSizeAsync` for setting the largest.
  - `width`: The width, in the screen's pixels.
  - `height`: The height.
  - `done`: Optional. Called once the window has the limit, or once it is refused, at a later poll.
  - `failed`: Optional. Receives why it hasn't; when omitted, it is logged.

  It replaces raylib's `SetWindowMinSize`.

  It is refused in a page, whose canvas follows the page.

  A size under 0 pixels is refused.
- `SetWindowMaxSizeAsync`: Asynchronously asks for the largest size the window can be resized to. See `SetWindowMinSizeAsync` for setting the smallest.
  - `width`: The width, in the screen's pixels.
  - `height`: The height.
  - `done`: Optional. Called once the window has the limit, or once it is refused, at a later poll.
  - `failed`: Optional. Receives why it hasn't; when omitted, it is logged.

  It replaces raylib's `SetWindowMaxSize`.

  It is refused in a page, whose canvas follows the page.

  A size under 0 pixels is refused.
- `DisableCursorAsync`: Asynchronously locks the mouse to the window and hides the cursor, for looking around. See `EnableCursorAsync` for letting it go.
  - `done`: Optional. Called once the mouse is locked, or once it is refused, at a later poll.
  - `failed`: Optional. Receives why it wasn't; when omitted, it is logged.

  It replaces raylib's `DisableCursor`.

  `GetMouseDelta` keeps coming while the position goes on past the window's edges.

  `IsCursorHidden` is true from the call.

  In a page the browser locks it only soon after a click or key press. Without one, it locks at the next. Escape lets it go.
- `EnableCursorAsync`: Asynchronously lets go of the mouse that `DisableCursorAsync` locked and shows the cursor.
  - `done`: Optional. Called once the mouse is let go, at a later poll.
  - `failed`: Optional. Receives why it wasn't; when omitted, it is logged.

  It replaces raylib's `EnableCursor`.

  `IsCursorHidden` is false from the call.
- `SetClipboardTextAsync`: Asynchronously puts text on the system's clipboard. See `GetClipboardTextAsync` for reading it.
  - `text`: The text.
  - `done`: Optional. Called once the text is on the clipboard, or once it is refused, at a later poll.
  - `failed`: Optional. Receives why it isn't; when omitted, it is logged.

  It replaces raylib's `SetClipboardText`.

  A page writes it only while it has the keyboard, soon after a press.
- `GetClipboardTextAsync`: Asynchronously reads the clipboard's text. See `GetClipboardImageAsync` for reading an image.
  - `read`: Receives the text at a later poll; "" when the clipboard holds none.
  - `failed`: Optional. Receives why it couldn't be read; when omitted, it is logged.

  It replaces raylib's `GetClipboardText`.

  A page reads it only with permission, which the browser may ask for.
- `GetClipboardImageAsync`: Asynchronously reads the clipboard's image. See `GetClipboardTextAsync` for reading text.
  - `loaded`: Receives the image once it is decoded, `PIXELFORMAT_UNCOMPRESSED_R8G8B8A8`.
  - `failed`: Optional. Receives why there is none, or why it couldn't be read; when omitted, it is logged.

  It replaces raylib's `GetClipboardImage`.

  A page reads it only with permission, which the browser may ask for.
- `TakeScreenshotAsync`: Asynchronously takes a screenshot of the next frame and saves it as a file. See `LoadImageFromScreenAsync` for the screen as an `Image`.
  - `fileName`: The file's name, or its path; a name with `'` is refused, as raylib's is.
  - `done`: Optional. Called once the file is written or downloaded, or once it is refused, at a later poll.
  - `failed`: Optional. Receives why it wasn't; when omitted, it is logged.

  It replaces raylib's `TakeScreenshot`.

  The name's extension picks the format, as `ExportImageAsync` does: ".png", ".qoi" or ".raw". Any other is refused.

  In a page it is downloaded under the name's file name, as raylib's web build does.

  Natively it is written where the name says, as raylib 6.2 writes it. A relative name is under the working directory, its directories kept. An absolute one is where it is.

  A directory that isn't there isn't made, and the screenshot is refused.

  It is taken as the next frame ends, not from the frame drawn last as raylib's is.

  Its alpha is opaque, as raylib's is.

  It is refused before `InitWindow`.
