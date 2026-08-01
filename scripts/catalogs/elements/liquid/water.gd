class_name Water extends Liquid

func _init() -> void:
	super()
	id = 2
	name = "Water"
	color = Color(0.2, 0.5, 1.0)
	density = 0
	viscosity = 1
	dispersion_rate = 4
	friction = 1
	energy_conservation = 8

func serialize_gpu(data: PackedInt32Array) -> void:
	super(data)
