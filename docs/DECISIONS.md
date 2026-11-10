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
    helix-math (`Matrix3D`), and the platform for drawing. Tried on the branch `raylib-slice`, and merged to `main` on 2026-11-03,
    the user's call: raylib 5.5's API complete, its parity suites against raylib's C passing, checked on Linux and Windows.

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
    `LoadFileText` and `FileExists` refuse everywhere, and later `LoadMusicStream` (it didn't wait, but in a page a missing file read as
    valid until its download failed; `LoadMusicStreamAsync` answers once the stream opens or fails), with the signature of the call to use, "LoadTexture: Synchronous loading is not
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
    Where even the latest release is broken (it crashes, reads past its arrays, or draws what GL refused), helix-ray fixes it rather
    than reproduce it, and lists the fix here: a cubemap read from a cross or a row that comes with mipmaps gets each face's own
    mipmaps (6.2 makes them magenta); `SetShaderValueTexture` binds a cubemap to a `samplerCube` (raylib binds it as a 2D texture,
    which GL refuses, so it draws black); a GIF frame `LoadImageAnimAsync` reads that is disposed of to the previous frame has its
    rectangle put back as it was before the frame was drawn, on every frame (stb_image does so for the second frame, and from the third
    reads before its own buffer, so raylib draws whatever memory lies there); `ExportFontAsCode` writes a font of any size (5.5's writes into a 1 MB buffer, past its end
    for an atlas compressing to more than about 170 KB); `rlGetMatrixProjectionStereo` and `rlGetMatrixViewOffsetStereo` give a zero
    matrix for an eye other than 0 and 1 (rlgl reads past its two). OBJ and MTL reading keeps its own list (28).
    helix-ray is raylib 5.5 as configured with `SUPPORT_GIF_RECORDING 0`: Ctrl+F12 records nothing (5.5's default records the window to
    a GIF, a debug key rather than an API, which 6.2 removes). GIF loading stays as 5.5's (`SUPPORT_FILEFORMAT_GIF 1`).
    A raylib call is done when it returns. Where the platform can refuse a call or applies it later, that can't hold, so the call is
    a candidate for an Async form, as the loads are (19, 20, 21): helix-ray's own `...Async(...args, ?done, ?failed)`, `done` once the
    change is granted, `failed` with the reason (logged as raylib's warning would be when omitted), and raylib's form `@:unsupported`,
    naming it. Each call is decided on its own. The window's requests are the first: `ToggleFullscreenAsync` and
    `ToggleBorderlessWindowedAsync`, as a page grants fullscreen only in a key press, click or tap and a window manager in its own
    time, so `IsWindowFullscreen` says the new state once the window has changed, not when the call returns. The window's other
    requests followed once `IWindow` answered each with `done` and `failed` (natively on SDL's matching event, failing after a second
    where the window manager ignores it): `SetWindowSizeAsync`, `SetWindowPositionAsync`, `SetWindowMonitorAsync`,
    `MaximizeWindowAsync`, `MinimizeWindowAsync`, `RestoreWindowAsync`, `SetWindowFocusedAsync`, `SetWindowOpacityAsync`,
    `SetWindowMinSizeAsync` and `SetWindowMaxSizeAsync`. Then the calls whose outcome comes later on any target: `DisableCursorAsync`
    and `EnableCursorAsync` (a page locks the mouse only soon after a press), `SetClipboardTextAsync` (a page writes the clipboard only
    with the keyboard), `TakeScreenshotAsync` (read back as the next frame ends, `done` once the file is written or downloaded), and
    the writes: `SaveFileTextAsync`, `SaveFileDataAsync` and every raylib export through them (`ExportDataAsCodeAsync`,
    `ExportAutomationEventListAsync`, `ExportImageAsync`, `ExportImageAsCodeAsync`, `ExportFontAsCodeAsync`, `ExportMeshAsync`,
    `ExportMeshAsCodeAsync`, `ExportWaveAsync`, `ExportWaveAsCodeAsync`). raylib's `bool` for a write said whether it was written; the
    Async form's `done` says the same, once the saves have written it (21's "need no answer" no longer holds: a page's write is kept
    a frame or more later, or not at all), or once the program's save callback has returned true. `SetWindowState` and
    `ClearWindowState` stay raylib's: here they only set flags, and ask nothing of the window.

