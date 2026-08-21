class_name Cast extends State

@export var canvas_logic: CanvasLogic
@export var distortion_rect: TextureRect

@export_category("Brush setting")
@export var min_brush_size: int = 1
@export var max_brush_size: int = 6

@export_category("Spell Component")
@export var spell_component: SpellComponent

var can_draw: bool = false
var recognizer: Recognizer

var current_stroke: PackedVector2Array = []
var all_strokes: Array[PackedVector2Array] = []

func enter() -> void:
	can_draw = false
	canvas_logic.initialize()
	
	recognizer = Recognizer.new()
	
	if spell_component:
		recognizer.load_templates(spell_component.get_current_spells())
	else:
		recognizer.load_templates([])
	
	all_strokes.clear()
	current_stroke.clear()
	
	_animate_distortion(true, func(): can_draw = true)

func _process(_delta: float) -> void:
	if not can_draw: return
	
	if player.mouse_component.is_pressed(&"draw"):
		current_stroke = PackedVector2Array()

	if player.mouse_component.is_held(&"draw"):
		current_stroke.append(player.mouse_component.position)
		
		var distance: float = player.mouse_component.position.distance_to(player.mouse_component.previous)
		var normalized_speed: float = clamp(distance / 25.0, 0.0, 1.0)
		var speed_mapped_size: int = int(lerp(float(max_brush_size), float(min_brush_size), normalized_speed))

		canvas_logic.process_drawing(player.mouse_component.position, player.mouse_component.previous, speed_mapped_size)

	if player.mouse_component.is_released(&"draw"):
		if current_stroke.size() > 5:
			all_strokes.append(current_stroke)
			current_stroke = PackedVector2Array()

func physics_process(_delta: float) -> State:
	if player.mouse_component.consume_press(&"toggle casting"):
		if not all_strokes.is_empty():
			var casted_spell: String = recognizer.recognize(all_strokes)

			if casted_spell != "None":
				print("Successfully cast spell: ", casted_spell)
			else: 
				print("Spell fizzled!")

		all_strokes.clear()
		return player.get_state("Idle")
	
	return self

func exit() -> void:
	can_draw = false
	canvas_logic.clear_canvas()
	_animate_distortion(false)

func _animate_distortion(grayscale_state: bool, on_finished: Callable = Callable()) -> void:
	if not distortion_rect or not (distortion_rect.material is ShaderMaterial):
		if on_finished.is_valid():
			on_finished.call()
		return

	var mat = distortion_rect.material as ShaderMaterial
	mat.set_shader_parameter("grayscale_enabled", grayscale_state)
	mat.set_shader_parameter("progress", 0.0)

	var tween = create_tween()
	tween.tween_method(func(val: float): mat.set_shader_parameter("progress", val), 0.0, 1.0, 0.5)
	tween.tween_method(func(val: float): mat.set_shader_parameter("progress", val), 1.0, 0.0, 0.5)
	
	if on_finished.is_valid():
		tween.finished.connect(on_finished)
