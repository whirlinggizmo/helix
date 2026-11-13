# helix-raylib's defines

[Back to the library](README.md)

Set in a build's hxml, as `-D helix-raylib-native-root=../assets`. `haxe --help-user-defines` lists them too, and an editor completes them in an hxml file.

- `helix-raylib-native-root=<directory>`: Where a native program finds its files, relative to its own directory. Defaults to ../web.
- `helix-raylib-host-warnings`: Warns where the program's own code reaches the page (localStorage, the page's fullscreen) for what Raylib answers on every target, naming the call. Off by default.
- `helix-raylib-portable-sys`: Gives a page a Sys (the program's options from the URL's query, the console and the clock) and refuses on every target what a page can't answer: Haxe's file calls (sys.io.File, sys.FileSystem), sys.io.Process and the Sys calls a page has no answer for, each refusal naming the raylib call to use. So a program that builds natively builds for the page. Off by default, when a build is Haxe's as shipped.
- `helix-raylib-frame-stats`: For timing a program without changing it: with the frame_stats option (--frame_stats=120,1200 natively, ?frame_stats=120,1200 in a page), records frames 121 to 1200, prints the stats as frame_stats and a JSON object, and closes the window. In a page the object is also window.helixResult. Off by default.
- `helix-raylib-custom-frame-control`: raylib's SUPPORT_CUSTOM_FRAME_CONTROL: EndDrawing only draws, and the program calls SwapScreenBuffer, WaitTime and PollInputEvents itself.
