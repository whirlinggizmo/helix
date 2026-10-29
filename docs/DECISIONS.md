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
    (`[HttpServer(url), FileSystem(shipped)]`): online the server's version wins, offline or for a file the server doesn't have the
    shipped one answers. A shipped file its manifests list at the server's hash is read in place, so a first run downloads only what
    changed. The shipped tree carries the same manifests (`AssetManifests` writes both at once, as the same tree), since a file system
    has no size or time to keep a run-time hash honest, and hashing a file to stream it would read it whole. Manifests are looked for by
    default (`AssetsOptions.manifestName`): a server without them costs one request a run and falls back to the cache mode, and the
    tree is HeliX's, wgrender-c's and libwgt's, where an unchanged directory is known from its parent alone. None of them seeded from
    shipped files; each read local files in place and never checked them.
