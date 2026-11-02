# Conventions

Rules for the libraries' public API, their examples, and the agents working on them. Names are predictable from what they do, so code
and agents can find an API before reading it.

## No backward compatibility

There are no users to protect. When an API changes, every caller changes with it in the same commit: examples, tests and tools.
Nothing keeps an old name, an old signature or an old behavior alive beside the new one: no aliases, deprecated wrappers,
compatibility flags or shims.

## Platform and services are constructed

Platform and services offer classes a program makes: adapters, services, caches, timers. Nothing in them is a static that builds a
service when first touched, installs itself into a loop, or is bundled with everything else, so a program carries only what it
constructs, and `-dce full` drops the rest. A thing a program makes for itself is an ordinary class with instances; what several of
them share is passed in, not reached for.

The layers above (the runner, an engine wearing a known API) may own the loop, and build a feature when its API is first touched where
the API they match requires it. A game on them carries what it uses (DECISIONS 15).

## A program links only what it names

What a program carries is what `-dce full` can't prove unused, so a library is written for the compiler to see what each program uses
(DECISIONS 30):

- **A library chooses an implementation from what the program wrote,** never from a string, an extension or an enum value the program
  passes as it runs. Readers, decoders, codecs, cache policies and sources are classes the program constructs and passes in, or
  functions it calls by name: `Models.loadGltf`, not a load that reads the extension and so carries every reader.
