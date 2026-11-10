# helix.raylib.extras

[Back to the library](README.md)

## Audio

*class* in [`engines/raylib/src/helix/raylib/extras/Audio.hx`](../src/helix/raylib/extras/Audio.hx), `import helix.raylib.extras.Audio;`

Provides the async versions of raylib 5.5's sound, wave and music loads and wave writes (raudio), helix-raylib's own, as a file is read later and most formats are decoded off the main thread: `LoadSoundAsync` for `LoadSound`, `LoadMusicStreamAsync` for `LoadMusicStream` and the rest. raylib's own call doesn't compile and names the one here (docs/DECISIONS.md 24, 38). Imported apart: `import helix.raylib.extras.Audio.*;`.

Each answers at a later poll, never during the call: `done` or `loaded` once it is done, `failed` with the reason when it is refused, logged as raylib's warning would be when `failed` is omitted.

### audio: the sound, wave and music loads and wave writes in place of raudio's that wait

```haxe
static function LoadSoundAsync(fileName:String, loaded:Sound -> Void, ?failed:String -> Void):Void
static function LoadMusicStreamAsync(fileName:String, loaded:Music -> Void, ?failed:String -> Void):Void
static function ExportWaveAsync(wave:Wave, fileName:String, ?done:() -> Void, ?failed:String -> Void):Void
static function ExportWaveAsCodeAsync(wave:Wave, fileName:String, ?done:() -> Void, ?failed:String -> Void):Void
```

- `LoadSoundAsync`: Asynchronously loads and decodes a sound file, ready to play at once, replacing raylib's `LoadSound`. See `LoadMusicStreamAsync` for playing a file as it is read.
  - `fileName`: The file, as the program names it.
  - `loaded`: Receives the sound.
  - `failed`: Optional. Receives why it couldn't be loaded; when omitted, it is logged.

  `InitAudioDevice` must come first.

  A file loaded again shares its first load's decoded sound.
- `LoadMusicStreamAsync`: Asynchronously opens a music file to be played as it is read, replacing raylib's `LoadMusicStream`. See `LoadSoundAsync` for decoding a file whole first.
  - `fileName`: The file, as the program names it, such as "assets/theme.ogg".
  - `loaded`: Receives the music, ready to play, once enough of the file has arrived to start.
  - `failed`: Optional. Receives why it couldn't be opened; when omitted, it is logged.

  `InitAudioDevice` must come first.

  A FLAC file is refused, as raylib 5.5's default build leaves FLAC out.

  Never loaded whole: it is read as it plays (helix-services' `Audio.stream`).
- `ExportWaveAsync`: Asynchronously writes a wave to a sound file, replacing raylib's `ExportWave`. See `ExportWaveAsCodeAsync` for writing a C header.
  - `wave`: The wave.
  - `fileName`: The file; its extension chooses the format.
  - `done`: Optional. Called once the file is written, or once it is refused, at a later poll.
  - `failed`: Optional. Receives why it wasn't, such as a wave with no samples or another extension; when omitted, it is logged.

  The extension chooses the format:

  - ".wav": 8, 16 and 24-bit samples as integers, 32-bit as floats, as raylib's dr_wav writes them. - ".raw": the samples unchanged.

  A ".qoa" file is refused, though raylib writes one.

  The file is written and kept by `SaveFileDataAsync`.
- `ExportWaveAsCodeAsync`: Asynchronously writes a wave as a C header, replacing raylib's `ExportWaveAsCode`. See `ExportWaveAsync` for writing a sound file.
  - `wave`: The wave.
  - `fileName`: The file; its name, upper case, names the defines and the array.
  - `done`: Optional. Called once the file is written, or once it is refused, at a later poll.
  - `failed`: Optional. Receives why it wasn't; when omitted, it is logged.

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

  A ".wav" file is read as dr_wav reads it, as 16-bit samples at the file's rate and channels (ADPCM and other compressed WAV encodings aren't read). A ".qoa" file is read as qoa.h reads it, as 16-bit samples, bit for bit. An ".ogg" file (Vorbis) is decoded by the platform at its own rate and made 16-bit as stb_vorbis makes its samples, its frames the stream's length, its last page's position. An ".mp3" file is decoded by the platform at its own rate, every frame of it, as raylib 5.5's dr_mp3 decodes it (a first Xing or Info frame is silence, and the encoder's delay and padding a LAME tag records are kept), and made 16-bit and then 32-bit float samples as that dr_mp3 makes them. An MP3's samples are raylib's and an Ogg file's within 1 in 32768 of them where the platform decodes as raylib does. Where its decoders differ, the samples differ in their last bits, and the frames a decoder leaves off an Ogg stream's end (tens of them) are silence. A file of more than 2 channels is mixed to stereo. A ".flac" file isn't read, as raylib 5.5's default build leaves FLAC out ("WAVE: Data format not supported"). As raylib's, the extension is lower or upper case. The answer comes at a later frame.

  The reader is chosen as the program builds when `fileType` is a constant, so a program reading only Ogg files carries no WAV or QOA reader; a type known only as the program runs brings every reader.

## Files

*class* in [`engines/raylib/src/helix/raylib/extras/Files.hx`](../src/helix/raylib/extras/Files.hx), `import helix.raylib.extras.Files;`

Provides the async versions of raylib 5.5's file calls (rcore), helix-raylib's own, as a file is read later: `LoadFileTextAsync` for `LoadFileText`, `SaveFileTextAsync` for `SaveFileText`, `FileExistsAsync` for `FileExists` and the rest. raylib's own call doesn't compile and names the one here (docs/DECISIONS.md 24, 38). Imported apart: `import helix.raylib.extras.Files.*;`.

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

- `LoadFileDataAsync`: Asynchronously reads a file's bytes, replacing raylib's `LoadFileData`. See `LoadFileTextAsync` for reading a text file.
  - `fileName`: The file.
  - `loaded`: Receives its bytes.
  - `failed`: Optional. Receives why it couldn't be read; when omitted, it is logged.

  Reads the first of these that has the file: - the program's `SetLoadFileDataCallback` - what `SaveFileData` wrote - the program's files
- `LoadFileTextAsync`: Asynchronously reads a text file, replacing raylib's `LoadFileText`. See `LoadFileDataAsync` for reading a file's bytes.
  - `fileName`: The file.
  - `loaded`: Receives its text.
  - `failed`: Optional. Receives why it couldn't be read; when omitted, it is logged.

  Reads the first of these that has the file: - the program's `SetLoadFileTextCallback` - what `SaveFileText` wrote - the program's files

  The text ends at the file's first NUL byte, as raylib's C string does.

  A byte that isn't UTF-8 is read as U+FFFD. A file is never refused for what it holds.
- `SaveFileDataAsync`: Asynchronously writes a file's bytes, replacing raylib's `SaveFileData`. See `SaveFileTextAsync` for writing text.
  - `fileName`: The file.
  - `data`: The bytes.
  - `dataSize`: How many of them.
  - `done`: Optional. Called once the file is written, or once it is refused, at a later poll.
  - `failed`: Optional. Receives why it wasn't; when omitted, it is logged.

  They are written through the program's `SetSaveFileDataCallback` when it has one. Otherwise they are kept across runs, as `SaveFileTextAsync`'s are.

  `LoadFileDataAsync` reads them back.
