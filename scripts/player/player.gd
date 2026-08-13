class_name Player extends Node2D

@onready var mouse_component: MouseComponent = %MouseComponent
@onready var keyboard_component: KeyboardComponent = %KeyboardComponent
@export var canvas_logic: CanvasLogic

@export var min_brush_size: int = 1
@export var max_brush_size: int = 6

func _ready() -> void:
	GameEvents.game_started.connect(_on_game_started)
	add_to_group(SaveManager.SAVABLE_GROUP)
	
	if canvas_logic:
		canvas_logic.initialize()

func _on_game_started() -> void:
	return

func _process(delta: float) -> void:
	var mouse_state: Dictionary = mouse_component.get_mouse_state()
	
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) and canvas_logic:
		# Calculate speed (distance moved this frame)
		var distance: float = mouse_state["position"].distance_to(mouse_state["previous"])
		
		# Map speed to brush size: fast = thin, slow = thick
		var normalized_speed: float = clamp(distance / 25.0, 0.0, 1.0)
		var speed_mapped_size: int = int(lerp(float(max_brush_size), float(min_brush_size), normalized_speed))
		
		canvas_logic.process_drawing(mouse_state["position"], mouse_state["previous"], speed_mapped_size)

#region Savable Contract

func get_save_id() -> String:
	return "player"

func save_data() -> Dictionary:
	return {}

func load_data() -> void:
	pass

#endregion
