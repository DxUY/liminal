extends Node

## Registered as autoload "SaveManager". Third in the autoload list
## Walks the saveable group at save time, collect Dictionaries, writes JSON.
## At load time, reads JSON and distributes data back by save ID

# Constants
const SAVABLE_GROUP: StringName = &"savable"
const SAVE_VERSION: int = 1
const SAVE_DIR: String = "user://saves/"
const SAVE_FILE: String = "save_%d.json"

func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(SAVE_DIR)
	print("SaveManager: Ready. Save Directory: ", SAVE_DIR)

## Save all savable nodes to the given slot (default 0)
func save(slot: int = 0) -> void:
	var data: Dictionary = {
		"version" = SAVE_VERSION,
		"timestamp" = Time.get_datetime_string_from_system(),
	}

	for node: Node in get_tree().get_node_in_group(SAVABLE_GROUP):
		if node.has_method("save_data") and node.has_method("get_save_id"):
			var id: String = node.get_save_id()
			data[id] = node.save_data()

	var path: String = SAVE_DIR + (SAVE_FILE % slot) #save_0.json
	var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		push_error("SaveManager: Could not open '%s' for writing." % path)
		return
	file.store_string(JSON.stringify(data, "\t"))
	file.close()

	print("SaveManager: Saved to slot %d." % slot)
	GameEvents.game_saved.emit(slot)

func load_game(slot: int = 0) -> void:
	var path: String = SAVE_DIR + (SAVE_FILE % slot)
	if not FileAccess.file_exists(path):
		push_error("SaveManager: No save file at '%s'." % path)
		return

	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("SaveManager: Could not open '%s' for reading." % path)
		return
	var raw: String = file.get_as_text()
	file.close()

	var parsed: Variant = JSON.parse_string(raw)
	if parsed == null:
		push_error("SaveManager: JSON parse failed for '%s'." % path)
		return

	var data: Dictionary = parsed as Dictionary

	# Version Check!
	var version: int = data.get("version", 0)
	if version < SAVE_VERSION:
		_migrate(data, version)

	# Load the data!
	for node: Node in get_tree().get_nodes_in_group(SAVABLE_GROUP):
		if node.has_method("load_data") and node.has_method("get_save_id"):
			var id: String = node.get_save_id()
			if data.has(id):
				node.load_data(data[id])

	print("SaveManager: Loaded from slot %d." % slot)
	GameEvents.game_loaded.emit(slot)

## Migrate a save file from an older version to the current version!
func _migrate(_data: Dictionary, from_version: int) -> void:
	print("SaveManager: Migrating from v%d to v%d." % [from_version, SAVE_VERSION])
	# Future: data["new_field"] = default_value
	pass
