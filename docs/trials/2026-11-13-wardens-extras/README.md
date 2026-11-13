# Wardens with the extras (2026-11-13)

Whether helix-raylib's extras make Wardens cheaper, quicker or more correct to build than raylib alone. Six fresh Sonnet agents built
[Wardens](../wardens/spec.md) natively, as the blind trials do ([../README.md](../README.md)), against one commit of helix:

- **Without the extras** (`helix-raylib-blind.016` to `.018`): the blind trials' brief, raylib 5.5's headers and examples alone.
- **With the extras** (`helix-raylib-docs.001` to `.003`): the same, with [a brief](../wardens/native/brief-extras.md) adding one line
  that points at the extras, and the extras' doc comments as their generated API page (`engines/raylib/api/extras.md`) in
  `docs/extras.md` (`run_entrant.py --extras`).

The spec asks for what the extras do without naming them: her parts posed as one, her attacks from the waist up while she moves
(`Models`), materials drawn as authored, metallic and roughness honoured (`Lighting`), and touch controls (`VirtualGamepad`). For this
trial it gained the attack on the move, and the gun's 90 degree arc in front of her, which keeps her upper body from turning to a
target behind her. The blind runs before it were on the spec without either, and aren't compared here.

## Runs

Started together on coinspinner, 3 hours each at most, against helix at the masked blend's trial (`b47a70d`).