25. **helix-ray counts what a model holds, following ownership, where raylib leaves it to the program.** raylib's `UnloadModel`
    frees a model's meshes and its maps arrays and never a texture or shader, so a C program frees those itself, or leaks them; Haxe
    has no destructor to lean on, and a model loaded from a file shares its textures and GPU buffers with the file's other loads, so
    helix-ray counts holders instead. A texture is counted by each holder: the program from each load that made it (`LoadTextureAsync`,
    `LoadTextureFromImage`) until `UnloadTexture`, and each material map it is assigned to (`MaterialMap.texture` is a property: the
    map keeps a copy of the record, retains the new texture and releases the old). A shader the same: the program from `LoadShader`
    until `UnloadShader`, and each material given it (`Material.shader` a property alike); the default shader and texture are never
    freed. A material and a mesh are counted the same way: the program from the call that made it (`LoadMaterialDefault`, `GenMesh*`,
    a `Mesh` made by hand) until `UnloadMaterial` or `UnloadMesh`, and each model whose `materials` or `meshes` holds it (both are
    abstracts over arrays, written by index as raylib's are, each write retaining the new element and releasing the old).
    `LoadModelFromMesh` takes over the program's hold on its mesh, as raylib programs don't unload a mesh given to a model. A material
    reaching 0 lets go of its maps' textures and its shader; a mesh reaching 0 lets go of its GPU buffers. Each is freed when its last
    holder lets go, and a release of something already at 0 does nothing. `UnloadTexture` or `UnloadShader` given a material's copy
    (`UnloadTexture(model.materials[0].maps[0].texture)`) lets go of one of the program's holds when there is one, else of that
    material's own, which it then doesn't let go of again. A file's loads share its textures and GPU buffers through a cache keyed by
    its path that holds no count: every load, the first included, takes its own counts on what it shares, and the file leaves the cache
    with its last load, so a later load reads it again. `UnloadModel` releases the model's counts, so nothing leaks. Where this differs
    from raylib: a texture or shader copied out of a material and used after its model is unloaded is freed (raylib leaks it); a
    material or mesh shared between models works (raylib's C frees it twice); and a texture or shader a program gives a material and
    never unloads stays while it lives, where raylib's `UnloadMaterial` frees it.

26. **An index ends in `Index` and a count in `Count`, so a name says which it holds.** A bare noun read as the thing itself:
    `GltfNode.mesh` was the mesh's index in `GltfFile.meshes`, `Skin3D.bones` the bones' indices in the skeleton's, `WavFile.channels`
    the number of channels; a reader had to open the doc comment to learn it was a number, and of which kind. Now a whole number naming
    a position in an array ends in `Index` (an array of them in `Indices`), and one naming how many ends in `Count` (`Counts`), fields
    and parameters alike (docs/CONVENTIONS.md, Names). A mesh's vertex indices keep glTF's and raylib's `indices`, the one name every
    reader of a mesh knows; a number of bytes is a size, named for its unit (`capacityBytes`); a handle, an id or a slot keeps its own
    noun. helix-ray's raylib types keep raylib's names (`Model.meshMaterial`, `BoneInfo.parent`). `tools/check_names.py` holds each
    field and parameter whose doc comment calls it an index or a number of things to the rule, reading Haxe's XML description.

27. **helix-ray reads glTF, GLB and OBJ models, and not IQM, VOX or M3D.** raylib's `LoadModel` also reads Inter-Quake Models, MagicaVoxel
    files and Model 3D files, and `LoadModelAnimations` IQM's and M3D's animations. They are rare beside glTF and OBJ: the tools that
    make models export glTF and OBJ, and a program that has an IQM, VOX or M3D file can convert it, where each format kept would be a
    reader to write, check against raylib's C and carry. `LoadModelAsync` refuses a file of one of them with a message saying it isn't
    supported and naming the formats that are, so an agent learns it at once rather than meeting a model with no meshes.

28. **helix-ray reads OBJ and MTL files as raylib does, except where raylib's reading is broken.** helix-formats' `ObjFile` and `MtlFile`
    read what a file says: every `g` and `o` line, a value the file doesn't give as null, a face of 1 or 2 corners, a corner naming a
    line the file doesn't have. helix-ray makes of that what raylib 6.2's `LoadOBJ` and raylib's `LoadMaterials` make with
    tinyobj_loader_c, quirks too, and the `obj_62` and `obj` parity suites hold it to raylib's C: a mesh at every `g` or `o` line with
    faces after it, a group's start counted in `f` lines against triangles, a face of 1 or 2 corners counted and giving no triangles,
    a material's `Kd`, `Ks` and `Ke` black where it gives none and its `Ns` 1, `map_Bump` not read (only `bump` and `map_bump`), a corner naming what the file lacks read as 6.2 reads it ((0, 0, 0), (0, 0), (0, 1, 0)) and one naming a line after
    its face read, an empty file read as one raylib can't read. Where tinyobj_loader_c's reading is broken (it reads outside its
    buffers or uninitialized memory, misreads a form the OBJ or MTL format gives, or reads one name two ways), helix-ray reads the file
    as the format has it. Each fix, checked against tinyobj_loader_c's source; none has a parity case, as raylib's side can't be
    declared to differ:
    - **A face of more than 5 corners** is a fan like any other. tinyobj's `parseLine` gives up on one, leaving the line's command
      uninitialized, and `tinyobj_parse_obj` reads it anyway (5.5's assertion stops the program instead); one of more than 16 corners
      overruns its stack array.
    - **A line longer than 4095 bytes** is read. `parseLine` gives up before setting the command's type, which is read uninitialized.
    - **A `g` or `o` line naming nothing** starts a group, as any such line does. tinyobj reads one only when a space or tab follows
      the keyword, and then, with nothing after it, looks for the name's end past its line buffer (`length_until_newline` given a
      length of 0); an `mtllib` line naming nothing alike.
    - **A material's name is the rest of its line, spaces at its ends taken off, in `newmtl` and `usemtl` alike.** tinyobj reads
      `newmtl`'s first word (`sscanf` into a 4096-byte buffer, which a longer name overruns, and which an empty one leaves
      uninitialized) and `usemtl`'s whole rest of line, so a name with a space in it, or a `usemtl` line with a space after its name,
      never finds its material.
    - **A material is found by its name.** tinyobj's table compares the names' djb2 hashes alone, so of two names that hash alike
      (`Ez` and `FY`) the later takes the earlier's place.
    - **An `mtllib` line naming several libraries** names each, as the format has it, and the last is read. tinyobj takes the line as
      one file's name, spaces included, and opens none; a library whose own name holds a space can't be named, as the format has it.
    - **A texture's path** is what follows its options (`-s`, `-bm` and the rest), resolved against its library's directory. tinyobj
      takes the rest of the line after one character as the name, options and spaces included, so a texture with options, or two
      spaces before its name, isn't found; and raylib resolves it against the OBJ file's directory in `LoadOBJ` and the working
      directory in `LoadMaterials`, so one library finds different textures by the two.
    - **A `#` after a statement starts a comment.** tinyobj reads an `f` line's comment as corners numbered 0 (`my_atoi` of a word),
      which its `fixIndex` makes the first position, and a `usemtl`, `mtllib` or texture line's as part of the name.
    - **A color of one value** (`Kd 0.5`) is that value three times, as the MTL format has it; tinyobj reads green and blue as 0. A
      `spectral` or `xyz` color is skipped; tinyobj reads its words as numbers, 0 for a word.
    - **A number with no digit before its point** (`.5`, `-.25`) is read; tinyobj's `tryParseDouble` fails on it and gives 0.
    - **An .mtl file whose lines end in `\r` alone** is read line by line; tinyobj reads it with `fgets`, as one line.

    A file that breaks the format is refused, not read as tinyobj's lenient parse makes it: `LoadModelAsync` fails, and a library
    refused leaves its model with the default material (logged), `LoadMaterialsAsync` failing on it. These aren't raylib's bugs but
    files no format allows, refused whole with the line named: text holding a NUL byte (tinyobj stops reading at it), a word that isn't a number where one is due (tinyobj's 0, or its leading digits), a `v`
    line of other than 3, 4 or 6 values, a `vt` of none or more than 3, a `vn` of other than 3, a corner not of OBJ's forms, a corner
    numbered 0 (tinyobj's first), an `f` line with no corners (tinyobj copies two uninitialized corners), a `usemtl` line naming
    nothing (tinyobj keeps the material before); in an .mtl file a `newmtl` line naming nothing, a color of 2 values, a number
    missing, an `illum` not a whole number, a texture line naming no file.

    Text is UTF-8 when its bytes are, and otherwise Latin-1, each byte the character of its value, as older tools write their
    system's 8-bit encoding (Windows-1252 among them); tinyobj compares names' bytes, so names match in both as they do in raylib
    (`obj_62`'s latin.obj). A path stays characters: helix-platform's file systems take a String, which hxcpp hands POSIX as UTF-8
    and Windows as UTF-16, and a browser fetches as a UTF-8 URL, so no target can be handed a lone byte 0xE9. A Latin-1 library's
    `café.png` is the file named `café.png` in the system's own spelling: found on Windows, where that name is UTF-16, on a page,
    and on Linux and macOS when the name is UTF-8, as unpacking and copying tools write it; raylib's `fopen` there looks for the
    name's raw bytes instead. Paths stay text because that is what engines give: SDL3's file I/O takes UTF-8, Godot, Unity and
    Unreal take Unicode strings, and a page fetches a URL; only languages' own libraries (Rust's `OsStr`, Python's surrogate escapes)
    keep a path's raw bytes. It is the one difference kept on a file the formats allow that isn't raylib's bug; no parity case shows
    it, as each side's file is spelled apart.

29. **A model's reader is chosen as the program builds, from its file's name.** `LoadModelAsync` read glTF, GLB and OBJ files, choosing
    the reader by the name's extension as the program ran, so every program loading a model carried both: a glTF-only program carried
    the OBJ and MTL readers (ray/tests/sizes' 6-model). `LoadModelAsync` is now a macro in `Raylib`, as `LoadShader` is: a name known as
    the program builds (a constant, or constants joined with +) calls its extension's reader alone, so dead-code elimination drops the
    other; a name known only as the program runs calls the one choosing then, which brings both. helix-services' `Models.load` chose by
    the extension too, so it was removed for `loadGltf` and `loadObj`, and helix-ray's glTF reader calls `loadGltf`: any engine on the
    services carries only the readers it calls. The loads of an image file choose its GIF reader so (`LoadImageAsync`,
    `LoadTextureAsync`, `LoadFontAsync` and `LoadImageAnimAsync` by the name, `LoadImageFromMemoryAsync` and
    `LoadImageAnimFromMemoryAsync` by the type), so a program naming no GIF file carries no GIF reader. Two size trades follow from
    it, where raylib differs. A GIF texture an OBJ's .mtl file names isn't read (the map gets no texture, as for a file that can't be read): its name arrives as the program runs, so reading it
    would link the GIF reader into every program loading a model (glTF 2.0 names only PNG and JPEG images, so a glTF model never
    needs it). And an image's format is picked by its file's extension or the type given, never by its bytes as stb_image's is, as
    sniffing them would link every decoder into every load. raylib's API is unchanged: a program
    names its files as raylib's do, and a constant name is what raylib's programs write. Rejected: a define (`-D helix-ray-no-obj`),
    which a program has to know to set and which fails only as it runs when set wrong; a call registering a reader, which raylib's API
    doesn't have; a reader built when first used (AGENTS.md).

30. **A program links only what it names, and the size ladders check it.** An audit of the ladders' builds (`-dce full`) found code
    every program carried that it never asked for, each reached from something that always runs or a choice made as the program
    runs: helix-ray's poll read every drop, so a window cleared each frame linked the assets, the HTTP client, the caches, the image
    decoder, `Images` and `Models`; its frame's end called the screenshots through a field it tested; `InitAudioDevice` polled the
    streams' topping up; a sound's length read every format's headers; the saves, the manifests and the actions linked `Type` to test
    a value. Each is now reached only from the call that asks for it (`DroppedFiles`, `Runtime.imaging` and `modelling`,
    `Frame.ended`, the first `SetAudioStreamCallback`, a native download's `Sound.measureFrom`), behaving as before; ray 1-window went
    from 26.6 to 22.0 KB gzipped, 8-audio from 88.4 to 78.7. CONVENTIONS, "A program links only what it names", is the rule: a
    library chooses an implementation from what the program wrote, never a run-time string, extension or enum value; an optional collaborator is reached through a hook
    its call installs, never a typed field tested for null; no run-time type inspection or `@:keep` in a library; a layer wearing a
    run-time-choosing API narrows it as the program builds (29). It names what still chooses at run time as known, not fixed. The
    check is `tools/measure_sizes.py --check`, through the compiler: each rung's `Main` declares in `@:adds` what it adds, and its
    build's `-xml` (what dead-code elimination kept) and a macro reading `@:keep` as written (`-xml` marks every kept type so) fail a
    rung linking what no rung up to it declares. Rejected: a table of each rung's packages in the tool, apart from the program it
    describes; matching the JavaScript's text for class names, which breaks on the next minifier or name mangling.

31. **Shaders above the platform are one services package, and the platform reflects what it compiles.** Shader work was done twice
    (helix-ray's `ShaderMacro` and `Program`, the helix-draw draft's `ShaderCode` and `ShaderValues`); `helix.services.shaders` does it
    once, agreed as an API over five rounds of cold-start trials (fourteen agents) before any of it was written: compiling while the
    program builds (`Shader.compile`, `compileText`, `ShaderVariants` for features, `makeExpr` for a library's macro); knowing a shader
    by name through handles found once (`getUniform`, `getUniformPath`, `reserveUniform`); values kept as `IGraphics.draw` takes them,
    layered over a base by reference with copy on write, shared blocks (`ShaderBlockValues`) and scenes (`ShaderScene`), snapshots for
    a batcher; typed classes generated by build macros (`ShaderValueClasses`); programs and pipelines held and rebuilt at the frame's
    start (`ShaderPrograms`, nothing built inside a frame); files replaced in place through the assets (`Shaders.watch`,
    `Assets.watch` and `notifyChanged`), one signal (`reloadCount`). The platform took what it needed as accepted proposals: the
    reflection as documented output (`ShaderBlock.members`, `ShaderSource.attributeTypes`), `compileText` with `ShaderCompileOptions`,
    structs and arrays and floats with integers in std140 blocks on every adapter (WebGL2 uniform buffers; sokol's GL setting each
    member itself, as sokol_gfx's own layout computes offsets from a flat member list and can't hold a struct's padding, nor `mat2`,
    `mat3`, `uint` or `bool`), loose uniforms gathered into `helix_uniforms` by a strict text step over glslang's preprocessed output, a
    block both stages declare alike one block, blocks numbered per stage (0 to 3 each, as SDL_GPU binds them), unfed attributes reading
    constants, the flip naming its uniform's place, the include extension enabled, the clip-scale wrap, and a draw refusing a pass's own
    target. Integer vertex attributes (proposal 7) were left undecided: `ivec` inputs are reflected and refused where a layout would feed
    them. helix-ray's shaders are the service's, its `ShaderMacro` keeping only raylib's adaptations. Rejected: compiling while the
    program runs (megabytes of compiler in a page, GOALS 2); names at the setters (a lookup a draw); a second reflector in each
    library; sokol_gfx's uniform blocks with padding members (sixteen members a block, and no struct, `mat3`, `uint` or `bool`).

32. **A wave keeps its file's rate and raylib 5.5's sample size, and reads what 5.5's default build reads.** `LoadWaveAsync` decoded
    every compressed file at 44100 Hz as floats, read FLAC and refused QOA, where raylib 5.5's `LoadWave` keeps a file's rate, gives
    Ogg 16-bit samples, MP3 32-bit floats and QOA 16-bit, and refuses FLAC (its config.h leaves `SUPPORT_FILEFORMAT_FLAC` out). The
    platform's `IAudioDecoder.decode` takes the rate to decode at, and helix-ray reads the file's from its header
    (`AudioHeader.readSampleRate`) and asks for it, so nothing is resampled; the platform reads no headers, so a program decoding for
    a clip at 44100 links none of it (a first draft's 0 for "the file's own rate" had every decoding program carry the header
    reader); Ogg's floats are made 16-bit as stb_vorbis makes them; QOA is helix-formats' port of qoa.h; FLAC is refused as 5.5 refuses it, matching its default
    configuration rather than fixing anything, and so is FLAC music (`LoadMusicStreamAsync`, `LoadMusicStreamFromMemory`). Decoders that read an MP3's LAME tag (SDL3_mixer's dr_mp3 0.7.4, Chromium's) trim the
    encoder's delay and padding and skip the tag's frame, where 5.5's dr_mp3 0.6.39 decodes every frame; helix-ray hides the tag from
    the decoder (Chromium still drops its frame, put back as the silence 0.6.39 decodes it as), so the frames are 5.5's on every
    target, and rounds the floats to 16 bits and back as 0.6.39 does (minimp3's SSE and scalar roundings), so natively they are 5.5's
    bit for bit (the `waves` parity suite). Chromium also ends an Ogg Vorbis stream early (by tens of frames, measured),
    so a wave's length is the stream's own (its last page's position) and what the browser left out is silence. The reader is chosen as
    the program builds, from a constant file name or type, as a model's is (29). Rejected: padding a trimmed MP3 back by the tag's
    numbers, as first proposed (silence where 5.5 has the decoder's own samples).

33. **A vertex attribute has a format, from the set every backend shares.** Attributes were floats alone, so layers above uploaded
    bytes as floats (helix-ray's colors four floats a vertex, its immediate vertex 48 bytes). `VertexAttribute.format` is a
    `VertexFormat`: `Float1` to `Float4`, `Half2`, `Half4`, and the normalized `UByte4Norm`, `Byte4Norm`, `UShort2Norm`, `Short2Norm`,
    `UShort4Norm` and `Short4Norm`, each read by a float input: the formats sokol_gfx, SDL_GPU (Vulkan, Direct3D 12, Metal) and WebGL2
    all have, as WebGPU does, each mapping one to one onto their enums. Offsets and strides are multiples of 4 and a stride at most 255,
    WebGL's limit made the platform's so a layout made in a page is made natively. One check (`adapters/shared/PipelineLayout`) holds
    the rules for every adapter and refuses a format fed into an integer input (`ShaderSource.attributeTypes`), which nothing checked
    before. helix-ray takes raylib's own layouts: a mesh's colors raylib's 4 bytes, the immediate vertex raylib's 36 bytes, and
    `UpdateMeshBuffer` writes color bytes where raylib does. Rejected: a (type, count, normalized) triple as GL and three.js spell it
    (most combinations refused by prose and each adapter's check); bytes or shorts read unnormalized as floats ("scaled": raylib's bone
    IDs, three.js' `skinIndex`, glTF's quantized positions), which only GL and WebGL2 have, as a platform format. Deferred: such inputs
    fed normalized and scaled back by the compiler, rounded; bone IDs stay floats until then.

34. **A render target's samples are chosen apart from its depth.** `createRenderTarget` multisampled a target exactly when it had depth,
    at the screen's count, so raylib's render textures (a depth buffer, one sample) were multisampled under an MSAA window and a target
    without depth (three.js' `samples`) could not be. It takes `msaaSampleCount`: 1 for none, 0 (the default) for the screen's, a count
    rounded down to the nearest the GPU draws the format with, up to `getMaxRenderTargetMsaaSampleCount(format)`, and never refused for
    being more than the GPU takes. A GPU need not take every power of two (lavapipe takes 1 and 4), so each adapter rounds to a count the GPU
    reports for the format. helix-ray's `LoadRenderTexture` asks for 1. SDL_GPU on NVIDIA's Vulkan driver (595.104 on Linux, 537.58 on
    Windows' RTX 2060) loses the device when a multisampled pass is followed by one of fewer samples in a command buffer (validation and
    synchronization layers clean, lavapipe fine), so the adapter submits what it has recorded before such a pass. Rejected: a target's count read back after it is made (the
    limit answers the question before); one limit for windows and targets (a browser's canvas count is its own choice).

35. **helix-render draws for the engines above, judged by a raylib layer and a three.js layer, and is built in stages from its API.**
    Its API was drafted whole (nine revisions; types and doc comments, no code, typechecked against the libraries below) and tried by
    cold-start agents three times: five trials of revision 6 (a 2D game, a 3D scene, custom shaders, a raylib layer, a three.js layer),
    three of revision 7 (custom shaders, raylib, three.js) and a raylib layer of revision 8; each round's findings changed the API, not
    the prose. What was agreed: one `Renderer` over `IGraphics` creating what is drawn (textures, targets, cube textures, meshes,
    models, fonts, environment maps) and recording the frame, drawn at `endFrame` (shaders built, then shadow passes, target passes in
    the order begun, the screen's); a target read and then drawn into again copied on write, as raylib's frame shows it; `clearTarget`
    recorded in order, a batch open or not; `beginFrame`'s clear optional (the platform always clears, and a swap chain need not keep
    the last frame, so black is the portable "not cleared"). `Batch2D` for 2D programs and `Batch3D` for everything else, raylib's 2D
    included (rlgl is one 3D batch under matrices: wire and point modes, shaders and stereo reach its 2D), both filling one set of
    shader names so one shader serves both and a material; draw state kept across `begin`s and frames as rlgl's, `resetState` putting
    it back; `transform` and `customData` written into the vertices, splitting nothing; shapes drawn from `shapeRegion`, a white texel
    on a sheet or atlas (`Texture2D.writeWhiteTexel`, raylib's `SetShapesTexture`), so shapes join the sprites' or the text's GPU draw;
    one shader for every font kind. Views (`View3D`, `beginViews`): each draw recorded once and drawn once a view, culled, lit and
    shadow-fitted for them all (raylib's stereo, three.js's ArrayCamera and WebXR); `View3D.isInView` at any time, for a layer culling
    its scene before the batch opens. Points: one pixel is the platform's `Primitive.Points`, larger, attenuated (three.js's
    `size × (viewportHeight / 2) / -z`) or textured ones and wide lines squares made in the vertex stage. Colors: a target's format says
    what it holds (RGBA8 and the screen sRGB, RGBA16F linear); 3D works in linear light, one `exposure` and `toneMapping` on the
    renderer for a direct draw and a resolve alike; the batch draws, and an `Unlit` material with `colorSpace` Srgb, multiply as stored
    (a 0x80 tint on a 0x80 texel gives 0x40, as raylib). Shaders are helix-services' (31): a program's draws through its `ShaderValues`,
    compiled by the type owning the vertex stage (`compileShader` for a fragment stage over helix-render's, `compileShaderStages` for
    both, `Batch3D.makeShaderExpr` for a layer's macro), every shader compiled with `clipScale` and `points`, the `View` and `Lighting`
    blocks shared through their includes (a shader declaring a name loose is written it per draw), names `Shader.withNames` gives
    filled as declared ones, clip planes cut by wrapping a fragment stage's `main`; no variants for a program's material (instancing
    by unfed attributes' constants, skinning and morphing by uniforms); bones and morph deltas in data textures (no 4 KiB block
    limit). Per-draw mesh state as one `MeshState3D` (helix-ray mirrors rlgl's global state in one; the materials stay as three.js
    expects them). Light in three.js's units, every light starting at π; four shadings; at most 4 casting lights, texel-snapped
    directional maps with cascades, bias in texels with a normal offset; HeliX's CPU environment bake, bloom and screen effects carried
    over. What the layers keep is named in the draft's tables: helix-ray its parity (raylib's exact vertices, `BLEND_ALPHA`, the
    default font's data, locations, high-DPI scissor), a three.js layer its scene graph, sorting, render lists and what needs MRT or
    cube targets. Rejected: a renderer-level pass per eye (draws recorded twice); a shapes flag in the vertex in place of a white texel
    (a program's shader would see it); a per-draw `colorSpace` on `Batch3D`; VSM shadows; a mask target for `toneMapped` off in a
    linear frame. It is built in stages, each member of a later stage throwing and naming it: 1, the renderer, textures and targets,
    the 2D batch and lists, text, and `Batch3D`'s unlit work; 2, lit materials and lights; 3, shadows; 4, environment maps; 5,
    post-processing; 6, fog; 7, morph targets. Asked of the libraries below and not yet there: `Font2D.kind` and kerning pairs and a
    `Font2D` from glyph data (helix-services), `GltfMaterial`'s alpha mode, cutoff, sides, samplers, texture transforms and
    extensions, and morph targets (helix-formats), `Mesh3D`'s second texture coordinates, morph targets and groups (helix-geometry),
    Euler orders, an object's `lookAt` and `Bounds3D` through a matrix (helix-math); and of the platform, a render target's own
    sample count, more depth tests, depth bias, stencil and a sampled depth.

36. **Assets knows a kept copy by its label, and its sources and cache policies are classes the program constructs.** `Assets` took
    an enum of sources (`FileSystem`, `HttpServer(url, ?cacheMode)`) and an options object (8), and tested `AssetCacheMode` as it
    ran, so every program with a server linked the manifest reader, the shipped trees and `haxe.crypto.Sha256`, and one reading only a
    file system linked the server's downloading; and every download was hashed, in every mode, `Off` too, for a hash only `Manifest`
    ever compared. HeliX hashed every download; the earlier C frameworks (wgrender-c, libwgt) hashed only a download a manifest lists,
    and HeliX's was the regression. Now `new Assets([sources])` takes `FileSystemSource(fileSystem)` and `ServerSource(url, http,
    cache)`, the cache a `RevalidateCache`, `TrustCache`, `MemoryCache` or `ManifestCache(fileSystem, {manifestName, shipped})`, the
    shipped trees given to the cache rather than inferred from the sources after it. A copy is current by its label: the server's ETag,
    Last-Modified and freshness (Revalidate, Trust), or the manifest hash it was checked under (Manifest). The one hash left is a
    download a manifest lists, once, before its label is written beside it: only it catches a CDN edge or a half-finished deploy serving
    the old bytes under a new manifest (option C, labels with no hash, would keep them under the new label). Kept copies and shipped
    files are never hashed, as none ever were. A record carries the byte count, and a replacement deletes the old record, writes the
    bytes, then the record, so no failed or interrupted write leaves a label beside bytes it doesn't describe (the old order, bytes
    then record, could serve new bytes under the old ETag after a rollback); a read with no record, or bytes of another size, downloads
    again, and a record of the old shape (no size) reads as none. 404 and 410 remove both, a directory's new manifest deletes the
    copies of the names it dropped as it arrives, and `deleteCopy(path)` deletes every server's copy of a file. `Assets` is
    `IPollable`: what it answers with nothing of the platform's to wait on (a held file, a refused path) answers at its `poll`, which
    the program calls each frame, so `MemoryCache` needs no file system to answer later through. Measured (`tools/measure_sizes.py`,
    gzip): a program reading a file system alone adds 0.7 KB for the assets; a server with a `RevalidateCache` 18.6 KB where 21.7 was
    (render's text, shapes and mesh rungs and helix-ray's from the texture up 3.0 to 3.3 KB smaller); `ManifestCache` adds 3.9 KB,
    `Sha256` and the manifests with it, and `measure_sizes --check` holds that only it links them. The `IHttp` contract's `done` meaning
    the whole body is checked against a server that closes early (`tools/platform_checks.py http`), in a page and natively. Deferred:
    a listed download hashed off the main thread (`crypto.subtle`, a platform contract to propose), and a listed file streamed while it
    downloads.

37. **An HTTP request fails after an idle timeout, and a page checks a body against its Content-Length.** Natively a request had
    `sys.Http`'s 10 seconds a read, and its connect none (hxcpp's connect ignores the socket's timeout, waiting minutes on Linux); in a
    page none at all, so a stalled server held a request until the browser gave up, if it did. Now `get` takes `?idleTimeout`, 30
    seconds by default on both targets: a request that receives nothing for that long fails, while it connects, waits for its head, or
    between parts of its body, and one that keeps receiving never does (a total timeout would fail a large download on a slow
    connection). 30 seconds outlasts a mobile network's connect retries (a lost SYN is sent again after 1, 3, 7 and 15 seconds) and a
    busy server's first byte. Natively the sockets connect without blocking and wait with `select`; https copies `sys.ssl.Socket`'s
    connect after its own wait. The name's lookup isn't timed, as it can't be on the thread that makes it. In a page a timer, reset at
    the head and each part, aborts through the request's `AbortController`; it starts only once the request is among the adapter's
    first six to its origin, since a browser queues the rest behind its six HTTP/1.1 connections and a timer from `fetch` would fail
    the seventh of seven slow downloads. `dispose` now ends each request as its abort does, where it aborted the controllers and let
    their rejections call `failed`. `done` meant the whole body natively but not always in a
    page: Chromium answered a connection closed mid-head 200 with an empty body, and Firefox a cut gzip body as whole. So a page checks a
    body that ends against its `Content-Length`: by the Resource Timing entry's `encodedBodySize` (the bytes as sent, so compression
    doesn't matter) where the page may read the entry, or by the bytes read where the response is the page's own origin's and
    uncompressed. Chromium adds the entry a task after the body ends, so a check with neither waits one task, once. A response from
    another origin without `Timing-Allow-Origin` hides both its sizes and its `Content-Encoding`, and calls `done` unchecked: guessing
    from the bytes read would fail a server's gzip of an incompressible file, whose body decodes shorter than its `Content-Length`. The
    page's Resource Timing buffer is doubled whenever it fills, since a full one drops each new entry; clearing it would take other
    code's. Checked by `tools/platform_checks.py http`, its server now serving the page so the cases are asked of the page's own origin
    and of another, in Chromium and natively (Firefox by hand: it passes the same cases).

38. **What helix-raylib adds to raylib's API is in `helix.raylib.extras`, a module for each raylib module or feature, and a program
    reaching for raylib or the page is pointed to it.** `Raylib`
    held raylib 5.5's API and helix-raylib's own `...Async` calls side by side, so an agent reading it couldn't tell raylib's from ours,
    and what a game needs from the device and the page (a phone's notch, the URL's options, touch or mouse, orientation, tilt) had no
    place at all: a game reached for `js.Browser` behind `#if js`, one target's code. Now `Raylib` (with `Raymath` and `Rlgl`) is
    raylib 5.5's alone, with the fixes 24 lists, and the package `helix.raylib.extras`, each module imported apart as `Raymath` is
    (`import helix.raylib.extras.Textures.*;`), holds everything helix-raylib adds, written as raylib writes its own: every `...Async` load, request and
    write (moved, not aliased: `Raylib.*` no longer has them), and `GetWindowSafeArea` (in the screen's coordinates, as
    `GetScreenWidth` measures), `GetRunOption`, `IsPlatformWeb`, `GetPlatformOS`, `IsTouchScreenAvailable`, `IsFinePointerAvailable`,
    `IsWindowCloseable`, `IsFullscreenAvailable`, `SetScreenOrientationAsync` and `GetScreenOrientation` (with `ORIENTATION_ANY`,
    `ORIENTATION_LANDSCAPE`, `ORIENTATION_PORTRAIT`), and the tilt (`EnableTiltAsync`, `DisableTilt`, `GetTilt`, `SetTiltRange`,
    `CalibrateTilt`), each over helix-platform's `ISystem`, `Device` and `IWindow` and the services' `Tilt`, answering on every target
    rather than failing to compile where a target has no such thing. The tilt is made when a tilt function is first called, so a
    program that calls none links none of it (30). It was one class, `Extras`, until it reached 73 calls and 848 lines; now it is a
    package, by one rule: the async versions of raylib's calls are in one module for each raylib module, named for it (`Textures`
    for rtextures', `Text`, `Models`, `Audio`), rcore's split three ways, as it alone would be some 50 calls (`Window` for the window,
    cursor, clipboard and screenshot, `Files` for the files, `Device` for the device and the page). A feature helix-raylib adds
    on its own is a module of its own, never added to an existing one (audio effects, when they come, are `extras.AudioEffects`). The
    names follow CONVENTIONS.md's plural and singular. Each module is generated by `gen_raylib` from its own section
    (`RWindowAsync`, `RFilesAsync`, `RTexturesAsync`, `RTextAsync`, `RModelsAsync`, `RAudioAsync`, `RDevice`), as the other facades
    are. Their shared answers are in `helix.raylib.internal.Answers`. `gen_raylib` fails a module over 300 lines, and one holding a static
    variable with an initializer, which every program importing it would link. An agent writes raylib from memory and reads the
    compiler, not the docs, so the compiler points the way: every refusal naming a call of an extras module names that module's import
    ("LoadTexture: Synchronous loading is not supported. See LoadTextureAsync(fileName:String, loaded:Texture2D->Void,
    ?failed:String->Void) in helix.raylib.extras.Textures (import helix.raylib.extras.Textures.*;)"), which `gen_raylib` checks, the
    module named the one holding the call; emscripten's calls that raylib's web programs make
    (`emscripten_set_main_loop`, `_arg`, `emscripten_cancel_main_loop`, `emscripten_run_script`, `_int`, `_string`,
    `emscripten_get_now`, `emscripten_sleep`) are refusals in `Raylib`, each saying what to write instead (raylib's own loop, which
    runs in a page; the `extras.Device` call that answers the script's question; `GetTime`); and a program whose own code reaches the host
    for what the extras answer (the page's location or `URLSearchParams`, `Sys.getEnv`, `matchMedia`, `maxTouchPoints`,
    `screen.orientation`, `env(safe-area-inset-*)`, `deviceorientation`, the page's storage and fullscreen, in code or in a
    `js.Syntax.code` string) builds with a warning at each place, worded as a refusal is and naming the call and its module's import, when built with `-D helix-raylib-host-warnings` (the user's call: off by default, as a person
    reads this README and may reach the host on purpose; on for an agent writing raylib from memory, which a trial sets, and A/B'd
    there against refusals alone). The warning reads the typed program after typing (`helix.raylib.internal.HostReach`, run
    by the library's `extraParams.hxml`), never the source's text, and looks only at files outside the libraries' class paths, so it
    costs a program that doesn't reach the host one walk of its own code. Rejected: keeping the `...Async` calls in `Raylib` beside
    raylib's (an agent can't tell which are raylib's), aliases in both places (no backward compatibility), and one `Extras` class
    for everything, which grows past reading as each feature lands.

39. **helix-render's frame is a command stream, kept lean, and helix-raylib moves onto it only if it costs no size or speed.** The
    recorded frame (35) is a list of commands for each pass, each an opcode and its arguments appended as the program draws, and
    played in order at `endFrame`: shadow passes, then target passes in the order begun, then the screen's. A target read and then
    drawn into again is one copy command. What only some programs use is linked only when used: the pipeline choice, disposal, the
    checks, `Batch3D`'s setup and the shader cache. Its costs were weighed and accepted: an error found at `endFrame` rather than at
    the call, arguments copied into the stream, a read in the middle of a frame (a screenshot, a pixel) waiting for the passes before
    it, a resource freed only after the frame that uses it, passes depending on each other in recording order, a frame's latency of
    one recording, and a harder trace when debugging. They are what rlgl's own batch and the earlier C frameworks' frame commands
    already pay. helix-raylib's `Frame` is the same idea, written for raylib alone. helix-raylib is rebuilt on helix-render only if each
    size rung grows by at most 1 to 2 KB gzip and `tools/compare/compare.py` finds the bunnymark no slower than docs/speed.md records. Otherwise it keeps
    its `Frame`. Rejected: drawing at each call (a render texture drawn into after the screen has begun needs its pass first, which
    raylib allows), and a retained scene inside the renderer (helix-scene's job).

40. **The order: raygui, its skins, helix-render's stages, helix-raylib on helix-render, then helix-scene, and Gyre's shape waits on
    the jam.** raygui depends on nothing helix-render adds. It draws through helix-raylib's calls, it rounds out the API agents know,
    and the jam needs a UI that agents don't hand-roll, so it comes first. raygui styles only colors, borders, text and icons. Skins
    from images (nine-slice textures for each control and state, image buttons) are what Godot, Unity and Phaser give, so helix-raylib
    adds them in `extras.GuiSkins`, a feature of its own (38), drawing through raygui's controls so their signatures stay raygui's.
    Their drawing moves into helix-render's `Batch2D` when helix-raylib moves onto it, where a retained UI uses it too. helix-render's
    stages come next, then helix-raylib on it under 39's bar, then helix-scene, the retained mode both Gyre and a three.js-style engine
    sit on. Gyre is a sibling of helix-raylib, never built on it: raylib's API has no lights, shadows or post-processing, and the
    mirror keeps raylib's quirks on purpose, which a scene would inherit. What Gyre holds of its own (the app's lifecycle, a retained
    UI, tweens, transitions, the autopilot) is the jam's question: agents build the same game on helix-raylib and on HeliX, and if the
    framework's structure doesn't beat the familiar API, those parts become services or extras and Gyre's API is not kept for its
    own sake. The speed this order holds to was set on 2026-11-04 (docs/speed.md): a bunnymark that drew 50k sprites natively in 30.8
    ms a frame now draws them in 3.1 (raylib C 2.95), from three changes to helix-raylib's batch (nothing allocated per draw, typed
    records in place of anonymous structures, quads as four indexed vertices).

41. **raygui is `helix.raylib.Raygui`, raygui 4.5-dev's API and behavior as raylib 5.5 ships it, its file loads in `extras.Gui`.**
    raygui is raylib's own immediate-mode GUI, a header of its own (`raygui.h`), so it is a facade of its own, imported apart as
    `Raymath` and `Rlgl` are (`import helix.raylib.Raygui.*;`). `gen_raylib` generates it from two sections, `RGui` (state, style,
    icons, tooltips and the text drawing the controls share) and `RGuiControls`, with its constants from
    `vendor/raygui/raygui_api.json`, which raylib's parser makes from `raygui.h`. Its version is the one raylib 5.5 ships in its
    examples, 4.5-dev, its one oracle (24). raylib 6.2 ships raygui 5.1-dev, whose changes are redesigns rather than fixes the 4.5
    signatures can keep (`GuiMessageBox` and `GuiTextInputBox` take another parameter, `GuiSliderPro` goes, and `GuiToggleGroup`,
    `GuiColorPanel` and `TEXT_LINE_SPACING` are reworked), so none is taken. Moving to 5.1 is a version bump of raygui with raylib's.
    A pointer a control changes is a one-element array (`[false]`, `[0]`, `[0.5]`, text as `[text]`), as raylib's `int *` is
    elsewhere, and a struct it changes is changed in place. It draws through helix-raylib's calls and reads input through them, as
    raygui does through raylib's, so raylib's automation events drive it. raygui computes in floats, and Raygui rounds to floats where
    that places a pixel. Its state is the sections', so a program that never calls raygui links none of it (30). With every call
    linked it costs 23.3 KB gzip, its icons included. `GuiLoadStyle` and `GuiLoadIcons` read a file, so they refuse, naming
    `GuiLoadStyleAsync(fileName, ?done, ?failed)` and `GuiLoadIconsAsync(fileName, loadIconsName, loaded, ?failed)` in `extras.Gui`,
    raygui's module of async calls (38). A style's font line loads its font through `LoadFontExAsync`. `GuiLoadStyleFromMemory` is
    private in 4.5-dev, so it isn't in the API. raygui's quirks are kept, as raylib's are: the text boxes' shared cursor, Delete and
    Backspace removing the size of the last character typed, a style file's last line unread without a break after it, and
    `GuiLoadStyleDefault` unloading the font set before it. The parity suites `raygui`, `raygui_input` and `raygui_values` build
    raygui's C against raylib 5.5: GL matches pixel for pixel, SDL_GPU within 2 levels in faint blends, and the values to 2e-9.
    Rejected: raygui 5.1's API (agents know 4.x's, which raylib 5.5 ships), and taking its fixes piecemeal (they don't separate
    from its redesigns).

42. **raygui's controls can be skinned from images, in `extras.GuiSkins`, drawing through raygui's own controls.** raygui draws every
    control as flat boxes in its style's colors. Godot (StyleBoxTexture), Unity (GUIStyle) and Phaser (nine-slice) all draw controls
    from a game's art, so helix-raylib adds it (40), a feature of its own in a module of its own (38). A `GuiSkin` (`helix.raylib`'s, beside
    raylib's types) is a texture and a nine-patch for each of raygui's states, falling back to the normal one, and the pressed one to the
    focused. `GuiSetSkin(control, part, skin)` sets it for a part of a control: its base (the box), its fill (a slider bar's bar, a
    progress bar's progress, a check box's check), its handle (a slider's, a scroll bar's thumb) or its item (a list's rows). `DEFAULT`
    behaves as `GuiSetStyle(DEFAULT, ...)` does, setting every control, and its own base is the panels' body. `GuiSkinFromSheet` cuts a
    sheet of a control's states, down or across. The controls keep raygui's signatures and its text, so a skinned `GuiButton` is
    `GuiButton(bounds, text)`. raygui's box drawing goes through one hook, null until a skin is set, so a program setting none links
    none of it and draws exactly as raygui does (the raygui suites unchanged); `GuiSkinsTests` checks a skinned control draws the
    vertices `DrawTextureNPatch` draws. A trial (docs/trials/2026-11-04-gui-skins) of two Sonnet agents changed the API, not the
    prose: the type moved to where they looked, the sheet cutter and the panels' skin were added, and the parts were tabled.
    Rejected: a skinned variant of each control (`GuiSkinnedButton`), which doubles the API agents must learn, and a scoped
    `GuiWithSkin(..., () -> ...)`, which raygui's style has no counterpart of.

43. **helix-render's lighting is linked by what gives light, and lit by three.js's formulas.** Stage 2 builds `Lambert`, `Phong` and
    `MetallicRoughness` (clearcoat, sheen, specular and ior as glTF's extensions add them) as one shader over `lighting.glsl` and
    `material.glsl`. Lights are in three.js's units: decay 2 with glTF's range window, a spot's smoothstep between its cones, and a
    hemisphere light's sky and ground taken as diffuse light along the normal. Ambient light is three.js's `AmbientLight`, so π shows
    white. Each draw is lit by the 8 lights reaching its box most, a spot's cone judged toward the box and widened by its reach, so a
    spot aimed at a large mesh's edge isn't dropped. Making a light, setting ambient light, writing a lit shading, an emissive color or
    a light map, or compiling a shader that reads the lighting installs it (30). A program that does none of them carries none of it
    (the render ladder's 5-mesh grows 0.28 KB gzip for the hooks), and a lit material there is drawn as no light leaves it, black with
    its alpha kept, as three.js draws one with no lights. A mesh's points larger than a pixel are each vertex's square made in the vertex
    stage, its records one per GPU instance, so an instanced mesh is one GPU draw per copy, linked once a point size is set. One-pixel
    points stay one per index, as raylib draws them. The lit rung (6-lit) costs 9.4 KB gzip over 5-mesh, nearly all of it the shader,
    whose every shading SPIRV-Cross inlines. Pixel tests check each light kind and shading against three.js's formulas within 3/255 on
    GL, SDL_GPU and WebGL2. Rejected: linking the lighting from `Material3D`'s constructor, which every unlit program calls; a shader
    for each shading (a shading chosen as the program runs links them all anyway); large points from the mesh's records copied on the
    CPU.

44. **helix-raylib skins an animated model on the GPU, keeping raylib's API, and a program's own shader skins through an include.**
    raylib's `UpdateModelAnimation` moves every vertex on the CPU, and helix-raylib made two GPU buffers a mesh a call: natively the
    adapter's 256 buffers ran out at about three characters a frame, and in a page 200 characters cost some 80 ms. Now a call stores the
    pose, not the vertices: each skinned mesh keeps its bone matrices as they are then, and each draw writes them into the frame's one
    bone palette (a data texture, four texels a bone, uploaded once before the frame's passes) and is given its first bone, so one
    model posed and drawn many times in a frame, a game's crowd, draws each as it was asked for. raylib's default shader is drawn through
    its skinned twin, `shaders/unlit_skinned.vs`. A program's own vertex stage skins on the GPU by including
    `<helix/raylib/shaders/skinning.glsl>` (the bone inputs, the palette and `helixSkin()`), or as raylib's `skinning.vs` does, with
    `boneMatrices`; any other shader of its own is skinned on the CPU, as raylib's is, its buffers made once a frame. `animVertices`
    and `animNormals` are worked out on the CPU when first read after a call, so a program reading them (or wire and point mode) sees
    what raylib's do. What a shader declares is read from its reflection (its attributes, samplers and uniforms), never its text. The
    palette, the twin and the CPU path are linked by the first `UpdateModelAnimation` or `UpdateModelAnimationEx` (30): the size ladder's
    rungs without animation are unchanged but for 6-model (0.3 KB gzip, the allocation-free bone uniforms a loaded skeleton links), and
    7-skinned grows by the twin and the palette. The `crowd` parity suite draws one model in 240 poses in a frame against raylib's C,
    which skins on the CPU; the GPU's sums differ from it by float rounding alone. raylib's CPU skinning leaves tangents, and so does the
    twin. Rejected: generating a skinned twin of every vertex stage a program loads, by rewriting its GLSL (it rewrites the user's code);
    a buffer per draw (the platform's buffers run out); the bones in a uniform array (a block's 4 KiB on SDL_GPU's Vulkan holds 64).

45. **raylib's examples' lighting is built in, as `extras.Lights`, over a public include.** raylib leaves lighting to its examples:
    `rlights.h` and the `lighting.vs` and `lighting.fs` they load. A program wanting lit models had to ship those files, and an animated
    model under them was skinned on the CPU (44). `extras.Lights` (38) mirrors `rlights.h` (`Light`, `CreateLight`,
    `UpdateLightValues`, `MAX_LIGHTS`, `LIGHT_DIRECTIONAL`, `LIGHT_POINT`, its count of lights the program's, as rlights' is) and adds
    `LoadLightingShader()`, the example's shader built in, so the example runs unchanged but for its load. helix-raylib's four model
    shaders are short files in `helix/raylib/shaders/` over two public includes a program's own shader can use as well:
    `<helix/raylib/shaders/skinning.glsl>` and `<helix/raylib/shaders/lights.glsl>` (rlights' uniforms and `helixLight`, lighting.fs's
    math), each documented in its head comment; unlit (raylib's default), unlit skinned, lit and lit skinned. A twin is written every
    uniform its shader is (`Program.mirror`), so `SetShaderValue` on the lit shader reaches its skinned draws. The lit shader is linked
    by `LoadLightingShader`, the skinned ones by `UpdateModelAnimation`, and the lit skinned one with the lit one (`LoadLightingShader` sets it as its program's
    skinned twin), so a lit program that never animates carries it too: `@:ifFeature` could link it only when both are called, but a
    field marked so keeps its class whatever else uses it, so it linked the twin into every lit program all the same. The
    `lighting` parity suite draws the example's setup and greenman lit and posed, through the built-in shader and through a program's
    own over both includes, against raylib's C running the example's files and skinning on the CPU. Rejected: the lighting in `Raylib`
    (it isn't raylib's API, 38), and copies of the GLSL in each shader rather than the includes.

46. **helix-raylib keeps raylib's API and behaviour exactly, and its pixels as a default, not a rule.** The API is the value: an agent
    or a developer who knows raylib writes raylib and it compiles, with the names, parameters, conventions and quirks they expect. Where a
    target forces a change (a page can't block on a file, so `LoadTexture` can't be), the call is a compile error naming its
    replacement and where to import it from, and a raylib type named without its import gets a compiler note with the import line;
    additions live in `extras` and are reached the same way. Never a silent difference: a call that compiles, runs and does something
    other than raylib. Pixel exactness against raylib's C (the parity suites, byte for byte) is kept because it is a free oracle: every
    drawing path is checked without written expectations, and a regression anywhere shows at once. It is not what agents need, which is
    behaviour they can predict, so where exactness would block a real gain in speed or quality, the gain is taken, that suite loosened to
    a stated tolerance of a pixel, and the reason recorded here. The sprite runs (2026-11-05) kept exactness because it cost 8 bytes a
    record. Rejected: exactness as a rule binding GPU-side math, and a README listing the differences (a message from the compiler, not
    prose).

47. **What goes in: the libraries by the engine bar, an engine's extras only as doors onto them.** A feature enters a library
    (platform, services, helix-render) when two of Godot, Unity, Heaps, three.js and raylib have it and a game in the shape we aim at
    would use it; it is then built once, properly, whether or not a consumer asks yet. helix-raylib's API is raylib's, complete and
    exact, and nothing is added to it. An extra is a raylib-shaped call onto machinery a library already has, for a raylib user who
    would otherwise drop a layer: the async loads, GPU skinning's include, the lights, an instanced texture draw. An extra passes two
    questions, not one: a library has or needs the machinery by the engine bar, and a raylib user would reach for it in raylib's terms.
    Only the second true is a what-if and is refused; only the first is a library item with no extra yet. Lit sprites (Godot's Light2D
    with normal maps, Unity's 2D lights, Phaser's) are a library item by this rule. Rejected: judging extras by raylib's own set alone,
    which leaves the engine with raylib and the async loads; and machinery of its own in an extra.

48. **The WebGL2 adapter sets state once a change, keeps vertex arrays over static buffers, and gives each draw's uniform blocks their
    own buffers in turn.** Measured on the robots page at 200 (2026-11-05): over ANGLE's GL backend a frame took 19 ms against 10 over
    its Vulkan backend, in stalls of 400 to 1100 ms about once a second while the GPU process waited on the driver. The stall was the
    uniform upload: writing a buffer a draw in flight still reads makes the NVIDIA GL driver wait for that draw, a round trip a draw.
    ANGLE's Vulkan backend stages the write itself and never showed it; raylib, Heaps and Lime use plain uniforms and have no buffer to
    collide on. Uniform blocks stay, as the spec has them on every backend, and each binding point gets buffers taken in turn, a draw
    each, enough for three frames of the most draws a frame has made. The GL frame fell to 10.6 ms, Vulkan to 9.8. The state cache and
    the vertex arrays cut the GL calls a draw from 27 to 5 and gave Vulkan a quarter; over GL they moved nothing alone, which is how the
    upload was found. Rejected: one ring buffer a frame bound by range (Vulkan 4x slower, GL unchanged), rotating the skinning palette's
    textures (unchanged), and plain uniforms for small blocks (a second shader dialect).

49. **helix-render's shadows are biased in texels, in the shader, and linked only by a light casting.** Each map is a layer of one
    shadow map a `begin`, drawn by its own pass before the frame's others, its casters drawn depth alone by the color draw's vertex
    stage (skinned and instanced alike) and, for a cut-out material, a fragment stage that discards by `alphaCutoff`. The lit stage
    converts the bias where it reads: a texel's width in the world at the point comes from the map's matrix and size, the lookup moves
    off the surface along its normal by `normalOffset` texels (more where the light grazes) and toward the light by `bias` plus
    `slopeBias` times the slope, capped at 3, so the same settings hold for any map size, reach, or a spot's distance. The earlier C
    frameworks found that a bias in depth units (0.0015) lifted shadows off feet and lost thin parts, which is why the pipeline's depth
    bias goes unused. A directional light's cascades split `distance` by `cascadeSplit`, each a square around its slice's sphere,
    snapped to its texels, so edges hold still as the camera moves and turns. Only one vec4 holds cascade ends, so the first directional
    light following the camera picks by the view's depth and another picks the first map that holds the point. `shadowParams` packs the
    first map, the count, the kind and the radius into its x, as the uniform table leaves four floats for seven values; if a value's
    precision ever shows, the table widens to two vec4 a light. A spot's or a
    point's near plane is a fixed share of its far one, so the shader reads the fade's distance from the depth alone. `castsShadow` is a
    property whose setter installs the work, so a program casting nothing links none of it but the lit stage's shadow GLSL
    (`shadows.glsl`, included under `HELIX_RENDER_SHADOWS`, on unless the program is built with `-D helix_render_no_shadows`: 6.5 KB of
    text, a few hundred bytes compressed, kept in by default since a build chooses once and a game with lights usually wants it). Rejected: the pipeline's depth bias (depth
    units, the earlier frameworks' failure), a cube map for a point light (six layers of the one array keep one sampler), and a uniform
    more in the block (the agreed table is the spec).

50. **A page draws its canvas at the canvas's own size, logical by default, the device's ratio on request.** The page window sized its
    drawing buffer to the viewport times the device's pixel ratio whatever the canvas's box, so a 800 x 450 canvas on a phone drew
    1715 x 3197 pixels, 15 times its own, and the bunnymark took 59 ms a frame there against raylib wasm's 27 (found on the moto g
    over adb, 2026-11-05); at 800 x 450 it takes 19. Now the buffer is the canvas's CSS box (the viewport's where the page gives it
    none) times a ratio its options choose: 1 until `DomWindowAdapterOptions.highDpi`, then the device's, which `pixelRatio` reports so
    the services' screen lays out right. helix-raylib sets it from `FLAG_WINDOW_HIGHDPI` at `InitWindow`: without the flag a page looks
    as raylib's web build does, soft on a dense screen and cheap; with it the canvas is sharp at the ratio squared in pixels filled,
    as raylib's desktop build honours the flag. Rejected: the device's ratio by default (crisp, but three to four times the fill on
    every phone for every program, and not what raylib's page does), and a build define (the program decides at run time, as the API
    has it).

51. **A graphics handle carries its kind, so a handle of another kind is refused on every adapter.** The kind (1 buffer, 2 texture of
    any kind, 3 program, 4 pipeline) is in bits 28 to 30, bit 31 clear so a handle is a positive `Int`, and 0 is still no handle.
    `GraphicsHandle` in the adapters' shared code is the one place that says so: the WebGL2 adapter puts the kind above its counter,
    and `NativeGraphics` puts it above the C's number and takes it off before a call, so the C sees only numbers below 1 << 28
    (`HELIX_HANDLE_MASK`). Each call checks the kind before anything else and throws the message it throws for an unknown handle, the
    same on every adapter: a draw "Invalid draw" (its textures "Invalid draw texture"), a pipeline's program "Invalid pipeline shader",
    a dispose "Invalid buffer", "Invalid texture", "Invalid shader" or "Invalid pipeline". The index buffer is checked only for an
    indexed pipeline, as IGraphics says another ignores it, so `NativeGraphics` keeps which pipelines are indexed. Before, the native
    adapters' kinds each counted from the same slot and generation, so a mixed-up handle reached another kind's table and could be
    taken there. The SDL_GPU adapter now keeps a slot's generation's low 12 bits in a handle (16 before), so a stale handle is taken
    for a new one only after 4096 reuses of its slot. sokol's generation fills its id's top 16 bits, so the sokol adapter keeps its
    handles as the id's low 28 bits and each kind's whole ids by slot, to give a handle its id back. Rejected: the C packing the kind
    itself (the encoding in C and again in Haxe, which checks it to throw), and a map from handle to the C's number (a lookup for
    each handle a draw passes).

52. **helix-raylib is rebuilt on helix-render before helix-render's stages 4 to 7, not after.** 40 put the rebuild after every stage.
    The jam's entrants showed the cost of that order: a glTF's materials (metallic, roughness, flat base colors) are read and kept,
    and helix-raylib's lit path, raylib's examples' lighting.fs mirrored, can't show them, while helix-render's `Material3D` and
    `Shading3D` can. Anything lit, shadowed or material-aware written for helix-raylib on the platform now is written again when it
    moves onto helix-render, so the move comes first and those features arrive as doors onto helix-render's (47). 39's bar is
    unchanged: each size rung may grow by at most 1 to 2 KB gzip and `tools/compare/compare.py` must find the bunnymark, and now the
    robots contender too, no slower than docs/speed.md records, raylib C in the run; otherwise helix-raylib keeps its `Frame`.
    Stages 4 to 7 follow the rebuild, each then reaching helix-raylib's users through an extra at once. Rejected: a PBR shader of
    helix-raylib's own on the platform first (a second lit path, replaced by the move); and raylib's default shader lighting a glTF
    as authored (raylib's default is unlit, and pixel parity is the default oracle, 46).

53. **helix-raylib keeps its `Frame`, helix-render is set aside, and a shared layer waits for its second user.** 52's step one was
    built (branch `raylib-on-render`, unmerged): `Frame` recording into `Renderer`, sprites through a `SpriteRuns2D` that `Batch2D`
    shared, meshes still `Frame`'s own. It drew raylib's pixels and failed both gates, main and branch alternating with raylib C steady
    in the run: +7.1 to +7.5 KB gzip on every rung to 9 and +9.7 at the game rung against 39's 1 to 2 (`Renderer` +11 KB raw, the
    shader service's programs, pipelines and variants +12, `SpriteRuns2D` +7, with 5 leaving `Frame`; every draw through `Renderer`
    was estimated to recover 1.4 KB gzip, a floor near +5.5), and the bunnymark 6% slower at 200k sprites (4.98 to 5.31 ms, raylib C
    12.8), the robots 3%, the cause untraced. Step two would have added `Batch3D`'s 52.7 KB raw. The numbers say the move can't
    reach the bar: the recorded frame, values by handle and copy on write are helix-render's own design, and raylib's API keeps
    `Frame`'s rlgl shape, so a raylib program carries both. Read plainly, nothing outside helix-render links it (its users are its
    examples, tests and size rungs), and the one engine measured on it draws better on the platform directly. So helix-render stays
    on main as built through stage 3, its checks running, set aside until an engine needs it, and stages 4 to 7 come off the queue;
    the one bug the branch found, a `Texture2D.update` in the screen's pass running after the target passes begun after it, went to
    main. The rule taken: a layer shared between engines is extracted from the first engine once the second exists, as `Images` and
    `Matrix3D` were (17) and the shader service was (31), never designed ahead of both; helix-render was built from HeliX's batch
    before any engine ran on it. A retained-mode engine is tried on helix-raylib itself, whose path is the one measured fast and
    small: raylib's API already holds cameras, materials, instancing, skinning, render textures and shaders by location, the scene,
    transforms and sort are the engine's own, and what raylib lacks (lights past four, shadows, environment maps, a linear pipeline,
    stable handles) arrives as extras, whatever proves engine-neutral moving down later. The first is `LoadPbrShader`, on
    helix-raylib with helix-render's BRDF cribbed into `pbr.glsl` so no second BRDF is designed: four programs rather than flags (lit
    and unlit, each skinned), a missing normal map a flat texel, so the fragment stage has no branch, and the material's values
    written by a hook only the shader installs, so a program without it links none of it. Rejected: loosening 39's bar to merge step
    one; a flag per feature in the fragment stage (an uber-shader by increments); helix-services computing a glTF's missing tangents
    at load (1.3 KB gzip on every glTF program for what one shader reads, so it happens at the first draw under the PBR shader
    instead); and an unlit material drawn through raylib's default shader (it reads the base color factor as sRGB bytes, so an unlit
    material drew the wrong color).

54. **A program's shaders are compiled ahead of time and loaded as its other files are.** `LoadShader` and `LoadShaderFromMemory` were
    macros compiling raylib's GLSL into the program as it built, the one load that stayed synchronous; a shader the build didn't hold
    (fetched, a mod's) couldn't load, and compiling at run time was rejected in 31 (megabytes of compiler in a page). Shaders now take
    the textures' path (38): `CompileShaderFile(vsFileName, fsFileName, compiledShaderFileName)`, a `--macro` of the program's build or
    of an hxml of its own, writes the program in every dialect (GLSL ES, GLSL 410, SDL_GPU's) with its uniforms' initializers, so one
    file loads on every target; `LoadCompiledShaderAsync` loads it, and `LoadCompiledShaderFromData` makes one at once from its data
    in memory, as `LoadTextureFromImage` does from pixels. raylib's two calls refuse to compile, naming them. Each name that takes a
    compiled shader says so, as raylib's `LoadShader` takes GLSL files and a twin of the same name would take either. helix-raylib's
    own shaders (`LoadPbrShader`, the lighting and default programs) stay built in, as part of the library, and `-D
    helix-raylib-files` went with the macros, which alone read it. helix-services' `ShaderBuildOptions.everyTarget` compiles every
    dialect in a target's build, as a page and a native program share one files folder. Rejected: keeping `LoadShader` for a shader
    the build holds beside the files (two paths, the one taking constants alone); and `LoadShaderFromMemory` taking compiled bytes
    (raylib's name, another input).

55. **raylib's `Color` is a value, and its other structs copy with `copy`.** C copies a struct on assignment and Haxe shares an object,
    so `var c = RED; c.a = 128;`, raylib's way of fading a color, changed `RED` for the whole program, and a run-4 entrant asked whether a
    map's color was its own. `Color` is now an abstract over an `Int`, its four bytes packed: assigning one copies it, `c.a = 128`
    changes the variable or field `c` names, and no color is ever allocated. raygui's color picker and panel, which write through a
    `Color *`, take it in a one-element array, as its other controls take their pointers. The other value structs (`Vector2` to `Vector4`,
    `Rectangle`, `Matrix`, `Ray`, `BoundingBox`, `Camera2D`, `Camera3D`, `Transform`, `RayCollision`, `NPatchInfo`, `BoneInfo`) stay
    objects, as their floats don't pack, and gain `copy(?out)`, their descriptions saying assignment gives a reference. Handles and
    configs (`Texture2D`, `MaterialMap` and the rest) have no `copy`, as a field copy bypasses their counted references. Rejected: a
    read-only `ConstColor` for the named colors (Haxe infers `var c = RED` as read-only, so reassigning it with a `Color` fails, and an
    explicit `Color` type reopens the hole); a build macro copying on every assignment; and `Color.copy`, which a value has no use for.

56. **A light has a range and an intensity, and the PBR shader tone maps.** rlights' point light doesn't dim with distance and its
    shader clips at white, so four near-white lights clipped the robots' scene to white. `Light.range` and `Light.intensity` are
    helix-raylib's own: within its range a point light falls off with the square of the distance, faded to nothing at the range by glTF's
    `KHR_lights_punctual` window, and intensity multiplies the color of either kind of light. A range of 0, the default, is no falloff,
    and a light's intensity starts at 1 in every lit shader, so `LoadLightingShader` stays raylib's pixel for pixel and a shader whose
    lights a program sets by hand shines as before. One function, `helixLightStrength` in `lights.glsl`, applies them for both lit
    shaders. `LoadPbrShader` tone maps with Khronos PBR Neutral, always: colors in the usual range come out as authored, and brighter
    light rolls off toward white. Rejected: a falloff window alone (not physical, so a lit scene changes as the camera moves, and glTF's
    lights would need converting); and a switch for tone mapping, which a program's own fragment stage over `pbr.glsl` covers.
57. **On-screen sticks are a virtual gamepad.** This revises 13. A virtual gamepad implements `IGamepads` and stands in front of the
    platform's gamepads, in a slot. A game reads its sticks as it reads any gamepad's: `Gamepads.getAxis`, `Actions`, and in
    helix-raylib `GetGamepadAxisMovement`. The first touch plugs it in. A physical gamepad in its slot replaces it, and the next touch
    after that gamepad leaves plugs it in again. It has two sticks, left and right, each with a touch zone, a base placement (floating,
    following or fixed), a radius and a dead zone of 0.12. Bounds cut out of the zones keep a game's buttons free. In helix-raylib,
    `EnableVirtualGamepad` turns it on and the runtime draws it at `EndDrawing`. A finger holding a stick there is no longer the mouse,
    so a tap elsewhere still reaches raygui. Seven trials of the doc comments shaped it. Once core.md pointed to it, every entrant found
    it there. Rejected: a separate sticks service read through calls of its own (the game's gamepad code would ignore it); and reporting
    the axes without the gamepad being available (raylib's usual `IsGamepadAvailable` guard would skip them). On-screen buttons come
    next, as the gamepad's buttons.
58. **On-screen buttons are the virtual gamepad's buttons.** A `VirtualButton` is a circle read as one gamepad button. The buttons
    capture a finger landing on one of them until it lifts: a button is down while a finger the buttons captured is within its circle. A
    thumb slides from one button onto another. Fingers the buttons captured stay with the buttons, away from the sticks and the mouse. Buttons are drawn from the moment the virtual
    gamepad is enabled, on a device with touch, as is a fixed stick at rest: each has a place, where a floating stick has none until a
    finger lands. `Gamepads` reads every button's state each poll and treats a change since the last poll as a press or a release, which
    the events have already made for a physical gamepad. One trial of the doc comments found no guess about the buttons. Rejected: the
    virtual gamepad adding `GamepadButtonDown` and `GamepadButtonUp` to the events (the events are the adapters' record, and helix-raylib's
    replay would count them twice); held until the finger lifts (a thumb couldn't slide between buttons); and rectangles (the sticks are
    circles, and so are most games' touch buttons). A face button without a position takes its place in a diamond at the window's
    bottom-right corner, in the service beside the sticks' default zones; helix-raylib labels the face buttons A, B, X and Y. Sticks and buttons take images and a label font, and a program draws its own
    controls from `visible: false` and the sticks' read-backs (`GetVirtualStickBase`, `GetVirtualStickKnob`, `IsVirtualStickHeld`,
    `IsVirtualGamepadVisible`). Three trials shaped these: the third had to blank four colors to hide a stick, which `visible` replaced.
59. **Tilt is a stick of the virtual gamepad.** A stick with `tilt` reads the device's tilt in place of a finger, past the stick's dead
    zone, and a tilt-steered game reads it as any gamepad's stick. The ROADMAP's separate tilt gamepad would have wanted the same slot
    as the virtual gamepad, whose buttons a tilt game needs (gas, brake, fire). The game turns the tilt on itself (`EnableTiltAsync`), as
    helix-legacy's Tilt button did: a browser asks only at a tap, and the game hears a refusal and offers a finger stick. helix-raylib
    gains `GetTiltStatus` and `IsTiltCalibrating`, for "tap to allow tilt" and "hold steady", which helix-legacy's states gave a game.
    The platform's `TiltStatus` gains `Starting`, between the ask and the first reading: without it the status read Off there where no
    tap is asked, and WaitingForTap after the tap on iOS, so "tap to allow tilt" stayed up after the tap that allowed it. The tilt plugs
    the virtual gamepad in, as a touch does: a phone that asks no permission has no tap to wait for. The virtual gamepad reads the tilt
    only once a tilt function has made it, so a program without one links no tilt adapter. One trial of the doc comments found no
    guess about the tilt, and a review found the rest. Rejected: a `TiltGamepad` beside the virtual gamepad (two gamepads in
    one slot); asking for the tilt when the virtual gamepad is enabled (the game would never hear the answer); and a third stick (a
    gamepad has two, and its axes end there).
60. **helix-raylib is raylib 5.5's API and its redirects, nothing more.** This revises 38, 42, 45, 47's extras, 53's lit extras, and 56
    to 59 for helix-raylib. The API is raylib 5.5's, with raygui, raymath, rlgl and rlights (`helix.raylib.Rlights`, as
    raygui is `Raygui`). A redirect is a raylib call that can't keep its promise on every target: it refuses to compile on every
    target, and its message names the call that replaces it, in `helix.raylib.extras`. The async loads and writes, the window
    requests and the compiled shaders are those. The program never learns where it runs. A call no redirect reaches leaves the
    library: `extras.Device` (the safe area, run options, the device, the window's abilities, orientation and tilt),
    `extras.VirtualGamepad`, `extras.Debug`, `extras.GuiSkins`, `extras.Sprites`, `LoadModelFromModels`, `GetModelBoundingBoxPosed`,
    `LoadLightingShader` and `LoadPbrShader` with their shader includes, and `Material.unlit`. What they built on stays in the
    libraries below for any engine: helix-services' virtual sticks, buttons and tilt, helix-geometry's `Mesh3D.merge`. raylib 6.2's
    `UpdateModelAnimationEx` stays for now, for a trial of whether a blend is reached by a refusal of `UpdateModelAnimation`, a
    warning, or neither. The `emscripten_run_script` refusals say only "Not supported". Why: three Sonnet entrants wrote the Wardens
    spec in C on stock raylib 5.5 (2026-11-09), and everything they gated on `PLATFORM_WEB` was a redirect here or the page's work
    underneath (the URL's options, saves, fullscreen, taps shorter than a frame, the main loop), but for whether the screen is touched,
    which the first touch answers. Agents given helix-raylib's docs never reached for `LoadModelFromModels` unprompted, and two of the
    three C entrants merged their characters by hand. A raylib developer knows raylib's API and nothing else of ours, so what the
    compiler can't lead to isn't found. Rejected: moving the extras to a `helix-raylib-extras` (the same drift under another name).
61. **helix-raylib keeps opt-in extras beside raylib's API.** This revises 60. An agent writing from raylib's API never finds an extra,
    but a developer reading the README does, so an extra that saves a program real work comes back, in `helix.raylib.extras`, linked
    only by a program that calls it: `extras.Lighting` (`LoadLightingShader` and `LoadPbrShader`, with `lights.glsl`, `pbr.glsl` and
    `Material.unlit`), `extras.VirtualGamepad`, and `LoadModelFromModels` and `GetModelBoundingBoxPosed` in `extras.Models`. rlights
    stays raylib's: `Light` keeps rlights' fields alone, and a PBR light's range and intensity are its shader's uniforms, set as any
    is. The virtual gamepad's tilt stick doesn't come back, as nothing turns the tilt on without `extras.Device`. Why: every Wardens
    entrant (2026-11-10, C on stock raylib 5.5 and helix-raylib blind) wrote its own lit, skinned shader, its own touch stick and
    buttons, and most read the glTF's roughness themselves. Two of three earlier C entrants merged their characters' meshes. Still out:
    `extras.Device`, `extras.Debug`, `extras.GuiSkins`, `extras.Sprites`.
62. **`extras.Device` is back, opt-in.** This revises 61's "still out". A game on a phone asks what raylib has no call for: the part of
    the window a notch leaves, whether the device has touch or a mouse, holding the screen one way up, the tilt. `extras.Device`
    answers each on every target, linked only by a program that calls one, with the virtual gamepad's tilt stick. Its run options
    stay gone, as `Sys.args()` reads the command line on every target. `IsPlatformWeb` is known as the program builds, the same answer
    as `#if js`. The `emscripten_run_script` refusals name the Device call that answers what a C program asks the page.
