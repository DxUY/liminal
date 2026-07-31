class_name Empty extends Element

func _init() -> void:
	id = 0
	name = "Empty"
	color = Color.TRANSPARENT
	density = 0

func serialize_gpu(data: PackedInt32Array) -> void:
	data.push_back(density)
