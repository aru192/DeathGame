# Validation report

Validated on Windows with the official Godot `4.7.2.stable.official.ed1daf0bf` binary.

## Automated gameplay smoke test

Command:

```powershell
& '.\.tools\godot-4.7.2\Godot_v4.7.2-stable_win64_console.exe' --headless --path . tests/smoke_test.tscn
```

Result: `SELF_TEST PASS: all gameplay systems exercised`

The test verifies all eight Input Map actions, configured main scene, title-to-game transition, level/enemy/hazard spawning, movement, jumping, attack startup, dodge stamina and invulnerability, enemy defeat, checkpoint refill/save, death count, fast respawn, pause/resume, boss intro and HP bar, phase-two transition, and boss defeat.

## Persistence test

`tests/save_writer.tscn` writes deaths/checkpoint/audio configuration. A separate Godot process running `tests/save_reader.tscn` loads it.

Results:

- `PERSISTENCE WRITE PASS`
- `PERSISTENCE READ PASS`

An intentionally malformed JSON save was also loaded. The main scene opened with defaults and without a script error.

## Import and visual verification

- Editor import completed under Godot 4.7.2 with every `.gd`, `.tres`, `.tscn`, and PNG dependency resolved.
- Main title was run through the GL Compatibility renderer at 1280×720.
- Gameplay and boss phase-two scenes were rendered through Godot's Movie Maker path.
- Reviewed captures are stored under `verification/title`, `verification/gameplay`, and `verification/boss`.

The only headless-host message was inability to read the Windows root certificate store in the sandbox. The project does not use networking and normal GL-rendered runs were unaffected.

## Editor-authoring refactor

The project was subsequently migrated from runtime-generated permanent layout to authored scenes. Godot 4.7.2 re-import and the complete gameplay smoke test passed after the migration.

- `level.tscn`: 21 editable platforms/boundaries, 13 hazards, 10 enemies, 2 checkpoints, player and boss
- `title_screen.tscn`: 12 directly editable UI nodes
- `hud.tscn`: directly editable status, boss, message, debug and pause UI nodes
- Player, enemy, hazard, checkpoint, boss, platform and backdrop scripts provide editor previews with `@tool`
- Post-refactor GL Compatibility capture: `verification/editor_final/`
