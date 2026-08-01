@abstract class_name Liquid extends Element

var viscosity: int
var dispersion_rate: int

func _init() -> void:
	type = Type.LIQUID

func serialize_gpu(data: PackedInt32Array) -> void:
	data.push_back(density)
	data.push_back(viscosity)
	data.push_back(dispersion_rate)
	data.push_back(friction)
	data.push_back(energy_conservation)
