class_name DatabaseGenerator extends RefCounted
## Scans the folders in a DatabaseConfig and bakes a GameDatabase at
## config.output_path. No game types and no cross-reference validation —
## id refs are validated at assignment by their owners' setters.

static func generate(config: DatabaseConfig) -> void:
	var database: GameDatabase = GameDatabase.new()
	for type_name: StringName in config.type_folders:
		var type: Script = _script_for(type_name)
		if type == null:
			continue
		database.paths_by_type[type_name] = _collect_paths(config.type_folders[type_name], type)
	ResourceSaver.save(database, config.output_path)
	print("%s generated (%d types)." % [config.output_path, config.type_folders.size()])

# Resolves a class_name to its Script via the global class list.
static func _script_for(type_name: StringName) -> Script:
	for global_class: Dictionary in ProjectSettings.get_global_class_list():
		if global_class["class"] == type_name:
			return load(global_class["path"])
	push_error("DatabaseGenerator: unknown class_name " + type_name)
	return null

# Recursive; is_instance_of already rejects off-type files, so no folder blacklist.
static func _collect_paths(folder: String, type: Script) -> PackedStringArray:
	var paths: PackedStringArray = []
	var dir: DirAccess = DirAccess.open(folder)
	if dir == null:
		push_error("DatabaseGenerator: cannot open " + folder)
		return paths
	dir.list_dir_begin()
	var entry: String = dir.get_next()
	while entry != "":
		var full_path: String = folder + "/" + entry
		if dir.current_is_dir():
			if entry != "." and entry != "..":
				paths.append_array(_collect_paths(full_path, type))
		elif entry.ends_with(".tres"):
			if is_instance_of(load(full_path), type):
				paths.append(full_path)
		entry = dir.get_next()
	dir.list_dir_end()
	return paths
