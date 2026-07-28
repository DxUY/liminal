extends Node2D

@onready var path_generator: PathGenerator = %PathGenerator
@onready var grid_simulator: GridSimulator = %GridSimulator
@onready var renderer: Renderer = %Renderer

func _ready() -> void:
	GameEvents.game_started.connect(_on_game_started)

func _on_game_started() -> void:
	var image: Image = path_generator.generate()
	grid_simulator.initialize(image)
	renderer.initialize(grid_simulator.get_current_texture(), grid_simulator.width, grid_simulator.height)
