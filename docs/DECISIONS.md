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