- `SaveFileTextAsync`: Asynchronously writes a text file, replacing raylib's `SaveFileText`. See `SaveFileDataAsync` for writing bytes.
  - `fileName`: The file.
  - `text`: Its text.
  - `done`: Optional. Called once the file is written, or once it is refused, at a later poll.
  - `failed`: Optional. Receives why it wasn't; when omitted, it is logged.

  Written through the program's `SetSaveFileTextCallback` when it has one, during the call, and answered by what that returned.

  Otherwise it is kept across runs, and answered once the write has finished.

  `LoadFileTextAsync` reads it back.
- `FileExistsAsync`: Asynchronously answers whether a file exists, replacing raylib's `FileExists`. See `DirectoryExistsAsync` for a directory.
  - `fileName`: The file.
  - `answer`: Receives true when it exists.

  The answer comes at a later frame, never during the call.

  A file exists when `SaveFileText` or `SaveFileData` wrote it, or when it is one of the program's.

  Finding one of the program's files reads it, so a load of it after answers at once.
- `DirectoryExistsAsync`: Asynchronously answers whether a directory exists, replacing raylib's `DirectoryExists`. See `FileExistsAsync` for a file.
  - `dirPath`: The directory.
  - `answer`: Receives true when it exists.

  The answer comes at a later frame, never during the call.

  A directory exists when a file `SaveFileText` or `SaveFileData` wrote is in it. The root ("", "." or "./") always exists.

  `helix-raylib-dropped` and the directories under it hold the dropped files.

  The program's own files aren't in directories: a program names each one it loads.
- `IsPathFileAsync`: Asynchronously answers whether a path is a file, not a directory, replacing raylib's `IsPathFile`. See `DirectoryExistsAsync` for a directory.
  - `path`: The path.
  - `answer`: Receives true for a file; false for a directory or nothing there.

  The answer comes at a later frame, never during the call.

  These are files, as `FileExistsAsync` finds them: - a file `SaveFileText` or `SaveFileData` wrote - a dropped file - a file the program has
- `GetFileLengthAsync`: Asynchronously answers a file's size, replacing raylib's `GetFileLength`.
  - `fileName`: The file.
  - `answer`: Receives its size in bytes; 0 when there is no file, as raylib's.

  The answer comes at a later frame, never during the call.

  The size is: - for a file `SaveFileText` or `SaveFileData` wrote, or the program's `SetLoadFileDataCallback` gives, its bytes' size - for a dropped file, its own - for a file of the program's, its size
- `GetFileModTimeAsync`: Asynchronously answers when a file was last written, replacing raylib's `GetFileModTime`.
  - `fileName`: The file.
  - `answer`: Receives the time, in whole seconds since the Unix epoch; 0 when there is no file or no time, as raylib's.

  The answer comes at a later frame, never during the call.

  The time is: - for a file of the program's, its time on disk - for a file `SaveFileText` or `SaveFileData` wrote, when it was saved - for a dropped file, the time kept for it - 0 for a file whose time isn't kept, such as one the program's load callback gives
- `LoadDirectoryFilesAsync`: Asynchronously lists a directory's files and subdirectories, replacing raylib's `LoadDirectoryFiles`. See `LoadDirectoryFilesExAsync` for a filter by extension and the subdirectories' files.
  - `dirPath`: The directory.
  - `loaded`: Receives the list, its `capacity` its `count`; empty, with a warning, when the directory can't be listed, as raylib's.

  The answer comes at a later frame, never during the call.

  Each path is the directory's followed by `/` and the name (`dirPath` "levels" gives "levels/1.json"). A subdirectory's has no slash at its end.

  The paths are sorted by name.

  The files listed are those `SaveFileText` and `SaveFileData` wrote, and the dropped files, in `DirectoryExistsAsync`'s directories. The program's own files aren't listed: a program names each one it loads.
