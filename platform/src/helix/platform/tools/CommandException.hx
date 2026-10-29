package helix.platform.tools;

/** A command's refusal: its message (the command's name first, "site: ..."), said on the standard error before the front door exits with 1. */
class CommandException extends haxe.Exception {}
