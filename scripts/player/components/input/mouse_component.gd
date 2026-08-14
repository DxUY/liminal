class_name MouseComponent extends Node

var position: Vector2 = Vector2.ZERO
var previous: Vector2 = Vector2.ZERO
var _is_fresh_click: bool = true

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		if _is_fresh_click:
			previous = event.position
			_is_fresh_click = false
		else:
			previous = position
		
		position = event.position

func is_held(button: MouseButton = MOUSE_BUTTON_LEFT) -> bool:
	var held: bool = Input.is_mouse_button_pressed(button)
	if not held:
		_is_fresh_click = true
	return held

func is_pressed(action: StringName) -> bool:
	return Input.is_action_just_pressed(action)

func is_released(action: StringName) -> bool:
	return Input.is_action_just_released(action)
