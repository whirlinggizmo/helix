# helix.services.config

[Back to the index](README.md)

## Config

*class* in [`services/src/helix/services/config/Config.hx`](../../services/src/helix/services/config/Config.hx), `import helix.services.config.Config;`

Provides the options the program was started with, read as text, numbers or true and false, each with a fallback.

Natively an option is the environment variable HELIX_ and its name in capitals, in a page the URL's query parameter (`ISystem.getOption`): `speed=2` is `HELIX_SPEED=2` natively and `?speed=2` in a page.

```haxe
var sound = config.getBool("audio", true);
time.scale = config.getFloat("speed", 1);
```

```haxe
function new(system:ISystem)
function has(name:String):Bool
function getString(name:String, fallback:String):String
function getBool(name:String, fallback:Bool):Bool
function getInt(name:String, fallback:Int):Int
function getFloat(name:String, fallback:Float):Float
```

- `new`: Creates the options over the platform's facts.
  - `system`: The platform's facts, whose `getOption` it reads.
- `has`: Returns whether an option was given.
  - `name`: The option's name.
  - returns: True when it was, even empty.
- `getString`: Returns an option as it was given.
  - `name`: The option's name.
  - `fallback`: What to return when it wasn't given.
  - returns: Its text, or the fallback.
- `getBool`: Returns an option as true or false: 1, true, yes and on are true, 0, false, no and off false, in any case.
  - `name`: The option's name.
  - `fallback`: What to return when it wasn't given, or is none of those.
  - returns: The value, or the fallback.
- `getInt`: Returns an option as a whole number.
  - `name`: The option's name.
  - `fallback`: What to return when it wasn't given, or isn't a whole number.
  - returns: The value, or the fallback.
- `getFloat`: Returns an option as a number.
  - `name`: The option's name.
  - `fallback`: What to return when it wasn't given, or isn't a finite number.
  - returns: The value, or the fallback.
