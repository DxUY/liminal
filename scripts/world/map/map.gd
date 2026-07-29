extends Control

@onready var path_generator: PathGenerator = %PathGenerator

func _ready() -> void:
	GameEvents.game_started.connect(_on_game_started)

func _on_game_started() -> void:
	return
