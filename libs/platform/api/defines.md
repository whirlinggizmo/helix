# helix-platform's defines

[Back to the library](README.md)

Set in a build's hxml, as `-D helix-product=Asteroids` (quoted when the value has a space: `-D "helix-company=Whirling Gizmo"`). `haxe --help-user-defines` lists them too, and an editor completes them in an hxml file.

- `helix-company=<name>`: The company that makes the program, one directory's name. ISystem's data and cache directories are under it, and natively SDL names the program by its product. Required by every program: a build without it fails.
- `helix-product=<name>`: The program's name, one directory's name. ISystem's data and cache directories are under the company and it, and natively SDL names the program by it, in the OS's audio mixer for one. Required by every program: a build without it fails.
