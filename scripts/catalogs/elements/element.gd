@abstract class_name Element extends RefCounted

var id: int
var name: StringName
var color: Color
var type: Type

var density: int
var friction: int
var energy_conservation: int

enum Type {
	EMPTY,
	SOLID,
	LIQUID,
	GAS,
	PLASMA,
	PARTICLE
}

@abstract func serialize_gpu(data: PackedInt32Array) -> void
