# water.gd
class_name Water extends Element

func _init() -> void:
	id = 2
	name = "Water"
	color = Color8(51, 128, 255)
	type = Type.LIQUID
	
	density = 1
	gravity_dir = 1
	velocity = Vector2i(0, 1)
	dispersion_rate = 5
	viscosity = 1
	friction = 1