- **An optional collaborator is reached only from the call that asks for it.** Code that always runs (a poll, a frame's end) holds a
  hook that call installs, never a typed field it tests for null: a typed field links its class, and the class all it reaches.
  helix-ray's frame keeps `Frame.ended`, which `Runtime.screenshots` adds to; its poll calls `Runtime.dropping`, which
  `DroppedFiles` sets in its `__init__` when the program names `IsFileDropped` or `LoadDroppedFiles` (from the program's start, as
  raylib reads every drop).
- **Nothing inspects a value's type as the program runs** (`Type`, `ValueType`, `haxe.rtti`, `js.Boot.getClass`) outside tools and
  macros, and nothing in a library is marked `@:keep`, which links it into every program that types it. Where an API takes a value
  of no type (parsed JSON, raylib's `void *` and varargs), `Std.isOfType` tests it against the few kinds it can be.
- **A layer wearing an API that chooses as the program runs narrows the choice as the program builds.** raylib's `LoadModel` reads
  the file's extension; helix-ray's `LoadModelAsync` is a macro that, given a constant name, calls that extension's reader alone
  (DECISIONS 29), and chooses as the program runs only for a name it can't know.

`tools/measure_sizes.py --check` holds the size ladders to it: each rung's `Main` declares in `@:adds` the library packages, modules
or classes it adds, and a rung linking a library class no rung up to it declares, a declaration it doesn't link, run-time type
inspection, or a library's `@:keep` fails, read from the build's `-xml` and a macro (`tools/haxe/Kept.hx`).

Known, not fixed yet (each a rung's `@:adds` or a program's bytes show):

- helix-services' `Models.load` chooses its reader by the extension (`loadGltf` and `loadObj` don't).
- helix-services' `Assets` takes its sources as an enum (`AssetSource`) and its cache policy as one (`AssetCacheMode`), so a program
  reading only a file system links the server's downloading, manifests and cache.
- helix-services' `Screen` tests its saves each poll, so a program with a screen links `Saves`; helix-ray's poll tests its keyboard,
  so every raylib program links `Keyboard`.
- helix-ray's `Runtime.fetch` decodes a file by its extension, so a program loading text or data through it links the image
  decoder; its `LoadImageFromMemoryAsync` and `LoadMusicStreamFromMemory` choose by their `fileType`, as raylib's do, and
  `LoadWaveAsync` and `LoadWaveFromMemoryAsync` by a name or type known only as the program runs; and in a page its assets are made
  over the server and its cache whatever a program loads.
- helix-platform's `WebAudioDecoderAdapter` reads a file's rate from its header for `decode` at rate 0, so a program asking for
  44100 links helix-formats' `AudioHeader.readSampleRate` too.

## Names

The API uses what Haxe gives: properties for values, classes for kinds, methods named for what they do. The earlier C frameworks' rules
(a method for everything, so a binding could be made of it; a type field instead of a class) were theirs, not Haxe's, and were dropped
.

| Kind | Form | Example |
| --- | --- | --- |
| A value | a property, read and assigned | `window.title = "Asteroids"`, `time.scale = 2`, `voice.volume = 0.5` |
| Several values set at once | `setX(...)` | `node.setPosition(x, y, z)` |
| A state now (a bool) | an adjective property | `time.paused`, `audio.running`, `files.canWrite` |
| A state asked with an argument | `isX(...)` | `gamepads.isButtonDown(0, South)`, `input.isDown(Key.A)` |
| Whether something is there | `hasX(...)`, naming what it looks for; never a bare `has` | `saves.hasKey("level")`, `config.hasOption("speed")` |
| Whether an action is possible here, so whether to offer it | `canX()` | `window.canMove()`, `window.canClose()` |
| Ask for what the platform may refuse or grant later | `requestX(...)` | `window.requestFullscreen(true)`, `window.requestSize(800, 600)` |
| An action | a verb | `window.close()`, `audio.stop(voice)`, `assets.load(path, done)` |
| A count or a limit | a property naming what it counts, ending in `Count`; an array of counts ends in `Counts`; the limit first | `events.padCount`, `graphics.msaaSampleCount`, `graphics.maxMsaaSampleCount`, `wav.channelCount` |
| An index | a property naming what it indexes, ending in `Index`; an array of indices ends in `Indices`. A mesh's vertex indices stay `indices`, as glTF and raylib name them | `GltfNode.meshIndex`, `GltfMaterial.baseColorImageIndex`, `Model3D.meshMaterialIndices`, `Mesh3D.indices` |
| Fill what it's given | a verb, not a property | `camera.computeRay(x, y, ray)`, `node.computeWorld(out)` |
| A command for what follows in a pass | `applyX(...)` (sokol's word) | `graphics.applyViewport(...)`, `graphics.applyScissor(...)` |
| A call made on its own, answering no request | an `onX` property, null for none; never a method | `window.onClose = save` |
| Remove one or all | one verb, the noun singular and plural, or `X` and `XAll` for a verb of its own; never a bare `clear()`. A value made empty is `makeEmpty()` | `files.deleteFile(path)` and `deleteFiles()`, `saves.deleteKey(key)` and `deleteKeys()`, `actions.unbind(...)` and `unbindAll()`, `bounds.makeEmpty()` |

- **A parameter holding a count or an index is named as such a property would be:** `window.getMonitorX(monitorIndex)`,
  `Mesh3D.fromSphere(radius, sliceCount, stackCount)`, `gltf.setBuffer(bufferIndex, bytes)`. A handle, an id or a slot is neither, and
  keeps its own noun (`audio.stop(voice)`, `gamepads.getAxis(slot, axis)`, `touch.getX(id)`); a number of bytes is a size, named for
  its unit (`capacityBytes`, `usedBytes`). `tools/check_names.py` checks every field and parameter whose doc comment calls it an index
  or a number of things.
- **A value is a property.** One that must act when assigned has a `set_` accessor; one read back from somewhere else has a `get_`;
  one nothing may assign is `(default, null)`. A record made whole and never changed after (`Touch`, a parsed header, a progress
  report) shows `final` fields. Nothing public is a bare `var` that something else keeps in step by hand.
- **A property clamps; a method may refuse.** Assigning can't answer, so a property takes what it's given, held to its range, and its
  doc comment says the range. Whatever can be refused or decided later is a method returning `Bool`: `requestSize`, `add`, `load`'s
  result.
- **`request` returns whether it asked, not whether it was granted.** The result comes later, to its lambdas: `done` when granted,
  `failed` with the reason when refused. They are optional; a caller that doesn't need the result passes neither. `can` says whether
  to offer the request at all.
- **A value-like type's method that changes it returns it,** so calls chain: the math types and `Image`
  (`bounds.makeEmpty().expand(x, y)`, `transform.yaw(turn).moveForward(step)`, `image.grayscale().contrast(20)`). One that can refuse
  at once returns `Bool` instead, and doesn't chain. A command on a service or a device (a platform contract, `Audio`, a `Voice`,
  `graphics.applyViewport`) returns `Void`, or `Bool` when it can refuse: chaining side effects gains nothing.
- **A value type's operations write into an optional out, last, and return it:** `a.add(b, ?out)`, `v.normalize(?out)`,
  `m.append(other, ?out)`. Omitted, it makes a new value and leaves its own unchanged; given the object itself, it works in place
  (`v.normalize(v)`), so an operation has one name and no in-place twin, and calls chain through the out (`a.add(b, a).scale(2, a)`).
  The out may be any of the inputs: each is read before anything is written. Only what changes the object's state rather than making
  a value is a plain verb on it (`set`, `copyFrom`, `makeEmpty`, `transform.yaw`). A value an operation may not have returns null,
  out unchanged (`m.invert(?out)` for a matrix with no inverse).
- **A value type's other methods are named for what they return.** A static `fromX(..., ?out)` builds one from what it's given
  (`Matrix3D.fromPerspective`, `Quaternion3D.fromAxisAngle`); a blend or a composition of others is a static named for it
  (`Vector3D.lerp(a, b, amount, ?out)`, `Matrix3D.compose(first, second, ?out)`). `toX(?out)` converts one into another kind
  (`rotation.toMatrix()`) and `computeX(?out)` derives a value from it (`transform.computeForward()`). A number it has is a property
  (`vector.length`).
- **A completion takes a lambda per outcome, success first,** and on a platform contract none is optional (`read(path, maxBytes,
  loaded, missing, failed)`): one of them is called once, on the main thread, never during the call; a cancelled request calls
  nothing. A service above may make the failure's lambda optional, logging what it was given with the path, so nothing fails
  silently. No result enum to switch on.
- **Kinds are classes.** A class holds only its kind's data; what acts on it is a method or a service that takes it. Nothing is found
  by reflection at run time.
- **One concept, one name across types:** a sprite's part of its texture is its region everywhere (`regionX`, `regionWidth`), not a
  region here and a source there.
- **Adapter classes are `<Api><Contract>Adapter`**, words the API's name ends with and the contract's starts with written once
  (`WebAudioAdapter`, not `WebAudioAudioAdapter`); ARCHITECTURE.md has the directories, and `tools/check_adapters.py` checks both. A
  contract whose adapters differ only by the target they run on names the target instead of the API (`BrowserFileSystemAdapter`,
  `NativeFileSystemAdapter`), since that is what a reader picks it by.
- **An adapter's constructor takes nothing, or one `<Adapter>Options`:** a `@:structInit` class beside it, so every value is named at
  the call (`new NativeFileSystemAdapter({directory: path, readOnly: true})`). A value it must have is a field without a default; one it
  may have declares its default in the field. A choice is an enum (`{graphics: Gl}`), never a `Bool` whose `false` means the other one.
  The compiler refuses a field the class doesn't have, so a guessed setting fails to build rather than doing nothing; for the same
  reason, every field takes effect whatever the others are set to. `tools/check_adapters.py` checks the shape and the name.
- **An argument or option is named for what it's used for** when that's more than its type says: `Assets`' `cacheFileSystem` is the
  `IFileSystem` downloaded copies are kept in, its `httpClient` the `IHttp` it downloads with. One that is simply the contract keeps
  the contract's name (`system`, `events`).
- **A directory is a directory,** as Haxe's standard library names it (`FileSystem.readDirectory`, `Path.directory`) and as programming
  APIs generally do: in names, doc comments and docs, never "folder" (the desktop's word) or "dir" (an abbreviation):
  `getProgramDirectory`, `assetDirectory`. Only a third party's own name keeps its word.
- **2D and 3D are named apart, always:** a type of one kind ends in its kind, whether or not the other kind has a counterpart yet
  (`Vector2D` and `Vector3D`, `Bounds2D` and `Bounds3D`, and as much `Mesh3D`, `Camera2D`), so no one guesses which kind a name means,
  and a counterpart arriving later renames nothing. That holds for a type that belongs to one of a kind, and for a family named by a
  file of one kind. Only what holds both kinds or neither keeps a plain name: a file format, a type both kinds use, which is
  neutral and lives outside them in the package of its own domain. The kind ends the name (`LayoutDirection2D`, not
  `Layout2DDirection`). `tools/check_names.py` checks it, its lists of the plain ones each giving the reason.
- **A method computing a value object takes an optional out last and returns the result:** `node.computeBounds()` makes new bounds,
  `node.computeBounds(scratch)` fills scratch and returns it, null meaning there's nothing, not a Bool beside the out. Given an out, it
  allocates nothing, so per-frame code can call it freely; without one it allocates exactly the result. Haxe skips an optional
  argument a value doesn't fit, so an out can follow another optional one unsaid.
- **A package is named for what it holds: plural when it holds many things of one kind, each a peer; singular when it is one field.**
  Said aloud, "the ___ package holds…" decides it. Plural: `helix.platform.adapters` (one adapter per API), `helix.platform.tools`,
  `helix.platform.macros`. Singular: `helix.platform`, `helix.math`, `helix.log`, `helix.asset`, `helix.audio`, `helix.input`, as
  .NET's guidelines have it (`System.Collections`, `System.IO`). A package under a plural one is again named for itself. What a domain
  holds lives in its package, not the package of whoever uses it first.
- **A package's main type may share its name** (`helix.log.Log`), which .NET's guidelines avoid: in C# a namespace and a type are one
  set of names and can be mistaken for each other, but in Haxe a package is lowercase and a type capitalized, so they never can.
- **A type is named plural when it hands out many of one kind, singular when it is one thing:** `Assets`, `Timers`; `Audio`, `Log`.
- **An exception type ends in `Exception`** and extends `haxe.Exception`: `GraphicsUnavailableException`, `CommandException`.
- **What holds something releases it with `dispose()`:** an object, a service or a cache, a contract's resource by kind
  (`IGraphics.disposeTexture`, `IAudio.disposeClip`), and the libraries' own C (`helix_dispose`), as .NET, OpenFL, Lime and Heaps name
  it. Nothing is named `destroy`, `cleanup` or `shutdown`. `close` is kept where `open` is its pair (`IWindow.close`, a device's
  `helix_audio_open` and `helix_audio_close`); a third party's names (`sg_shutdown`, `SDL_DestroyGPUDevice`) stay theirs.
- **Capitals:** `2D` and `3D` keep a capital D. Every acronym, abbreviation and product name in a name is written as a word, its first
  letter alone a capital, as Haxe's standard library writes them (`haxe.Json`, `haxe.Http`, `Xml`, `Utf8`, `Md5`): `Ui`, `Gpu`, `Url`,
  `id`, `Sdl3`, `Dom`, `WebGl2`, `IndexedDb`. No length decides it and no name is an exception, so any name can be written without
  looking it up. Prose keeps a product's own spelling (WebGL2, IndexedDB, SDL3).

## Units

One unit per kind of value across the API, so nothing has to be converted at a call:

- **Angles are radians.** A positive angle turns from +x toward +y: clockwise on screen in 2D, where y grows downward. 3D is
  right-handed with +y up.
- **Time is seconds**, as a `Float`, from the platform's monotonic clock (`ISystem.getTime`). A value in another unit says so in its
  name (`budgetMs`) or, where the name can't, in its doc comment.
- **Colors are `0xAARRGGBB`** integers, alpha in the top byte, as Haxe's libraries write them and as an editor's color picker reads a
  literal; `helix.math.Color` gets and sets their channels, and mixes, blends and converts them. Text writes a color the CSS way, `#RRGGBB` or `#RRGGBBAA`, converted
  by `Color.fromRgba` and `toRgba`.
- **A simulation that must play alike on every target** (a replay, lockstep, physics) takes its trigonometry from `helix.math.Trig`,
  never `Math`'s `sin`, `cos`, `tan`, `atan2`, `asin`, `acos`, `exp` or `log`, which differ in the last bit between the browser and
  native. Arithmetic, `sqrt`, `floor` and `pow` agree. Drawing may use `Math`.
- **Positions and sizes name their space** in the doc comment: framebuffer pixels (`IWindow`'s framebuffer size, the pointer), logical
  pixels (the window), or world units (a camera's).

## Layout and documentation

Code is written to be read, by people and agents, not packed.

- **Formatted by the tool, not by hand.** Haxe source is laid out by haxe-formatter (`formatter` on lib.haxe.org) with the repository's
  `hxformat.json`: one statement per line, indented blocks. Formatting is checked with the other checks, so dense one-line classes and
  functions don't come back.
- **Every public type and member has a doc comment** (`/** ... */`), written as reference documentation. Private code gets a comment
  where the reason isn't plain from the code.
- **Doc comments follow C#'s XML documentation conventions, in Haxe's tag syntax.** The structure and the voice are C#'s; the tags are
  the Javadoc-style ones dox and `tools/gen_apidoc.py` read:

  | C# | Here |
  |---|---|
  | `<summary>` | the first paragraph |
  | `<param name="x">` | `@param x` |
  | `<returns>` | `@return` |
  | `<value>` (a property) | the first line |
  | `<remarks>` | the paragraphs after the tags |
  | `<example>` | a fenced code block in the remarks |
  | `<exception>` | `@throws` |
  | `<see cref="X"/>` | `` `X` `` |

  - **The summary** is one sentence, standing alone (completion and the reference's index show it alone). A method starts with a
    third-person verb: "Returns ...", "Sets ...", "Finds ...", "Adds ...". A property: "Gets or sets the ...", "Gets the ..." when
    read-only, "Gets or sets a value indicating whether ..." for a Bool; its unit, range and default follow. A class: "Represents a
    ...", or "Provides ...". An interface: "Defines ...". An enum: "Specifies ...".
  - **The parameters and the return** come last in the source, after the remarks (Javadoc's order: dox reads a tag's text up to the
    next tag, so text after a tag would be taken as its), one per line, in order; the reference renders them under the summary. A
    parameter is a noun phrase: "The x coordinate, in framebuffer pixels from the left." An optional parameter starts "Optional." A
    return: "The node, or null if there is none."; a method that can refuse: "False when ...". A property has neither.
  - **The remarks** are plain paragraphs, impersonal, present tense: how it is used (a class: the sequence of calls), what is skipped
    or ignored, what state it reads, limits, and a fenced example where a call's shape isn't obvious from its signature. A fact that
    changes what the reader does belongs here ("A browser plays no sound until the player has pressed a key."); the design's reasons,
    its history and comparisons to other frameworks don't (DECISIONS holds those).
  - **Standard words.** Never "you". "Optional", "provided", "omitted", "receives", "defaults to", "must be", "skipped", "ignored",
    "clamped to", "unchanged", "local units", "its subtree": not "when given", "left out", "held to", "says", "as it was", "the node's
    own units", "what's under it".
  - **Sample**, `IFileSystem.read`:

        /** Reads a whole file.

            @param path  The file's path under the root.
            @param maxBytes  The largest file to read; a larger one fails.
            @param loaded  Receives the file's bytes.
            @param missing  Called when there is no file at the path.
            @param failed  Receives why it can't be read.
            @return  The abort: nothing is called after it. */

  `tools/gen_apidoc.py` renders the tags as a list under the summary, the remarks after.
- **Generated API documentation.** The doc comments are the API reference: dox (`dox` on lib.haxe.org) generates it from them, so what
  a developer or an agent reads is what the code says; `docs/api/<library>.md` is the same, committed, checked by `gen_apidoc --check`,
  and the platform's adapters, each one target's, are together in `docs/api/platform-adapters.md`, each marked with its target.
- **Each library's reference is what its own users write against, and nothing else.** A developer or an agent given only the
  reference and a hello world should be able to build any program, and not be put off by machinery. Haxe has no internal, so what
  another package of a library must reach is public, and the library's own is marked:
  - helix-platform's users are programs and engines built on it: they construct its adapters and call its contracts
    (`WebGl2GraphicsAdapter`, `IGraphics`, `IFileSystem`), so those and the types they take are shown, and only its C bridges
    (`internal/`) and shared helpers (`adapters/shared/`) are marked; `tools/check_adapters.py` holds both.
  - **A type a library's users never make, name, set or get back** carries `@:noCompletion`: out of the language server's completion
    and out of the reference (dox and `tools/gen_apidoc.py` skip it). It still compiles when named.
  - **A class only the library calls** also takes `@:allow(helix)` and leaves its members private (no `public`), so a user can't call
    it at all; a member implementing an interface stays public, as Haxe requires. Tests and tools outside `helix` say so with
    `@:access(helix)` on their classes.
  - **A member only the library uses, on a type its users do use**, carries `@:noCompletion` itself.
  - **A type a user meets is shown, however internal it looks:** what a load returns, what a callback is handed, what a user overrides,
    a base used through its subclasses.
  - **A shown type is a file of its own**, so a user imports it by the path the reference gives: Haxe finds a type in another type's
    file only through that file's module, which no one guesses. A family gets a package; a hidden helper may share its user's file.
  - **Checked:** `gen_apidoc` fails when a shown type is in another type's file, and when a shown member's signature names a hidden
    type, but for an optional argument a user leaves out; `check_adapters` requires the marks on the platform's bridges and helpers and
    their absence on its contracts and adapters. A new type is marked when it's added; when unsure, ask whether a user would name it.

```console
python3 tools/format.py         # lay out the Haxe source; --check only checks
python3 tools/check_docs.py     # list public API without a doc comment, and docs naming what they mustn't
python3 tools/check_types.py    # every library, every target it supports, in seconds
python3 tools/gen_apidoc.py     # the API reference: docs/api (committed; --check in the tests) and build/api/index.html
```

- **Tools are named for what they are:** a runnable tool is verb_noun, words apart by underscores (`check_types.py`,
  `measure_sizes.py`); a `check_` tool only reports, a `gen_` tool makes files (committed ones), the rest do what they say. Every tool
  answers `--help` with its usage, from its docstring (a Node tool's leading comment), and does nothing else, and refuses an argument
  it doesn't take (`tools/cli.py`); a module the tools import says so when it's run. BUILDING.md names every tool, and
  `tools/check_tools.py` checks all of it. A module only imported by other tools is named for what it holds, a plain noun that can't
  read as a verb (`variants.py`, `pins.py`). Front doors keep their noun (`helix.py`). What a program runs is Haxe, on a library's
  class path under `helix.<library>.tools` (`helix.platform.tools.ShaderCompiler`), run in the compiler or its interpreter, so a program
  needs no Python, and never compiled into a program.
- **What a user runs needs only Haxe:** a library's examples build from hxml files beside them, so nothing else is installed to use a
  library. Python and Node are the repository's own checks (`tools/`), never in a user's path.

The formatter and dox are pinned in `dependencies.json` and installed into the repository's own haxelib (`build/haxelib`), as hxcpp is.

## Build

A build is named `<platform>-<config>-<backend>[-<option>...][-<sanitizer>]`, each part chosen from a fixed list, so a name says what
was built and where it is (`tools/variants.py` holds the lists).

- **platform:** what the program links against, this machine's for a native build: `linux-x64`, `linux-arm64`, `macos-arm64`,
  `macos-x64`, `windows-x64-msvc` (hxcpp's default on Windows; `windows-x64-mingw` would be MinGW's, not supported yet), and `js` for
  the browser.
- **config:** `debug` or `release`. `release` is what ships: full dead-code elimination, the analyzer's optimizations, Terser in the
  browser. `debug` finds faults: Haxe's `-debug` (a source map in the browser; natively hxcpp's debug runtime with stack lines and null
  checks), the standard dead-code elimination, no optimizer, and the adapters' C unoptimized with its assertions and sokol_gfx's
  validation on.
- **backend:** always named, never implied by the platform: the exact API the build draws with, `webgl2`, `sdl3-gl`, `sdl3-gpu`.
  `sdl3-gl` draws with sokol_gfx on GL; WebGPU's, when it comes, is `webgpu`. `sdl3-gpu` is SDL_GPU, whose driver (Vulkan, Direct3D 12,
  Metal) SDL picks as the program starts; a program chooses it by constructing `Sdl3GpuGraphicsAdapter` (`-D sdl_gpu` in the
  platform's examples). A `headless` backend (no window or GPU, for tests) is to come; none exists yet.
- **options**, then a **sanitizer**, in that order: a name only adds, never `-noX`. None exists yet.

## Tools

A tool that reads Haxe code (a generator, a check, the API reference) reads it as the compiler describes it, `haxe -xml` or a macro run
in the compile, never by matching its text: the compiler resolves types, parameters, metadata and doc comments as the code means them,
where a pattern breaks on the next arrow or generic it didn't foresee. `tools/gen_raylib.py` reads helix-ray's sections so, with a
macro (`tools/haxe/Fields.hx`) for the macro functions `-xml` leaves out. A tool still matching text is changed when it is next
touched.

## Examples

- An example shows one thing with its library alone, on both targets, from hxml files beside it. Work that a program would otherwise
  repeat belongs in a library; an example that has to do it by hand says so in its comment.
- An example declares each adapter with its contract's type, named for what the program uses it for: `var httpClient:IHttp = new
  HaxeHttpAdapter();`, `var shipped:IFileSystem = new NativeFileSystemAdapter({...})`, so a reader sees the adapter, the contract and
  its use on one line.
- Native checks that drive a window run on a private display (`tools/private_display.py`), never on the user's desktop: a new window
  takes the keyboard focus, so the user's typing would land in it.