- `LoadDirectoryFilesExAsync`: Asynchronously lists a directory's files with some extensions, and with `scanSubdirs` its subdirectories' too, replacing raylib's `LoadDirectoryFilesEx`. See `LoadDirectoryFilesAsync` for listing one directory's every file and subdirectory.
  - `basePath`: The directory.
  - `filter`: The extensions kept, such as ".png;.jpg;DIR", or null for every file.
  - `scanSubdirs`: Whether the subdirectories' files are listed too.
  - `loaded`: Receives the list, its `capacity` 8192; a directory that can't be listed adds nothing, with a warning.

  The answer comes at a later frame, never during the call.

  The paths are `LoadDirectoryFilesAsync`'s, a subdirectory's files right after it.

  A filter is `IsFileExtension`'s list. "DIR" in it keeps the subdirectories.

  A null filter keeps every file, and without `scanSubdirs` every subdirectory too.

  At most 8192 paths are listed (raylib's `MAX_FILEPATH_CAPACITY`), with a warning when there are more.
- `ExportDataAsCodeAsync`: Asynchronously writes bytes as a C header, the text raylib's `ExportDataAsCode` writes. See `SaveFileDataAsync` for the bytes as they are.
  - `data`: The bytes.
  - `dataSize`: How many of them.
  - `fileName`: The file; its name, upper case, names the define and the array, with `_` for `.`, `-`, `?`, `!` and `+`.
  - `done`: Optional. Called once the file is written, or once it is refused, at a later poll.
  - `failed`: Optional. Receives why it wasn't; when omitted, it is logged.

  The header is raylib's, byte for byte: - the bytes' count, as a define - the bytes, as an array in hexadecimal, 20 a line

  Written through `SaveFileTextAsync`.
- `LoadAutomationEventListAsync`: Asynchronously loads an automation events list from a text file, replacing raylib's `LoadAutomationEventList` given a file. See `ExportAutomationEventListAsync` for writing one.
  - `fileName`: The file, as `ExportAutomationEventList` writes it.
  - `loaded`: Receives the list, its capacity 16384.
  - `failed`: Optional. Receives why it couldn't be read; when omitted, it is logged.

  The file is read as `LoadFileTextAsync` reads it.

  Reads these lines, as raylib's does: - a line starting `c`, the count - a line starting `e`, an event: its frame, type and four parameters

  Other lines are skipped. So is a last line with no newline at its end, as raylib's reading skips it. A line is read 255 characters at most, as raylib's `fgets` reads it.

  A count that isn't the number of events read warns, and the count becomes the events read.
- `ExportAutomationEventListAsync`: Asynchronously writes a list's events as text, the text raylib's `ExportAutomationEventList` writes. See `LoadAutomationEventListAsync` for reading it back.
  - `list`: The list.
  - `fileName`: The file.
  - `done`: Optional. Called once the file is written, or once it is refused, at a later poll.
  - `failed`: Optional. Receives why it wasn't; when omitted, it is logged.

  The text is raylib's, byte for byte: - a header of comments - `c` and the count - a line for each event: `e`, its frame, type and four parameters, and its type's name

  Written through `SaveFileTextAsync`.

## Gui

*class* in [`engines/raylib/src/helix/raylib/extras/Gui.hx`](../src/helix/raylib/extras/Gui.hx), `import helix.raylib.extras.Gui;`

Provides the async versions of raygui's style and icon loads, helix-raylib's own, as a file is read later: `GuiLoadStyleAsync` for `GuiLoadStyle` and `GuiLoadIconsAsync` for `GuiLoadIcons`. raygui's own call doesn't compile and names the one here (docs/DECISIONS.md 38). Imported apart: `import helix.raylib.extras.Gui.*;`.

Each answers at a later poll, never during the call: `done` or `loaded` once it is done, `failed` with the reason when it is refused, logged as raylib's warning would be when `failed` is omitted.

### gui: the style and icon loads in place of raygui's that wait for a file

```haxe
static function GuiLoadStyleAsync(fileName:String, ?done:() -> Void, ?failed:String -> Void):Void
static function GuiLoadIconsAsync(fileName:String, loadIconsName:Bool, loaded:Array<String> -> Void, ?failed:String -> Void):Void
```

- `GuiLoadStyleAsync`: Asynchronously loads a style file (.rgs) over the current style, replacing raygui's `GuiLoadStyle`.
  - `fileName`: The style file.
  - `done`: Optional. Called once the style is loaded, at a later poll.
  - `failed`: Optional. Receives why it couldn't be read; when omitted, it is logged.

  The default style is loaded first if it isn't yet.

  A text file's first line starts with '#'. It reads: - each `p <control> <property> 0x<value>` line, which sets that property. - the `f <size> <charmap> <font>` line, which loads the font at its size with the charmap file's characters. Both files are beside the style file.

  A font that can't be loaded, or an `f` line naming none, leaves raylib's default font at size 10. A file that can't be read leaves the default style, loaded first.

  A text file's last line is read only when a line break ends it, as in raygui.

  A binary file sets its properties, and its font when it holds one.
- `GuiLoadIconsAsync`: Asynchronously loads an icon file (.rgi) over raygui's icons, replacing raygui's `GuiLoadIcons`.
  - `fileName`: The icon file.
  - `loadIconsName`: Whether the icons' names are read.
  - `loaded`: Receives the icons' names, in order, or null when they weren't read or the file isn't an icon file.
  - `failed`: Optional. Receives why it couldn't be read; when omitted, it is logged.

  The file's icons replace raygui's from the first, as raygui reads them.

  A file that isn't an icon file changes nothing.

## Lighting

*class* in [`engines/raylib/src/helix/raylib/extras/Lighting.hx`](../src/helix/raylib/extras/Lighting.hx), `import helix.raylib.extras.Lighting;`

Provides lit shaders, built in, that rlights' lights light (`helix.raylib.Rlights`): `LoadLightingShader`, raylib's lighting examples' `lighting.vs` and `lighting.fs`, which shine every material alike, and `LoadPbrShader`, which draws a glTF's materials as authored, metallic-roughness. Imported apart: `import helix.raylib.extras.Lighting.*;`.

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

A model posed by `UpdateModelAnimation` under either is skinned on the GPU. A program's own shader lights as the lit one does by including `<helix/raylib/shaders/lights.glsl>`: rlights' uniforms and `vec4 helixLight(vec4 texelColor, vec4 tint, vec3 fragPosition, vec3 fragNormal)`, called as `helixLight(texture(texture0, fragTexCoord), colDiffuse*fragColor, fragPosition, fragNormal)`; and as the PBR one does by including `<helix/raylib/shaders/pbr.glsl>`, `vec4 helixPbr(vec4 baseColor, float metallic, float roughness, float occlusion, vec3 emissive, vec3 fragPosition, vec3 normal)`. A program that calls none of this links none of it.

### lighting: the lit and PBR shaders rlights' lights light

```haxe
static function LoadLightingShader():Shader
static function LoadPbrShader():Shader
```

- `LoadLightingShader`: Returns raylib's examples' lighting shader (`lighting.vs` and `lighting.fs`), built in. It shines every material alike, one Phong highlight whatever the material says. See `LoadPbrShader` for drawing a glTF's materials as authored.
  - returns: The shader, the program's until `UnloadShader`.

  Set up as raylib's lighting example does: `locs[SHADER_LOC_VECTOR_VIEW]` is `viewPos`, set to the camera's position each frame; `GetShaderLocation(shader, "ambient")` finds the ambient color; lights come from rlights' `CreateLight`. A model posed by `UpdateModelAnimation` under it is skinned on the GPU. A program's own shader lights the same way by including `<helix/raylib/shaders/lights.glsl>`.

  ```haxe
  var shader = LoadLightingShader();
  SetShaderValue(shader, GetShaderLocation(shader, "ambient"), [0.1, 0.1, 0.1, 1.0], SHADER_UNIFORM_VEC4);
  model.materials[0].shader = shader;
  var light = CreateLight(LIGHT_POINT, new Vector3(-2, 1, -2), Vector3Zero(), YELLOW, shader);
  ```
- `LoadPbrShader`: Returns helix-raylib's PBR shader, built in: a glTF's materials drawn as authored, metallic-roughness under the same lights as `LoadLightingShader`, which shines every material alike.
  - returns: The shader, the program's until `UnloadShader`.

  Set up as that one: `locs[SHADER_LOC_VECTOR_VIEW]` is `viewPos`, set to the camera's position each frame; `GetShaderLocation(shader, "ambient")` finds the ambient color; lights come from rlights' `CreateLight`, a light's color what a white surface facing it shows. A model posed by `UpdateModelAnimation` under it is skinned on the GPU. A material marked `unlit` (glTF's `KHR_materials_unlit`) draws its base color and no light.

  Each light also has a range and an intensity, set with `SetShaderValue` at `GetShaderLocation(shader, "lights[0].range")` and `"lights[0].intensity"` (and the next light's at `lights[1]`). A point light with a range dims with distance, fading to nothing at the range, and 0, the default, is no falloff. Intensity is a multiple of the light's color, 1 by default. Light brighter than white rolls off toward white instead of clipping, and colors in the usual range come out as authored.

  Each draw reads the material's maps `MATERIAL_MAP_ALBEDO`, `MATERIAL_MAP_METALNESS`, `MATERIAL_MAP_ROUGHNESS`, `MATERIAL_MAP_NORMAL`, `MATERIAL_MAP_OCCLUSION` and `MATERIAL_MAP_EMISSION`. Their samplers are `albedoMap`, `metalnessMap`, `roughnessMap`, `normalMap`, `occlusionMap` and `emissiveMap`, found at `locs[SHADER_LOC_MAP_ALBEDO]` and the five after it. A missing map reads white, and a missing normal map reads a flat normal.

  Each draw also reads the material's values. `maps[MATERIAL_MAP_ALBEDO].color` times the tint is `colDiffuse`. `maps[MATERIAL_MAP_METALNESS].value` is `metallicValue`, `maps[MATERIAL_MAP_ROUGHNESS].value` is `roughnessValue`, and `maps[MATERIAL_MAP_EMISSION].color` is `emissiveColor`. Colors are taken as linear, as a glTF's factors are. An image's texels are decoded from sRGB. A material from `LoadMaterialDefault` is a smooth non-metal, both values 0, until set.

  A mesh without tangents under a normal map gets them with its first draw (`GenMeshTangents`). A program's own shader draws the same way by including `<helix/raylib/shaders/pbr.glsl>`.

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

## Models

*class* in [`engines/raylib/src/helix/raylib/extras/Models.hx`](../src/helix/raylib/extras/Models.hx), `import helix.raylib.extras.Models;`

Provides the async versions of raylib 5.5's model, material and animation loads and mesh writes (rmodels), helix-raylib's own, as a file is read later: `LoadModelAsync` for `LoadModel`, `LoadModelAnimationsAsync` for `LoadModelAnimations` and the rest. raylib's own call doesn't compile and names the one here (docs/DECISIONS.md 24, 38). Imported apart: `import helix.raylib.extras.Models.*;`.

Each answers at a later poll, never during the call: `done` or `loaded` once it is done, `failed` with the reason when it is refused, logged as raylib's warning would be when `failed` is omitted.

And a model's bounds as posed, which raylib's `GetModelBoundingBox` leaves at the bind pose: `GetModelBoundingBoxPosed`.

### models: the model, material and animation loads and mesh writes in place of rmodels' that wait

```haxe
static function LoadModelAnimationsAsync(fileName:String, loaded:Array<ModelAnimation> -> Void, ?failed:String -> Void):Void
static function LoadMaterialsAsync(fileName:String, loaded:Array<Material> -> Void, ?failed:String -> Void):Void
static function ExportMeshAsync(mesh:Mesh, fileName:String, ?done:() -> Void, ?failed:String -> Void):Void
static function ExportMeshAsCodeAsync(mesh:Mesh, fileName:String, ?done:() -> Void, ?failed:String -> Void):Void
```

- `LoadModelAnimationsAsync`: Asynchronously loads a glTF or GLB file's animations, replacing raylib's `LoadModelAnimations`.
  - `fileName`: The file, as the program names it.
  - `loaded`: Receives the animations, as many as the file has; their count is its length.
  - `failed`: Optional. Receives why they couldn't be loaded; when omitted, it is logged.

  A file without skins gives none. Only the file's first skin is read.

  IQM and M3D animations are refused, as is any file but glTF and GLB.

  Each animation is sampled 60 times a second, as raylib 6.2 samples it, with (int)(duration * 60) + 1 frames.

  Each frame's pose is its bones' transforms in the model.
- `LoadMaterialsAsync`: Asynchronously loads an .mtl file's materials with the textures they name, replacing raylib's `LoadMaterials`. See `LoadModelAsync` for loading an OBJ file with the materials its `mtllib` names.
  - `fileName`: The file, as the program names it: an .mtl file.
  - `loaded`: Receives the materials, in the file's order; their count is its length.
  - `failed`: Optional. Receives why they couldn't be loaded (the file isn't an .mtl file, can't be found or can't be read); when omitted, it is logged.

  The program holds each material until `UnloadMaterial`.

  Each starts as raylib's default material, and reads these fields as raylib's `ProcessMaterialsOBJ` does:

  - `map_Kd`, the diffuse texture, or with none MTL's `Kd`, the diffuse color (alpha 255). - `map_Ks` and MTL's `Ks`, the specular texture and color. - `bump` or `map_bump`, the normal map's texture. The normal map's color is white and its value is MTL's `Ns`, the specular exponent. - MTL's `Ke`, the emission color. - `disp`, the height map's texture.

  A field a material doesn't give defaults to tinyobj_loader_c's default, as raylib has it. Each color is black and the specular exponent is 1.

  A texture's path is resolved against the file's directory. A texture that can't be read is none (id 0) and is logged.

  A file that breaks the format fails.
