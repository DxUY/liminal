@abstract class_name Liquid extends Element

var viscosity: int
var dispersion_rate: int
var surface_tension: int

func _init() -> void:
	type = Type.LIQUID

func serialize_gpu(data: PackedInt32Array) -> void:
	data.append(density)
	data.append(viscosity)
	data.append(dispersion_rate)
	data.append(friction)
	data.append(energy_conservation)
	data.append(surface_tension)
