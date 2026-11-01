# Decisions

Why things are the way they are, numbered, in order.

1. **A library above the platform starts as its API, not a prose spec.** Its types and members with their doc comments are written
   first, agreed and tried before any implementation, and the doc comments are its spec. A prose spec says again what the doc comments
   say, and drifts from them: `IFileSystem`'s comments still said a page's root could be the server after docs/PLATFORM.md said
   otherwise, and two of the build trial's agents went looking for that file system. The same trial built every adapter right from the
   reference, the READMEs and the examples alone, with no spec.
2. **Each service is constructed on its own,** from the contracts it needs, as the platform's adapters are: no hub holding all six. A
   program carries only what it constructs. Both Opus agents of the build trial's second run did this; the Sonnet agent built a hub
   and said one each would fit better.
3. **An input action is named by a string:** `actions.bind("jump", Keyboard(Space), Pad(0, South))`, `actions.isPressed("jump")`. Names are what a settings file or a
   rebinding screen holds.
4. **Assets keeps its own cache on both targets,** IndexedDB in a page and the cache directory natively, with cache modes (revalidate by
   the host's Cache-Control, trust the copy, off) and manifests. The browser's HTTP cache gives revalidation alone, may evict a large
   file between runs, and would make a page behave apart from native; HeliX's assets found every mode necessary.
5. **A sound loads two ways:** decoded whole (`load`, for effects) or played as it's read (`stream`, for music), as HeliX had them.
6. **Saves writes at its poll:** `set` queues a change, and the next `poll` writes everything set that frame as one file, one write in
   flight at a time; `flush(done, failed)` starts the pending write at once, never blocking. A page's end (`IWindow.onClose`, at
   pagehide) can start a write that never finishes, so little is left pending for it.
7. **`Actions.bind` takes its bindings as a rest argument,** one call binding one or several. With one signature for one binding and
   another for an array, or an abstract taking either, Haxe can't resolve `Keyboard(Space)` without `Binding` imported, and the
   services trial's one compile failure was that import; with every argument a `Binding`, it resolves.
8. **Assets takes an options object:** `{sources, ?httpClient, ?cacheFileSystem}`. The HTTP client and the cache belonged to every
   server source and were passed to each; once, named where they're built, each reads as what it is. A source is `FileSystem(fileSystem)`
   or `HttpServer(url, ?cacheMode)`, each named for where the files are; the cache mode is the source's, as one server's
   files may be trusted while another's are revalidated.
9. **Movement is read as one capped vector:** `Actions.computeVector(left, right, up, down, ?out)`, its length held to 1, so a keyboard
   diagonal is no faster than a straight line and a stick pushed partway stays partway. Two of the services trial's agents read two axes
   and moved diagonals 1.41 times as fast. It puts helix-math under helix-services, which costs a program nothing it doesn't call.
10. **The wiring is the next layer's, not the services'.** Which adapter per target, who polls whom, and how a program ends with its
    save written are the same in every program the trials produced; by goal 1, what has to be explained before use is the API's to
    fix, and the services stay the pieces a game reads. What can be designed out of them is: `Input` reads the last `IEvents.poll`, so
    their order is free.
11. **A server's manifests make shipped files patchable.** A game that patches lists its server first and its shipped files after
    (`[HttpServer(url, Manifest), FileSystem(shipped)]`): online the server's version wins, offline or for a file the server doesn't have the
    shipped one answers. A shipped file its manifests list at the server's hash is read in place, so a first run downloads only what
    changed. The shipped tree carries the same manifests (`AssetManifests` writes both at once, as the same tree), since a file system
    has no size or time to keep a run-time hash honest, and hashing a file to stream it would read it whole. A server's manifests are a
    cache mode of its own (`Manifest`), not looked for by default: in a page every request for a manifest a server doesn't have is a
    404 in the console, which reads as an error, and a flag or bit field beside the mode would allow combinations that mean nothing
    (manifests with Off). A `Manifest` server without one is warned about and treated as Revalidate. The tree is HeliX's, wgrender-c's
    and libwgt's, where an unchanged directory is known from its parent alone. None of them seeded from
    shipped files; each read local files in place and never checked them.