- `ExportMeshAsync`: Asynchronously writes a mesh as an OBJ file through `SaveFileTextAsync`, replacing raylib's `ExportMesh`. See `ExportMeshAsCodeAsync` for writing a C header.
  - `mesh`: The mesh, with positions, texture coordinates and normals.
  - `fileName`: The file; only ".obj" is written.
  - `done`: Optional. Called once the file is written, or once it is refused, at a later poll.
  - `failed`: Optional. Receives why it wasn't, such as another extension; when omitted, it is logged.

  Positions and texture coordinates are written to 6 places, normals to 4, and each face as a triangle, as raylib's `ExportMesh` writes them.
- `ExportMeshAsCodeAsync`: Asynchronously writes a mesh as a C header through `SaveFileTextAsync`, replacing raylib's `ExportMeshAsCode`. See `ExportMeshAsync` for writing an OBJ file.
  - `mesh`: The mesh.
  - `fileName`: The file; its name, upper case, names the defines and the arrays.
  - `done`: Optional. Called once the file is written, or once it is refused, at a later poll.
  - `failed`: Optional. Receives why it wasn't; when omitted, it is logged.

  The mesh\'s counts are written as defines, and each array it has as 20 values a line, floats to 3 places, as raylib's `ExportMeshAsCode` writes them.

### models: a skinned model's bounds as posed

```haxe
static function GetModelBoundingBoxPosed(model:Model):BoundingBox
```

- `GetModelBoundingBoxPosed`: Returns a model's bounds as its last `UpdateModelAnimation` (or `UpdateModelAnimationEx`) posed it: `GetModelBoundingBox`'s box, each skinned mesh bounded by its vertices where its bones put them rather than where the skin was bound. A mesh never posed, or without bones, counts as it is, and so does a vertex no bone weights. It is exact whatever shader draws the mesh, as it works the positions out from the pose itself, allocating nothing; that is each skinned vertex moved by its bones, on the CPU, each call. As `GetModelBoundingBox`, its least and most corners are then moved by the model's transform (a turned model's box is not its bounds).
  - `model`: The model.
  - returns: The box.

### models: models merged into one

```haxe
static function LoadModelFromModels(models:Array<Model>, ?skeleton:Model):Null<Model>
```

- `LoadModelFromModels`: Returns a new model with the provided models' meshes merged where possible. The provided models are unchanged. For example, a character's head, body, legs and feet models, whose materials differ only in color, are merged into one character model with one mesh.
  - `models`: The models.
  - `skeleton`: Optional. The model whose bones, bind pose and transform the new model takes. Usually one of the provided models.
  - returns: The new model, or null when refused.

  Meshes whose materials differ only in diffuse color are merged into one mesh. Each material's diffuse color is multiplied into the vertex colors, and the merged mesh has one material, the same material with a white diffuse color. Meshes whose materials differ in anything else (the shader, a texture, `unlit`, or another map's color or value) stay separate meshes.

  A shader that ignores the vertex color draws a merged mesh without the materials' colors.

  A mesh lacking normals, texture coordinates or colors that another merged mesh has gets normals (0, 0, 1), texture coordinates (0, 0) and white colors. Tangents are kept when every merged mesh has them. `texcoords2` is dropped.

  With `skeleton`, the new model has the bones, bind pose and transform of `skeleton`, and an animation that poses `skeleton` poses the new model. Each provided model's bones are matched to the bones of `skeleton` by name. A vertex following a bone that `skeleton` lacks follows the nearest ancestor of that bone that `skeleton` has. A vertex with no such ancestor stays where it is when the new model is posed. A provided model bound in another bind pose is rebound to the bind pose of `skeleton`. A vertex following several bones whose bind poses differ by different amounts is rebound approximately. A provided model without bones is placed where its transform put it.

  Without `skeleton`, the new model has no bones and the identity transform. Each provided model's transform is multiplied into the model's vertices, and a provided model with bones is merged at its bind pose.

  The merged meshes are uploaded. Refused, with the reason logged, for an empty list, for a provided model with bones whose transform differs from the transform of `skeleton`, and for a `skeleton` of more than 256 bones.

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

## Shaders

*class* in [`engines/raylib/src/helix/raylib/extras/Shaders.hx`](../src/helix/raylib/extras/Shaders.hx), `import helix.raylib.extras.Shaders;`

