class_name MouseComponent extends Node

var _position := Vector2.ZERO
var _previous := Vector2.ZERO

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		_previous = _position
		_position = event.position

func get_mouse_position() -> Vector2:
	return _position

func get_previous_mouse_position() -> Vector2:
	return _previous

func get_mouse_delta() -> Vector2:
	return _position - _previous
