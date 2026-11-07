# helix.services.config

[Back to the library](README.md)

## Config

*class* in [`libs/services/src/helix/services/config/Config.hx`](../src/helix/services/config/Config.hx), `import helix.services.config.Config;`

Provides the options the program was started with, read as text, numbers or true and false, each with a fallback.

Options come from `ISystem.getOption`. Natively an option is on the command line, or else an environment variable named HELIX_ followed by the option's name in capitals. In a page it is a query parameter in the URL. The option `speed=2` is `--speed=2` or `HELIX_SPEED=2` natively and `?speed=2` in a page.

```haxe
var sound = config.getBool("audio", true);
time.scale = config.getFloat("speed", 1);
```

```haxe
function new(system:ISystem)
function hasOption(name:String):Bool
function getString(name:String, fallback:String):String
function getBool(name:String, fallback:Bool):Bool
function getInt(name:String, fallback:Int):Int
function getFloat(name:String, fallback:Float):Float
```

- `new`: Creates the options over the platform's system.
  - `system`: The platform's system, whose `getOption` it reads.
- `hasOption`: Returns whether an option was provided.
  - `name`: The option's name.
  - returns: True when it was provided, even with an empty value.
- `getString`: Returns an option's text, unchanged.
  - `name`: The option's name.
  - `fallback`: The value to return when the option wasn't provided.
  - returns: Its text, or the fallback.
- `getBool`: Returns an option as true or false.
  - `name`: The option's name.
  - `fallback`: The value to return when the option wasn't provided, or is none of those words.
  - returns: The value, or the fallback.

  1, true, yes and on are true. 0, false, no and off are false. Case is ignored, and so are spaces around the value.
- `getInt`: Returns an option as a whole number.
  - `name`: The option's name.
  - `fallback`: The value to return when the option wasn't provided, or isn't a whole number in Int's range.
  - returns: The value, or the fallback.
- `getFloat`: Returns an option as a number.
  - `name`: The option's name.
  - `fallback`: The value to return when the option wasn't provided, or isn't a finite number.
  - returns: The value, or the fallback.