Provides the loads of shaders compiled ahead of time, in place of raylib's `LoadShader` and `LoadShaderFromMemory`. Imported apart: `import helix.raylib.extras.Shaders.*;`.

### shaders: the loads of shaders compiled ahead of time

```haxe
static function LoadCompiledShaderAsync(compiledShaderFileName:String, loaded:Shader -> Void, ?failed:String -> Void):Void
static function LoadCompiledShaderFromData(compiledShaderData:haxe.io.Bytes):Shader
```

- `LoadCompiledShaderAsync`: Asynchronously loads a shader compiled ahead of time by `CompileShaderFile`, replacing raylib's `LoadShader`. See `LoadCompiledShaderFromData` for making one from compiled data in memory.
  - `compiledShaderFileName`: The compiled shader's file.
  - `loaded`: Receives the shader.
  - `failed`: Optional. Receives why it couldn't be loaded; when omitted, it is logged.

  Its stages are raylib's GLSL (`#version 330`), and may include helix-raylib's shader includes, such as `<helix/raylib/shaders/skinning.glsl>`. Compile each shader with a line in the build's hxml:

  ```hxml
  --macro helix.raylib.extras.Shaders.CompileShaderFile("shaders/glow.vs", "shaders/glow.fs", "web/glow.shader")
  ```
- `LoadCompiledShaderFromData`: Returns a shader made from a compiled shader's data, replacing raylib's `LoadShaderFromMemory`. See `LoadCompiledShaderAsync` for loading one from a file.
  - `compiledShaderData`: The compiled shader, as `CompileShaderFile` writes it.
  - returns: The shader, or an empty one (id 0) when the data isn't a compiled shader, with a warning.

### Macros, run as the program builds

```haxe
static macro function CompileShaderFile(vsFileName:Null<String>, fsFileName:Null<String>, compiledShaderFileName:String):Void
```

- `CompileShaderFile`: Compiles a shader's two stages, raylib's GLSL, into a file `LoadCompiledShaderAsync` loads on every target. Run as a `--macro` of the program's build, or of an hxml of its own, one line a shader:
  - `vsFileName`: The vertex stage's file, or null for raylib's default.
  - `fsFileName`: The fragment stage's file, or null for raylib's default.
  - `compiledShaderFileName`: The file to write.

  ```hxml
  -lib helix-raylib
  --macro helix.raylib.extras.Shaders.CompileShaderFile("shaders/glow.vs", "shaders/glow.fs", "web/glow.shader")
  ```

## Text

*class* in [`engines/raylib/src/helix/raylib/extras/Text.hx`](../src/helix/raylib/extras/Text.hx), `import helix.raylib.extras.Text;`

Provides the async versions of raylib 5.5's font loads and writes (rtext), helix-raylib's own, as a file is read later and glyphs are rasterized off the main thread: `LoadFontAsync` for `LoadFont`, `LoadFontExAsync` for `LoadFontEx` and the rest. raylib's own call doesn't compile and names the one here (docs/DECISIONS.md 24, 38). Imported apart: `import helix.raylib.extras.Text.*;`.

Each answers at a later poll, never during the call: `done` or `loaded` once it is done, `failed` with the reason when it is refused, logged as raylib's warning would be when `failed` is omitted.

### text: the font loads and writes in place of rtext's that wait

```haxe
static function LoadFontExAsync(fileName:String, fontSize:Int, codepoints:Array<Int>, codepointCount:Int, loaded:Font -> Void, ?failed:String -> Void):Void
static function LoadFontFromMemoryAsync(fileType:String, fileData:haxe.io.Bytes, dataSize:Int, fontSize:Int, codepoints:Array<Int>, codepointCount:Int, loaded:Font -> Void, ?failed:String -> Void):Void
static function LoadFontDataAsync(fileData:haxe.io.Bytes, dataSize:Int, fontSize:Int, codepoints:Array<Int>, codepointCount:Int, type:Int, loaded:Array<GlyphInfo> -> Void, ?failed:String -> Void):Void
static function ExportFontAsCodeAsync(font:Font, fileName:String, ?done:() -> Void, ?failed:String -> Void):Void
```

- `LoadFontExAsync`: Asynchronously loads a TrueType or OpenType font file at a size, replacing raylib's `LoadFontEx`. See `LoadFontFromMemoryAsync` for making a font from bytes already loaded.
  - `fileName`: The file, as the program names it.
  - `fontSize`: The glyphs' size: the height of a line, in pixels.
  - `codepoints`: The characters, or null for those from the space on.
  - `codepointCount`: How many characters; 0 for 95, the printable ASCII when `codepoints` is null.
  - `loaded`: Receives the font once its glyphs are ready.
  - `failed`: Optional. Receives why it couldn't be loaded; when omitted, it is logged.

  The font holds only the characters the file has. `glyphCount` may be fewer than asked for, and a character it lacks draws as its '?'.

  Each Unicode space the file has (U+0020, U+00A0, U+2000 to U+200A, U+3000 and the others) is a blank glyph as wide as its advance.
- `LoadFontFromMemoryAsync`: Asynchronously makes a font from a TrueType or OpenType file's bytes, replacing raylib's `LoadFontFromMemory`. See `LoadFontExAsync` for loading a file by its name. The glyphs are rasterized off the main thread.
  - `fileType`: The file's extension, ".ttf" or ".otf". Any other is refused.
  - `fileData`: The file's bytes.
  - `dataSize`: How many of them.
  - `fontSize`: The glyphs' size: the height of a line, in pixels.
  - `codepoints`: The characters, or null for those from the space on.
  - `codepointCount`: How many characters; 0 for 95.
  - `loaded`: Receives the font once its glyphs are ready.
  - `failed`: Optional. Receives why it couldn't be made; when omitted, it is logged.

  The font holds only the characters the file has, as `LoadFontExAsync`'s does. With none of them, it is the default font.
- `LoadFontDataAsync`: Asynchronously rasterizes a TrueType or OpenType font's glyphs, each with its own image. See `LoadFontFromMemoryAsync` for a font ready to draw, replacing raylib's `LoadFontData`.
  - `fileData`: The font file's bytes.
  - `dataSize`: How many of them.
  - `fontSize`: The glyphs' size: the height of a line, in pixels.
  - `codepoints`: The characters, or null for those from the space on.
  - `codepointCount`: How many characters; 0 for 95.
  - `type`: `FONT_DEFAULT` for antialiased glyphs, `FONT_BITMAP` for glyphs with no gray, `FONT_SDF` for signed distances. Any other is taken as `FONT_DEFAULT`.
  - `loaded`: Receives the glyphs once they are ready.
  - `failed`: Optional. Receives why the font couldn't be read; when omitted, it is logged.

  Each glyph's image is 8-bit grayscale, for `GenImageFontAtlas`.

  Under `FONT_SDF` the images hold signed distances, with 4 texels of padding, 128 on the outline and 64 for each texel.
- `ExportFontAsCodeAsync`: Asynchronously writes a font as a C header, the text raylib 5.5's `ExportFontAsCode` writes. The file is written through `SaveFileTextAsync`, replacing raylib's `ExportFontAsCode`.
  - `font`: The font.
  - `fileName`: The file.
  - `done`: Optional. Called once the file is written, or once it is refused, at a later poll.
  - `failed`: Optional. Receives why it wasn't; when omitted, it is logged.

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

*class* in [`engines/raylib/src/helix/raylib/extras/Textures.hx`](../src/helix/raylib/extras/Textures.hx), `import helix.raylib.extras.Textures;`

