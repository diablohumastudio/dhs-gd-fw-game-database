@tool
extends Node
## Auto-regenerates the baked database when a .tres is created/deleted/moved
## inside a configured type folder — the database stores only paths, so in-place
## edits never rebake. Split from the plugin entry script because it references
## FileSystemMonitor classes (a peer dependency): the plugin only instantiates
## this node after verifying the monitor addon is installed, so the addon still
## compiles without it. The game points the addon at its config via
## CONFIG_PATH_SETTING.

const CONFIG_PATH_SETTING: String = "diablohumastudio/game_database/config_path"
const REGEN_DEBOUNCE_SEC: float = 1.0

var _config: DatabaseConfig
var _regen_timer: Timer


func _ready() -> void:
	_load_config()
	_create_regen_timer()
	# Deferred: plugin load order is not guaranteed, so the monitor may not
	# have entered the tree yet.
	_connect_monitor.call_deferred()


func _exit_tree() -> void:
	var monitor: DH_FileSystemMonitorPlugin = DH_FileSystemMonitorPlugin.instance
	if monitor and monitor.changes_detected.is_connected(_on_files_changed):
		monitor.changes_detected.disconnect(_on_files_changed)


func _load_config() -> void:
	var config_path: String = ProjectSettings.get_setting(CONFIG_PATH_SETTING, "")
	if config_path.is_empty():
		push_warning("GameDatabase: project setting '%s' not set — auto-regeneration off." % CONFIG_PATH_SETTING)
		return
	_config = load(config_path) as DatabaseConfig
	if _config == null:
		push_error("GameDatabase: '%s' is not a DatabaseConfig — auto-regeneration off." % config_path)


# This node has no scene, so the debounce Timer is created dynamically.
func _create_regen_timer() -> void:
	_regen_timer = Timer.new()
	_regen_timer.one_shot = true
	_regen_timer.timeout.connect(_on_regen_timer_timeout)
	add_child(_regen_timer)


func _connect_monitor() -> void:
	var monitor: DH_FileSystemMonitorPlugin = DH_FileSystemMonitorPlugin.instance
	if monitor == null:
		push_warning("GameDatabase: FileSystemMonitor plugin not enabled — auto-regeneration off (run the generator EditorScript manually).")
		return
	if not monitor.changes_detected.is_connected(_on_files_changed):
		monitor.changes_detected.connect(_on_files_changed)


func _on_files_changed(changes: DH_FSM_ChangeSet) -> void:
	if _config == null:
		return
	if _any_watched_data_file_changed(changes):
		_regen_timer.start(REGEN_DEBOUNCE_SEC)   # restart = debounce


# modified_file_paths is deliberately ignored: the baked database stores only
# paths, so editing a .tres in place never changes the bake.
func _any_watched_data_file_changed(changes: DH_FSM_ChangeSet) -> bool:
	for file_path: String in changes.created_file_paths:
		if _is_watched_data_file(file_path):
			return true
	for file_path: String in changes.deleted_file_paths:
		if _is_watched_data_file(file_path):
			return true
	for move: DH_FSM_Move in changes.moved_files:
		if _is_watched_data_file(move.from_path) or _is_watched_data_file(move.to_path):
			return true
	return false


func _is_watched_data_file(file_path: String) -> bool:
	if not file_path.ends_with(".tres"):
		return false
	if file_path == _config.output_path:
		return false   # our own bake — never loop on it
	for folder: String in _config.type_folders.values():
		if file_path.begins_with(folder.trim_suffix("/") + "/"):
			return true
	return false


func _on_regen_timer_timeout() -> void:
	DatabaseGenerator.generate(_config)
