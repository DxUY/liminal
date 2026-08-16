class_name Cast extends State

@export var canvas_logic: CanvasLogic
@export var distortion_rect: TextureRect

func enter() -> void:
	if distortion_rect and distortion_rect.material is ShaderMaterial:
		var mat = distortion_rect.material as ShaderMaterial
		
		# Turn on grayscale and reset progress to 0
		mat.set_shader_parameter("grayscale_enabled", true)
		mat.set_shader_parameter("progress", 0.0)
		
		# Create a command-driven tween for the full loop (0 -> 1 -> 0)
		var tween = create_tween()
		tween.tween_method(
			func(val: float): mat.set_shader_parameter("progress", val), 
			0.0, 1.0, 0.5
		)
		tween.tween_method(
			func(val: float): mat.set_shader_parameter("progress", val), 
			1.0, 0.0, 0.5
		)

func physics_process(_delta: float) -> State:
	return self

func exit() -> void:
	pass
