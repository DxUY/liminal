class_name SpellComponent extends Node

func _ready() -> void:
	add_to_group(SaveManager.SAVABLE_GROUP)

func get_save_id() -> String:
	return "spell"

func save_data() -> Dictionary:
	return {
		"spells": [] # Your saved spell dictionaries/strokes go here
	}

func load_data() -> void:
	pass

func get_current_spells() -> Array[Dictionary]:
	return []
