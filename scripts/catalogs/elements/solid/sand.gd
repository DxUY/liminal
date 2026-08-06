class_name Sand extends Element

func _init() -> void:
	id = 1
	name = "Sand"
	color = Color8(235, 200, 100)
	type = Type.SOLID
	
	density = 10
	gravity_dir = 1
	velocity = Vector2i(0, 1)  # Default downward terminal velocity impulse
	dispersion_rate = 0
	friction = 5
