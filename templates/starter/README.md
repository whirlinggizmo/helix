# {title}

A game on [HeliX](https://github.com/whirlinggizmo/helix) (`-lib helix`). `src/Game.hx` is the game, `src/Main.hx` starts it. The builds
are in `hxml/`, each run from this directory:

```console
haxe hxml/dev.hxml                # the dev loop: open http://localhost:8064/, edit, save; the page takes the new code as it runs, and shaders/<name>.glsl as they change
haxe hxml/build.web.hxml          # the browser build alone, out/web/
haxe hxml/build.dist.hxml         # the release build for hosting: out/dist/, zipped as out/{name}-web.zip (itch.io)
haxe hxml/serve.dist.hxml         # out/dist/ served at http://localhost:8095/, to try before uploading
haxe hxml/build.native.hxml       # the native build (hxcpp), out/native/Main; it reads assets/ beside itself: copy (or link) the directory to out/native/assets
```

`common.hxml` holds what every build shares; the build steps are macros in `helix.tool` (`Build`, `Watchers`, `WebServer`). `favicon.svg` is the page's icon: put
the game's own there. The shader compiler is fetched the first time a shader is packed; `haxelib run helix setup` fetches it ahead,
before going offline say.
