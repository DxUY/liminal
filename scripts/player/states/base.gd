class_name State extends Node

var player: Player

## Runs ONCE, the instant this state becomes active
func enter() -> void:
	pass

## Runs ONCE, the instant this state is replaced.
func exit() -> void:
	pass

## Runs EVERY physics frame while this state is active
func physics_process(_delta: float) -> State:
	return self
