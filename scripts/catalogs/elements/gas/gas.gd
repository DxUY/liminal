@abstract class_name Gas extends Element

func _init() -> void:
	type = Type.GAS

func serialize_gpu(data: PackedInt32Array) -> void:
	data.push_back(density)
	data.push_back(friction)
	data.push_back(energy_conservation)
