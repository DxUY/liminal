extends Node2D

@export var map: CompressedTexture2D
@onready var texture_rect: MeshInstance2D = %TextureRect

func _ready() -> void:
	GameEvents.game_started.connect(_on_game_started)

func _on_game_started() -> void:
	pass
