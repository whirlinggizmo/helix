# helix-math's defines

[Back to the library](README.md)

Set in a build's hxml, as `-D helix-math-standard-trig`. `haxe --help-user-defines` lists them too, and an editor completes them in an hxml file.

- `helix-math-standard-trig`: Makes Trig's functions the standard library's (Math.sin and the others), and with them the cosines and sines helix-math's rotations take. Faster in a browser. A result's last bit may then differ between targets, so a simulation no longer plays alike on each. Off by default.
