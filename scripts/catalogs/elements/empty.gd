class_name Empty extends Element

func _init():
	id = 0
	name = &"Empty"
	color = Color.TRANSPARENT
	type = Type.EMPTY

func serialize_gpu(data: PackedInt32Array) -> void:
	data.push_back(type)