Provides the async versions of raylib 5.5's image and texture loads and writes (rtextures), helix-raylib's own, as a file or the GPU answers later: `LoadTextureAsync` for `LoadTexture`, `LoadImageAsync` for `LoadImage`, `ExportImageAsync` for `ExportImage` and the rest. raylib's own call doesn't compile and names the one here (docs/DECISIONS.md 24, 38). Imported apart: `import helix.raylib.extras.Textures.*;`.

Each answers at a later poll, never during the call: `done` or `loaded` once it is done, `failed` with the reason when it is refused, logged as raylib's warning would be when `failed` is omitted.

### textures: the image and texture loads and writes in place of rtextures' that wait

```haxe
static function LoadImageRawAsync(fileName:String, width:Int, height:Int, format:Int, headerSize:Int, loaded:Image -> Void, ?failed:String -> Void):Void
static function LoadImageFromTextureAsync(texture:Texture2D, loaded:Image -> Void, ?failed:String -> Void):Void
static function LoadImageFromScreenAsync(loaded:Image -> Void, ?failed:String -> Void):Void
static function ExportImageAsync(image:Image, fileName:String, ?done:() -> Void, ?failed:String -> Void):Void
static function ExportImageAsCodeAsync(image:Image, fileName:String, ?done:() -> Void, ?failed:String -> Void):Void
```

- `LoadImageRawAsync`: Asynchronously loads an image's raw pixels from a file, replacing raylib's `LoadImageRaw`. See `LoadImageAsync` for an encoded image file.
  - `fileName`: The file.
  - `width`: The width, in pixels.
  - `height`: The height, in pixels.
  - `format`: The pixel format (`PIXELFORMAT_*`).
  - `headerSize`: The bytes before the pixels, skipped when the file holds them and the pixels.
  - `loaded`: Receives the image.
  - `failed`: Optional. Receives why it couldn't be loaded; when omitted, it is logged.

  A file with fewer bytes than the pixels need fails.

  A file too small for the header and the pixels is read from its first byte.
- `LoadImageFromTextureAsync`: Asynchronously reads a texture's pixels into an RGBA image, replacing raylib's `LoadImageFromTexture`. See `LoadImageFromScreenAsync` for the screen.
  - `texture`: The texture.
  - `loaded`: Receives the image, `PIXELFORMAT_UNCOMPRESSED_R8G8B8A8`.
  - `failed`: Optional. Receives why it couldn't be read; when omitted, it is logged.

  The image is RGBA, whatever the texture's format.

  A texture on the GPU (one drawn, or a render texture) is read as the frames drawn so far left it.

  A render texture's rows come bottom first, as raylib's do, so its image is upside down.

  A texture updated this frame (`UpdateTexture`) is read once the frame is drawn, so the update shows.

  A texture not drawn yet is read from memory. raylib's default texture is its white pixel.

  A cubemap is read from the image it was made from while that is kept in memory. Its faces on the GPU aren't read.
- `LoadImageFromScreenAsync`: Asynchronously reads the screen into an RGBA image as the next frame ends, replacing raylib's `LoadImageFromScreen`. See `TakeScreenshotAsync` for saving the screen to a file.
  - `loaded`: Receives the image, `PIXELFORMAT_UNCOMPRESSED_R8G8B8A8`.
  - `failed`: Optional. Receives why it couldn't be read; when omitted, it is logged.

  The image is the framebuffer's size, not the screen's, rows top first, its alpha opaque.

  A call before `InitWindow` fails.
- `ExportImageAsync`: Asynchronously writes an image to a PNG, QOI or raw file through `SaveFileDataAsync`, replacing raylib's `ExportImage`. See `ExportImageAsCodeAsync` for writing a C header.
  - `image`: The image.
  - `fileName`: The file; its extension chooses the format.
  - `done`: Optional. Called once the file is written, or once it is refused, at a later poll.
  - `failed`: Optional. Receives why it wasn't, such as an empty image or another extension; when omitted, it is logged.

  The file's extension chooses the format:

  - ".png": any uncompressed format. A format other than 8-bit grayscale, grayscale and alpha, RGB or RGBA is written as RGBA. - ".qoi": RGB or RGBA alone. - ".raw": the pixels as they are.

  The file is kept as `SaveFileDataAsync` keeps it. `TakeScreenshotAsync` writes a real file.
- `ExportImageAsCodeAsync`: Asynchronously writes an image as a C header through `SaveFileTextAsync`, replacing raylib's `ExportImageAsCode`. See `ExportImageAsync` for writing a PNG, QOI or raw file.
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

- `LoadImageAsync`: Loads an image file, answering when it is decoded: helix-raylib's own, in place of raylib's `LoadImage`, as the file is read later. A PNG, JPEG, BMP or TGA file is decoded by the platform, so it gives `PIXELFORMAT_UNCOMPRESSED_R8G8B8A8` whatever its channels, where raylib's gives a grayscale file grayscale; a QOI file gives its own channels, RGB or RGBA, as raylib's. A GIF file gives its first frame, `PIXELFORMAT_UNCOMPRESSED_R8G8B8A8`, as `LoadImageAnimAsync` gives it, and nothing after it is read; one with no frames, or broken before its first frame ends, fails to load.
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
- `LoadTextureAsync`: Loads an image file as a texture, answering when it is ready: helix-raylib's own, in place of raylib's `LoadTexture`, as the file is read later. The file is read as `LoadImageAsync` reads it, a GIF file's first frame among them, its reader chosen as the program builds as `LoadImageAsync`'s is. A file loaded again shares its first load's texture, and the image goes to the GPU when first drawn. The answer comes at a later frame, never during the call.
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

## VirtualGamepad

*class* in [`engines/raylib/src/helix/raylib/extras/VirtualGamepad.hx`](../src/helix/raylib/extras/VirtualGamepad.hx), `import helix.raylib.extras.VirtualGamepad;`

Provides on-screen gamepads for phones: sticks and buttons a finger works, read through raylib's gamepad functions. Imported apart, with its constants: `import helix.raylib.extras.VirtualGamepad.*;`.

The first touch anywhere on the screen plugs an enabled virtual gamepad in. A mouse click leaves the virtual gamepad unplugged. Once the virtual gamepad is plugged in, `IsGamepadAvailable` is true for its slot, and its sticks read through `GetGamepadAxisMovement` and its buttons through `IsGamepadButtonDown`, `IsGamepadButtonPressed` and `IsGamepadButtonReleased`. `IsGamepadVirtual` tells a virtual gamepad from a physical one.

A physical gamepad plugged into the virtual gamepad's slot replaces the virtual gamepad. The first physical gamepad plugged in takes slot 0. The next touch after the physical gamepad is unplugged plugs the virtual gamepad in again.

A free finger is a finger that is not currently captured. A stick captures a finger landing in its touch zone, and the buttons a finger landing on one of them. A free finger counts as the mouse, as every finger does without a virtual gamepad. The touch functions list every finger.

The virtual gamepad is drawn at `EndDrawing`, over everything the frame drew. On a device with touch, its buttons and fixed sticks are drawn from the moment it's enabled, and every other stick while it has captured a finger. A program drawing its own controls sets their `visible` to false and draws from `IsVirtualGamepadVisible`, `IsVirtualStickHeld`, `GetVirtualStickBase` and `GetVirtualStickKnob`. The virtual gamepad is hidden while a physical gamepad is in its slot.

