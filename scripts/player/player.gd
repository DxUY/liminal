class_name Player extends Node2D

@onready var states: State = %States

@export var initial_state_name: StringName
@export var mouse_component: MouseComponent

var current_state: State

var _states: Dictionary[StringName, State] = {} 

func _ready() -> void:
	GameEvents.game_started.connect(_on_game_started)
	add_to_group(SaveManager.SAVABLE_GROUP)

	# Cache every state and hand it a reference back to this player.
	for child: Node in states.get_children():
		if child is State:
			var state: State = child as State
			state.player = self
			_states[child.name] = state

	current_state = get_state(initial_state_name)
	if current_state != null:
		current_state.enter()

func _on_game_started() -> void:
	pass

func _physics_process(delta: float) -> void:
	if mouse_component.is_pressed("toggle casting") and current_state.name != "Cast":
		_change_state(get_state(&"Cast"))

	var nextState: State = current_state.physics_process(delta)
	_change_state(nextState)

#region Savable Contract

func get_save_id() -> String:
	return "player"

func save_data() -> Dictionary:
	return {}

func load_data() -> void:
	pass

#endregion

#region Helpers

func get_state(state_name: StringName) -> State:
	if not _states.has(state_name):
		push_warning("No state named '%s' under States. Check the node name!" % state_name)
		return null
	return _states[state_name]

func _change_state(new_state: State) -> void:
	if new_state == null or new_state == current_state: return
	
	current_state.exit()
	current_state = new_state
	current_state.enter()

#endregion
