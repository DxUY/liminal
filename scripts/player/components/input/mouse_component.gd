class_name MouseComponent extends Node

var _position := Vector2.ZERO
var _previous := Vector2.ZERO

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		_previous = _position
		_position = event.position

func get_mouse_state() -> Dictionary:
	return {
		"position": _position,
		"previous": _previous,
		"delta": _position - _previous
	}
