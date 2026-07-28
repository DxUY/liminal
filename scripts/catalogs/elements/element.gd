@abstract class_name Element extends RefCounted

var id: int
var name: StringName
var color: Color
var type: Type

enum Type {
	EMPTY,
	SOLID,
	LIQUID, 
	GAS,
	PLASMA
}

@abstract func serialize_gpu(data: PackedInt32Array) -> void
