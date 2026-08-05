class_name Water extends Liquid

func _init() -> void:
	super()
	id = 2
	name = "Water"
	color = Color8(51, 128, 255)
	density = 1
	viscosity = 1
	dispersion_rate = 5
	surface_tension = 1 
	friction = 1
	energy_conservation = 8

func serialize_gpu(data: PackedInt32Array) -> void:
	super(data)
