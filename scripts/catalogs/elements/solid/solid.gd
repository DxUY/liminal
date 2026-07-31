@abstract class_name Solid extends Element

var hardness: int

func _init() -> void:
	type = Type.SOLID

func serialize_gpu(data: PackedInt32Array) -> void:
	data.push_back(density)
	data.push_back(hardness)
