package helix.tools.shared;

/** A command's refusal: its message (the command's name first, "site: ..."), said on the standard error before the front door exits with 1. */
class CommandError extends haxe.Exception {}
