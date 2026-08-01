@abstract class_name Solid extends Element

var hardness: int
var inertial_resistance: int
var collapse_threshold: int

func _init() -> void:
	type = Type.SOLID

func serialize_gpu(data: PackedInt32Array) -> void:
	data.push_back(density)
	data.push_back(hardness)
	data.push_back(inertial_resistance)
	data.push_back(friction)
	data.push_back(energy_conservation)
	data.push_back(collapse_threshold)
