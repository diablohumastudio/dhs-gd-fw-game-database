class_name GameDatabase extends Resource
## Baked index of all designer data, produced by DatabaseGenerator. `paths_by_type`
## (saved) maps a DataItem class name -> its .tres paths. At runtime the generic
## getters lazily load those into an id->item dict per type and cache it (O(1) by-id).
## Pass the class itself as `type`, e.g. get_all(LevelData). Generic — zero game types.

@export var paths_by_type: Dictionary[StringName, PackedStringArray] = {}

var _index_by_type: Dictionary[StringName, Dictionary] = {}   # class name -> { StringName id: DataItem }

func get_all(type: Script) -> Array:
	return _index_for(type).values()

func get_by_id(type: Script, id: StringName) -> DataItem:
	return _index_for(type).get(id, null)

# All ids of a type. (Consumed by the future selector dropdown.)
func get_ids(type: Script) -> Array:
	return _index_for(type).keys()

func _index_for(type: Script) -> Dictionary:
	var type_name: StringName = type.get_global_name()
	if _index_by_type.has(type_name):
		return _index_by_type[type_name]
	var index: Dictionary = {}
	for path: String in paths_by_type.get(type_name, PackedStringArray()):
		var item: DataItem = load(path)
		if item == null:
			push_error("GameDatabase: failed to load " + path)
			continue
		if not item.id:
			push_error("GameDatabase: empty id in " + path)
			continue
		if index.has(item.id):
			push_error("GameDatabase: duplicate id '%s' for type %s (%s)" % [item.id, type_name, path])
		index[item.id] = item
	_index_by_type[type_name] = index
	return index
