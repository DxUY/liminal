extends Control

@export var map: CompressedTexture2D

@onready var import_component: ImportComponent = %ImportComponent
@onready var element_mapped_component: ElementMappedComponent = %ElementMappedComponent

func _ready() -> void:
	GameEvents.game_started.connect(_on_game_started)

func _on_game_started() -> void:
	if map == null:
		push_error("No map assigned.")
		return

	# Import the source imported_image.
	var imported_image := import_component.import_compressed(map)
	if imported_image == null: return
