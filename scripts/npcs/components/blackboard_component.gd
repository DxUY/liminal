class_name BlackboardComponent extends Node

var _data: Dictionary = {}

func set_value(key: StringName, value) -> void:
	_data[key] = value

func get_value(key: StringName, default = null):
	return _data.get(key, default)

func has_value(key: StringName) -> bool:
	return _data.has(key)

func erase_value(key: StringName) -> void:
	_data.erase(key)

func clear() -> void:
	_data.clear()

func get_all() -> Dictionary:
	return _data.duplicate()
