class_name MouseComponent extends Node

var position: Vector2 = Vector2.ZERO
var previous: Vector2 = Vector2.ZERO
var _is_fresh_click: bool = true

var _consumed_actions: Dictionary[StringName, bool] = {}

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		if _is_fresh_click:
			previous = event.position
			_is_fresh_click = false
		else:
			previous = position
		position = event.position

func is_held(action_name: StringName) -> bool:
	var held: bool = Input.is_action_pressed(action_name)
	if not held:
		_is_fresh_click = true
	return held

func is_pressed(action: StringName) -> bool:
	return Input.is_action_just_pressed(action)

func consume_press(action: StringName) -> bool:
	if Input.is_action_just_pressed(action):
		if not _consumed_actions.get(action, false):
			_consumed_actions[action] = true
			return true
	else:
		_consumed_actions[action] = false
	return false

func is_released(action: StringName) -> bool:
	return Input.is_action_just_released(action)
