@tool
extends EditorPlugin
## Class-library addon: DataItem, GameDatabase, DatabaseConfig and DatabaseGenerator
## register via class_name and need no editor hooks. Auto-regeneration of the baked
## database lives in database_auto_regen.gd, which references FileSystemMonitor
## classes — a peer dependency this entry script deliberately does NOT name, so the
## addon still compiles without it (classes usable, generator runnable manually).

const MONITOR_CLASS_NAME: StringName = &"DH_FileSystemMonitorPlugin"

var _auto_regen: Node


func _enter_tree() -> void:
	if not _is_file_system_monitor_installed():
		push_warning("GameDatabase: FileSystemMonitor addon not found — auto-regeneration off. Install https://github.com/diablohumastudio/dhs-gd-fw-file-system-monitor at addons/diablohumastudio_framework/file_system_monitor, or run the generator EditorScript manually.")
		return
	# Addon-relative dynamic path: keeps the peer dependency out of this script's
	# parse step and survives the addon folder being relocated.
	var auto_regen_script: GDScript = load((get_script() as Script).resource_path.get_base_dir() + "/database_auto_regen.gd")
	_auto_regen = auto_regen_script.new()
	add_child(_auto_regen)


func _is_file_system_monitor_installed() -> bool:
	for global_class: Dictionary in ProjectSettings.get_global_class_list():
		if global_class["class"] == MONITOR_CLASS_NAME:
			return true
	return false