```haxe
InitWindow(800, 450, "twin stick");
EnableVirtualGamepad(0);
while (!WindowShouldClose()) {
var moveX = GetGamepadAxisMovement(0, GAMEPAD_AXIS_LEFT_X);
var aimX = GetGamepadAxisMovement(0, GAMEPAD_AXIS_RIGHT_X);
// ...
}
```

```haxe
static inline var VIRTUAL_STICK_BASE_FLOATING:Int
static inline var VIRTUAL_STICK_BASE_FOLLOWING:Int
static inline var VIRTUAL_STICK_BASE_FIXED:Int
static inline var VIRTUAL_STICK_LEFT:Int
static inline var VIRTUAL_STICK_RIGHT:Int
```

- `VIRTUAL_STICK_BASE_FLOATING`: A stick whose base is where the finger lands. The base stays there while the stick is held.
- `VIRTUAL_STICK_BASE_FOLLOWING`: A stick whose base is where the finger lands. The base is pulled along when the finger moves past the radius.
- `VIRTUAL_STICK_BASE_FIXED`: A stick whose base stays at the fixed base position. A finger landing anywhere in the stick's touch zone pushes the stick from the base toward the finger. While no finger holds the stick, the stick is drawn at the base, the knob at rest.
- `VIRTUAL_STICK_LEFT`: The left stick, read as `GAMEPAD_AXIS_LEFT_X` and `GAMEPAD_AXIS_LEFT_Y`.
- `VIRTUAL_STICK_RIGHT`: The right stick, read as `GAMEPAD_AXIS_RIGHT_X` and `GAMEPAD_AXIS_RIGHT_Y`.

### virtual gamepad: on-screen sticks read as a gamepad's

```haxe
static function EnableVirtualGamepad(gamepad:Int, ?options:VirtualGamepadOptions):Void
static function DisableVirtualGamepad(gamepad:Int):Void
static function IsGamepadVirtual(gamepad:Int):Bool
static function IsVirtualGamepadVisible(gamepad:Int):Bool
static function IsVirtualStickHeld(gamepad:Int, stick:Int):Bool
static function GetVirtualStickBase(gamepad:Int, stick:Int):Vector2
static function GetVirtualStickKnob(gamepad:Int, stick:Int):Vector2
```

- `EnableVirtualGamepad`: Enables a virtual gamepad in a slot. The first touch after enabling plugs the virtual gamepad in. Enabling it again applies the new options. Its held sticks and buttons, and whether it's plugged in, stay as they were.
  - `gamepad`: The slot, 0 to 3.
  - `options`: Optional. Its sticks, its buttons and their look. Two floating sticks, on the screen's left and right halves, when omitted.

  ```haxe
  EnableVirtualGamepad(0, {
  right: {enabled: false},
  buttons: [{button: GAMEPAD_BUTTON_RIGHT_FACE_DOWN}, {button: GAMEPAD_BUTTON_RIGHT_FACE_RIGHT}]
  });
  ```
- `DisableVirtualGamepad`: Disables the virtual gamepad in a slot, unplugging it. A physical gamepad in that slot is unaffected.
  - `gamepad`: The slot, 0 to 3.
- `IsGamepadVirtual`: Returns whether the gamepad in a slot is a virtual one (`EnableVirtualGamepad`).
  - `gamepad`: The slot, 0 to 3.
  - returns: True while a virtual gamepad is plugged in there. False for a physical one or an empty slot.
- `IsVirtualGamepadVisible`: Returns whether the virtual gamepad in a slot is drawn: enabled, on a device with touch, with no physical gamepad in its slot. A program drawing its own sticks (`visible: false`) draws them while this is true.
  - `gamepad`: The slot, 0 to 3.
  - returns: True while drawn.
- `IsVirtualStickHeld`: Returns whether a finger holds a stick of the virtual gamepad in a slot.
  - `gamepad`: The slot, 0 to 3.
  - `stick`: `VIRTUAL_STICK_LEFT` or `VIRTUAL_STICK_RIGHT`.
  - returns: True while held.
- `GetVirtualStickBase`: Returns where a stick's base is, in the screen's pixels. While the stick isn't held, the base is at the stick's home: the fixed base position, or one and a half radii in from the touch zone's bottom outer corner.
  - `gamepad`: The slot, 0 to 3.
  - `stick`: `VIRTUAL_STICK_LEFT` or `VIRTUAL_STICK_RIGHT`.
  - returns: The base's center. (0, 0) without a virtual gamepad in the slot.
- `GetVirtualStickKnob`: Returns where a stick's knob is, in the screen's pixels: under the finger, held within the radius of the base. While the stick isn't held, the knob is at the base.
  - `gamepad`: The slot, 0 to 3.
  - `stick`: `VIRTUAL_STICK_LEFT` or `VIRTUAL_STICK_RIGHT`.
  - returns: The knob's center. (0, 0) without a virtual gamepad in the slot.

## Window

*class* in [`engines/raylib/src/helix/raylib/extras/Window.hx`](../src/helix/raylib/extras/Window.hx), `import helix.raylib.extras.Window;`

Provides the async versions of raylib 5.5's window, cursor, clipboard and screenshot calls (rcore), helix-raylib's own, as each answers later: `SetWindowSizeAsync` for `SetWindowSize`, `ToggleFullscreenAsync` for `ToggleFullscreen`, `GetClipboardTextAsync` for `GetClipboardText` and the rest. raylib's own call doesn't compile and names the one here (docs/DECISIONS.md 24, 38). Imported apart: `import helix.raylib.extras.Window.*;`.

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

- `ToggleFullscreenAsync`: Asynchronously asks for fullscreen, or for the window back at the size and place it had. See `ToggleBorderlessWindowedAsync` for the borderless window, replacing raylib's `ToggleFullscreen`.
  - `done`: Optional. Called once the window has changed, or once it is refused, at a later poll.
  - `failed`: Optional. Receives why it was refused; when omitted, it is logged.

  It may wait for the next key press, click or tap, or be refused.

  Called while borderless, it only switches to fullscreen.

  `IsWindowFullscreen` reports the new state once the window has changed, not when the call returns.
- `ToggleBorderlessWindowedAsync`: Asynchronously asks for the window to fill the screen without borders, or back to the window. See `ToggleFullscreenAsync` for fullscreen, replacing raylib's `ToggleBorderlessWindowed`.
  - `done`: Optional. Called once the window has changed, or once it is refused, at a later poll.
  - `failed`: Optional. Receives why it was refused; when omitted, it is logged.

  The window fills the screen without borders.

  It may wait for the next key press, click or tap, as `ToggleFullscreenAsync` may.

  Called while fullscreen, it only switches to borderless.

  As in raylib, `IsWindowState(FLAG_BORDERLESS_WINDOWED_MODE)` is true while it is, and `IsWindowFullscreen` false.
- `SetWindowSizeAsync`: Asynchronously asks for the window's size, replacing raylib's `SetWindowSize`. See `SetWindowMinSizeAsync` and `SetWindowMaxSizeAsync` for limiting how small or large it can be.
  - `width`: The width, in pixels.
  - `height`: The height, in pixels.
  - `done`: Optional. Called once the window has a size from the request, or once it is refused, at a later poll.
  - `failed`: Optional. Receives why it wasn't resized; when omitted, it is logged.

  The window manager may give another size. `GetScreenWidth` and `GetScreenHeight` report it once it has.

  Refused while the window is fullscreen or maximized, and where the system doesn't allow it.

  A size under 1 pixel is refused.
