# GameDatabase

Generic, data-driven index for designer `.tres` resources. Zero game types — the game
contributes only a config resource and a thin typed repository on top.

## What it provides

- **`DataItem`** — base `Resource` with `id: StringName`, the stable primary key every
  top-level designer resource inherits (database indexing, save keys, event routing).
- **`GameDatabase`** — baked index resource: `paths_by_type` maps a class name to its
  `.tres` paths; generic `get_all(type)` / `get_by_id(type, id)` / `get_ids(type)` with a
  lazy per-type id→item cache (O(1) by-id lookups).
- **`DatabaseConfig`** — which `DataItem` types to index, which folder each lives in, and
  where the baked database is saved.
- **`DatabaseGenerator`** — scans the config's folders and bakes the `GameDatabase`.
- **Auto-regeneration** (`database_auto_regen.gd`) — rebakes automatically (1s debounce)
  when a `.tres` is created/deleted/moved inside a configured folder. In-place edits never
  rebake (the bake stores only paths); the bake output itself is excluded (no loop).

## Game-side setup

1. Author a `database_config.tres` (type folders + `output_path`).
2. Point the addon at it via the project setting:
   ```
   [diablohumastudio]
   game_database/config_path="res://path/to/database_config.tres"
   ```
3. Optionally keep a tiny EditorScript that calls `DatabaseGenerator.generate(CONFIG)` as a
   manual fallback (File → Run).
4. Read data through your own typed repository (e.g. an autoload wrapping
   `GameDatabase.get_by_id(LevelData, id)`).

## Peer dependency

Auto-regeneration requires the **FileSystemMonitor** addon
(https://github.com/diablohumastudio/dhs-gd-fw-file-system-monitor) installed at
`addons/diablohumastudio_framework/file_system_monitor`. Without it the addon still
compiles and the classes/generator work — only auto-regeneration is disabled (a warning
says so). The plugin entry script checks for the monitor before loading the auto-regen
node, so no parse errors leak from the missing dependency.
