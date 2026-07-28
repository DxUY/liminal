class_name Sand extends Solid

func _init() -> void:
	super()
	id = 1
	name = "Sand"
	color = Color(1.0, 0.9, 0.4)

func serialize_gpu(data: PackedInt32Array) -> void:
	data.push_back(type)
	data.push_back(hardness)
