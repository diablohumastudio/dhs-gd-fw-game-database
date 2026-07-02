class_name DatabaseConfig extends Resource
## Which DataItem types a database indexes, where their .tres live, and where the
## baked database is saved. The game authors one database_config.tres; adding a new
## entity type = one entry there. Generic — zero game types.

@export var type_folders: Dictionary[StringName, String] = {}
@export var output_path: String