12. **Each input device is a contract of its own,** built over the events: `IKeyboard`, `IMouse`, `ITouch`, `IGamepads` and `ITilt`,
    each adapter constructed over the events adapter of its API and adding to its one stream, so the order between devices is kept.
    A device a program doesn't construct isn't listened to, read or linked: tilt inside the one events contract had cost every page
    its code, and every page polled its gamepads. The services' devices take the stream and their platform device (`new
    Keyboard(events, keyboard)`), so the stream isn't offered under a device's name and a missing device fails at compile time. The
    first press stays the events' own, heard without any device. Natively the tilt is an SDL adapter that reports `Unavailable`: SDL
    reads motion sensors on Android, iOS and Windows, which a mobile build would take up.
13. **On-screen controls aren't a service.** `Touch` is the fingers as state, by id, as Flixel's `FlxTouch` is. A touch region (an
    on-screen button) and a floating touch stick, which HeliX bound in its actions, are placed in the game's units on its visible area,
    drawn, and kept clear of its buttons, none of which the services have; another engine would place and draw its own. Flixel keeps
    them in `flixel.ui` as sprites (`FlxVirtualPad`, `FlxVirtualStick`), and Lime and OpenFL have none. Where they go is open; reading
    `Touch` and implementing `IActionDevice`, they'd be read by `Actions` as the devices are. Taps, flicks and two-finger gestures
    interpret the fingers and come as their own service.
14. **Typed text is the platform's, and a text field isn't the services'.** Only the OS turns keys into characters (the layout, dead
    keys, an input method) and shows a phone's keyboard, so `Event.Text` and `IKeyboard.textInput` are the platform's, as Lime's
    `onTextInput` and `textInputEnabled` are. Typing a name in trial 8 needed more than a frame's characters: Backspace with its
    repeats, Enter to end, the game's keys left out meanwhile, which is a text field, a UI control (Flixel's `FlxInputText`). The
    services' `Keyboard` reads keys alone.

15. **Platform and services are constructed; the layers above may wear a known engine's API.** The libraries were split so an engine
    above gains their small size, and so a game on it needs no knowledge of them: it is written against an API agents were already
    trained on (GOALS 1), mirrored exactly where it is provided and missing, not altered, where it isn't, so a gap is a compile error. A
    mirrored API may need what platform and services refuse: owning the loop (a page calls its program each frame), or a hub every
    program touches (Flash's `stage`, Godot's `Input`) building a feature when first asked for it. So the rule that a program constructs
    what it uses binds platform and services, and the layers above carry what a game uses, through what it references. What the
    familiar API costs is measured by a size ladder against the same programs written on the services.

16. **raylib is the API to mirror first, as helix-ray.** A trial asked fresh agents to write one small game from memory against five
    engines' APIs (Godot 4, OpenFL with Away3D, Heaps, Pixi with three.js, raylib), each use checked against the real reference: all
    were 94% right or better, so memory didn't separate them; raylib (99.1%, 16 of 20 jobs written alike) combined the best memory
    with high agreement and a shape nearest ours (no stage or hubs, the program's own loop). helix-ray mirrors raylib 5.5 exactly, by
    raylib's names: a build macro runs raylib's `while (!WindowShouldClose())` as a frame in a page; the program's files are loaded
    before `main` so loads answer at once; raylib's GLSL is compiled as the program builds, for every backend. Three fresh agents wrote
    the game in 2D, then with a 3D view, from raylib knowledge alone: 0 to 2 compile errors each, every one a raylib function missing
    here (since added); all six played in a page and natively. It uses the services (input, time, saves, assets, audio, images) and
    helix-math (`Matrix3D`), and the platform for drawing. On trial on the branch `raylib-slice`, not merged.

17. **Images and Matrix3D go below the mirror.** What any engine would take as it is moved out of helix-ray: image files decoded into
    pixels became the services' `Images` (no GPU, so services still doesn't draw), and raymath's matrices became helix-math's
    `Matrix3D` (helix-math's style, rotations through `Trig`), both agreed as APIs and tried by fresh agents first. Drawing stays in
    helix-ray until a second consumer makes a drawing library worth its own place.

18. **The libraries are zlib, crediting what they stand on.** As raylib, SDL and sokol are: a built program owes no notice, a copy of
    the source keeps it, the disclaimer as MIT's. Each library carries its LICENSE, and others' licenses beside their code in a folder
    per project (`vendor/<project>/`), as each is published from its own directory; haxelib.json says BSD, as haxelib has no zlib. Each
    library's README credits what it includes (helix-platform: Sokol, SDL, SDL3_mixer, stb, dr_libs, the shader tools; helix-ray and
    helix-math: raylib, whose small guessable API is the work helix-ray is built on; helix-ray: par_shapes, for raylib's generated
    meshes), in place of a repository-wide notices file.

19. **helix-ray loads as raylib does, and says what a page can't.** raylib's loads answer at once and own what they load, with no
    sharing, deferred upload or async. helix-ray keeps the API and changes what it can underneath: a file loaded twice shares its GPU
    copy (textures, a model's meshes and textures, a decoded sound), freed by its last unload; textures and meshes go to the GPU at
    their first draw; natively each load reads its file when called. A page can't read synchronously, so it loads before `main` the
    files its program names (a string in its sources equal to a file's path, the files a named glTF points to, and the folders of
    `-D helix-ray-preload`), and a load of anything else refuses with how to bring it in. `LoadTextureAsync`, `LoadModelAsync`,
    `LoadSoundAsync` and `LoadFileTextAsync`, helix-ray's own, answer when ready on both targets, after which the plain load answers
    at once. Swapping a placeholder in under the plain loads was weighed and left out: sizes and bounds read at load would be the
    placeholder's (all three 3D trial agents fitted the camera to the model's bounds); placeholders belong to a managed layer, as
    librl has them. Every raylib and raymath function helix-ray lacks is a macro that refuses to compile, naming itself, so a program
    knows it remembered raylib right. The defines are helix-ray's: `helix-ray-files`, `helix-ray-native-root`, `helix-ray-preload`.

20. **A page's loads are asynchronous, said by the compiler.** DECISIONS 19's preload, files found by scanning the program's sources for
    their paths, guessed at build time what only a run knows: a file not preloaded may be in memory by its load, brought in by an
    earlier async load or the program's load callback, and a computed name was missed silently. Folders named for preloading, raylib's
    own way, still guessed. So a page build refuses `LoadTexture`, `LoadModel`, `LoadSound` and `LoadFileData` where they are written,
    "LoadTexture: Synchronous loading is not supported. See LoadTextureAsync()": short, naming the way, raising no new question.
    Natively they load at once, as raylib's do, and the `...Async` loads work on both, so a program for both uses them. A page reads
    nothing before `main` but the saves, when the program uses them; `LoadFileText` and `FileExists` still answer from the saves, and
    `LoadMusicStream` streams. Faking synchronous loads in a page, which would let raylib code build for it unchanged, waits for a
    trial of how agents take to the async loads (ROADMAP).

21. **raylib's synchronous reads don't compile on any target.** DECISIONS 20 refused them in a page alone, so a program that built
    natively failed when built for a page: one program, two codes. Now `LoadTexture`, `LoadModel`, `LoadSound`, `LoadFileData`,
    `LoadFileText` and `FileExists` refuse everywhere, with the signature of the call to use, "LoadTexture: Synchronous loading is not
    supported. See LoadTextureAsync(fileName:String, loaded:Texture2D->Void, ?failed:String->Void)", so an agent needn't look it up.
    Each is a macro in `Raylib` whose body returns `helix.platform.macros.Build.unsupported(message, macro (null : T))`: the
    message is reported where the program calls it, all such calls in one build, and the call keeps raylib's result type, so nothing
    after it is typed wrong because of it; the message is in the source an agent reads. Haxe's `#error` fires wherever the file is
    read, called or not, `@:deprecated` only warns, and `@:require` refuses but leaves the call `Dynamic`, which errors again at its
    first use. In a section the function is marked `@:unsupported("message")`, which `gen_raylib` writes as the macro, checking the
    signature the message names against the call's own. `@:unsupported` is for what helix-ray won't have, by design (these loads,
    rlgl's GL objects), and `@:unimplemented` for what it doesn't have yet (`Build.unimplemented`), so an agent can tell a dead end from
    a gap. `gen_raylib` reads the sections as the compiler describes them (`haxe -xml`, and a macro for the facades' own macro
    functions), not by matching their text. Nothing is read before `main`, and no scan of the program's sources
    decides what: the saves are read when first used. `SaveFileText` and `SaveFileData` need no answer, so they stay raylib's; a write
    made before the saves are read is held and made after, so it wins over what was kept. `LoadFileTextAsync` asks the program's text
    callback, then the saves, then fetches, so what `SaveFileText` wrote reads back a frame later. Faking synchronous loads in a page,
    still on the roadmap, would bring them back on both targets at once. What helix-ray doesn't have yet is declared from raylib's own
    description of its API (`ray/vendor/raylib/raylib_api.json`, and `raymath_api.json` made by raylib's parser), with raylib's
    signatures and `@:unimplemented("LoadImage: Not implemented")`, so an agent reading the source sees what raylib has; a struct
    helix-ray has no type for (`Image`, `Font`, `Wave` and the rest) is generated with raylib's fields until it is written by hand.

22. **raymath is apart from `Raylib`, as in raylib.** raylib.h declares none of raymath's functions; a C program that calls
    `Vector2Add` includes `raymath.h`, and raylib's own examples do, so an agent trained on raylib knows to. helix-ray's `Raymath`,
    generated from the `RMath` section as `Raylib` is from the others, is that header: `import helix.ray.Raymath.*;` beside
    `Raylib`'s. The trial agents used raymath through `Raylib` alone, as the README then told them; the async trial shows whether
    they import `Raymath` unprompted. The sections are private to helix-ray, as raylib's `.c` modules sit behind its headers.
    rlgl is apart the same way (`#include "rlgl.h"`): `Rlgl`, from the `RRlgl` section, has its matrix stack, immediate drawing and
    render state over helix-ray's frame, its constants, and refuses its GPU objects (vertex arrays and buffers, framebuffers, GL ids),
    which helix-platform has no GL to give. Its API description, `rlgl_api.json`, is made from `rlgl.h` by raylib's parser, as
    `raymath_api.json` is.

23. **Geometry is a library of its own, helix-geometry, over helix-math.** helix-math holds the values every layer computes with (vectors,
    matrices, quaternions, transforms, bounds, curves, trig, random numbers, colors), depending on nothing. What is built of them as
    objects in a world went to helix-geometry when meshes came: the cameras, the frustum, rays and what they meet, meshes made and changed,
    and the tests on 2D shapes. A mesh library would have doubled helix-math's weight for programs that only need its values; the
    cameras went with the rays, since a camera makes the ray a pointer picks with. A mesh is helix-geometry's `Mesh3D` everywhere:
    helix-services' models hold their meshes as it, each with its material's index beside it, so a file's mesh and a made shape are one
    type. helix-ray keeps raylib's own meshes and ray tests (par_shapes' vertices, raylib's box normal), which helix-geometry's are not.

24. **helix-ray speaks raylib 5.5 and behaves as raylib's latest release.** Its names and signatures stay raylib 5.5's, the version
    agents know best: a release takes a year or two to gather the code and examples a model learns from, and 5.5 sits on an API
    largely unchanged since 4.x. Its behavior is the latest release's (6.2 now, a tag, not the development line) wherever raylib has
    since fixed a bug and the 5.5 signature still holds: the glTF bind pose from the inverse bind matrices, skinning under non-joint
    parents, animated normals, a glTF material's metallic-roughness image split into its roughness and metalness maps, a ray not
    meeting a sphere behind it. A change that is a choice rather than a fix (parameters reordered,
    a range changed) stays 5.5's, as it would break code written for 5.5. helix-ray's API is raylib 5.5's alone: a later release's
    functions arrive with the version bump, not before. One is kept ahead of it, on trial: `UpdateModelAnimationEx`, 6.2's blend of
    two animations; the next agent trial asks for a blended animation, to see whether agents reach for it. Each behavior taken is checked against that release's own C, as 5.5's were,
    so each function has one oracle: the later release's C where a fix was taken, 5.5's everywhere else. Taking a later release's API,
    when agents know it as well as 5.5's, is a version bump: the API changes, and every caller with it (rule: no backward
    compatibility).