- `SetWindowPositionAsync`: Asynchronously asks for the window's place on the desktop, replacing raylib's `SetWindowPosition`. See `SetWindowMonitorAsync` for moving it to another monitor.
  - `x`: The left edge, in pixels.
  - `y`: The top edge, in pixels.
  - `done`: Optional. Called once the window has moved, or once it is refused, at a later poll.
  - `failed`: Optional. Receives why it didn't move; when omitted, it is logged.

  Refused while the window is fullscreen or maximized, and where the system doesn't allow it, as Wayland doesn't.
- `SetWindowMonitorAsync`: Asynchronously asks for the window on another monitor, replacing raylib's `SetWindowMonitor`. See `SetWindowPositionAsync` for placing it on the desktop.
  - `monitor`: The monitor, 0 to `GetMonitorCount() - 1`.
  - `done`: Optional. Called once the window is on the monitor, or once it is refused, at a later poll.
  - `failed`: Optional. Receives why it isn't, such as a monitor that isn't there; when omitted, it is logged.

  Where the window can't be moved, a monitor other than its own is refused.
- `MaximizeWindowAsync`: Asynchronously asks for the window maximized, replacing raylib's `MaximizeWindow`. See `RestoreWindowAsync` for bringing it back.
  - `done`: Optional. Called once the window is maximized, or once it is refused, at a later poll.
  - `failed`: Optional. Receives why it wasn't; when omitted, it is logged.

  Refused where the system can't maximize the window.
- `MinimizeWindowAsync`: Asynchronously asks for the window minimized, replacing raylib's `MinimizeWindow`. See `RestoreWindowAsync` for bringing it back.
  - `done`: Optional. Called once the window is minimized, or once it is refused, at a later poll.
  - `failed`: Optional. Receives why it wasn't; when omitted, it is logged.

  Refused where the system can't minimize the window.
- `RestoreWindowAsync`: Asynchronously asks for the window back to its size from minimized or maximized, replacing raylib's `RestoreWindow`. See `MaximizeWindowAsync` and `MinimizeWindowAsync` for changing it.
  - `done`: Optional. Called once the window is restored, or once it is refused, at a later poll.
  - `failed`: Optional. Receives why it wasn't; when omitted, it is logged.

  A minimized window is restored from minimized, any other from maximized.
- `SetWindowFocusedAsync`: Asynchronously asks for the window brought to the front with the keyboard, replacing raylib's `SetWindowFocused`.
  - `done`: Optional. Called once the window has the keyboard or the window manager keeps it elsewhere, at a later poll.
  - `failed`: Optional. Receives why it hasn't; when omitted, it is logged.

  A window manager may only flash it.
- `SetWindowOpacityAsync`: Asynchronously asks for the window's opacity, replacing raylib's `SetWindowOpacity`.
  - `opacity`: From 0 (clear) to 1 (opaque).
  - `done`: Optional. Called once the window has the opacity, or once it is refused, at a later poll.
  - `failed`: Optional. Receives why it hasn't; when omitted, it is logged.

  A desktop without a compositor refuses it.
- `SetWindowMinSizeAsync`: Asynchronously asks for the smallest size the window may take, replacing raylib's `SetWindowMinSize`. See `SetWindowMaxSizeAsync` for setting the largest.
  - `width`: The width, in the screen's pixels.
  - `height`: The height.
  - `done`: Optional. Called once the window has the limit, or once it is refused, at a later poll.
  - `failed`: Optional. Receives why it hasn't; when omitted, it is logged.

  Refused where the system doesn't allow it.

  A size under 0 pixels is refused.
- `SetWindowMaxSizeAsync`: Asynchronously asks for the largest size the window may take, replacing raylib's `SetWindowMaxSize`. See `SetWindowMinSizeAsync` for setting the smallest.
  - `width`: The width, in the screen's pixels.
  - `height`: The height.
  - `done`: Optional. Called once the window has the limit, or once it is refused, at a later poll.
  - `failed`: Optional. Receives why it hasn't; when omitted, it is logged.

  Refused where the system doesn't allow it.

  A size under 0 pixels is refused.
- `DisableCursorAsync`: Asynchronously locks the mouse to the window and hides the cursor, for looking around, replacing raylib's `DisableCursor`. See `EnableCursorAsync` for letting it go.
  - `done`: Optional. Called once the mouse is locked, or once it is refused, at a later poll.
  - `failed`: Optional. Receives why it wasn't; when omitted, it is logged.

  `GetMouseDelta` keeps coming while the position goes on past the window's edges.

  `IsCursorHidden` is true from the call.

  The lock may wait for the next click or key press, or be refused.
- `EnableCursorAsync`: Asynchronously lets go of the mouse that `DisableCursorAsync` locked and shows the cursor, replacing raylib's `EnableCursor`.
  - `done`: Optional. Called once the mouse is let go, at a later poll.
  - `failed`: Optional. Receives why it wasn't; when omitted, it is logged.

  `IsCursorHidden` is false from the call.
- `SetClipboardTextAsync`: Asynchronously puts text on the system's clipboard, replacing raylib's `SetClipboardText`. See `GetClipboardTextAsync` for reading it.
  - `text`: The text.
  - `done`: Optional. Called once the text is on the clipboard, or once it is refused, at a later poll.
  - `failed`: Optional. Receives why it isn't; when omitted, it is logged.

  It may be refused unless it comes soon after a key press.
- `GetClipboardTextAsync`: Asynchronously reads the clipboard's text, replacing raylib's `GetClipboardText`. See `GetClipboardImageAsync` for reading an image.
  - `read`: Receives the text at a later poll; "" when the clipboard holds none.
  - `failed`: Optional. Receives why it couldn't be read; when omitted, it is logged.

  It may need permission, which the system may ask for.
- `GetClipboardImageAsync`: Asynchronously reads the clipboard's image, replacing raylib's `GetClipboardImage`. See `GetClipboardTextAsync` for reading text.
  - `loaded`: Receives the image once it is decoded, `PIXELFORMAT_UNCOMPRESSED_R8G8B8A8`.
  - `failed`: Optional. Receives why there is none, or why it couldn't be read; when omitted, it is logged.

  It may need permission, which the system may ask for.
- `TakeScreenshotAsync`: Asynchronously takes a screenshot of the next frame and saves it as a file, replacing raylib's `TakeScreenshot`. See `LoadImageFromScreenAsync` for the screen as an `Image`.
  - `fileName`: The file's name, or its path; a name with `'` is refused, as raylib's is.
  - `done`: Optional. Called once the file is written or downloaded, or once it is refused, at a later poll.
  - `failed`: Optional. Receives why it wasn't; when omitted, it is logged.

  The name's extension picks the format, as `ExportImageAsync` does: ".png", ".qoi" or ".raw". Any other is refused.

  It is written where the name says, as raylib 6.2 writes it. A relative name is under the working directory, its directories kept. An absolute one is where it is.

  A directory that isn't there isn't made, and the screenshot is refused.

  Taken as the next frame ends, not from the frame drawn last as raylib's is.

  The image\'s alpha is opaque, as raylib's is.

  Refused before `InitWindow`.
