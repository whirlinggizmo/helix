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
    the extension too, so it gains `loadGltf` and `loadObj` beside it, and helix-ray's glTF reader calls `loadGltf`: any engine on the
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
    configuration rather than fixing anything, and so is FLAC music (`LoadMusicStream`, `LoadMusicStreamFromMemory`). Decoders that read an MP3's LAME tag (SDL3_mixer's dr_mp3 0.7.4, Chromium's) trim the
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
