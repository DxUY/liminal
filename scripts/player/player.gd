class_name Player extends Control

@onready var mouse_component: MouseComponent = %MouseComponent
@onready var keyboard_component: KeyboardComponent = %KeyboardComponent

func _ready() -> void:
	GameEvents.game_started.connect(_on_game_started)
	add_to_group(SaveManager.SAVABLE_GROUP)

func _on_game_started() -> void:
	return

func _process(_delta: float) -> void:
	return

#region Savable Contract

func get_save_id() -> String:
	return "player"

func save_data() -> Dictionary:
	return {}

func load_data() -> void:
	pass

#endregion
