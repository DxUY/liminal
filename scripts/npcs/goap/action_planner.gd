class_name ActionPlanner extends Node

var _actions: Array

## Set actions available for planning.
## This can be changed at runtime for more dynamic actions.
func set_action(actions: Array) -> void:
	_actions = actions

## Receives a Goal and an optional blackboard.
## Returns a list of actions to be executed.
func get_plan(goal: Goal, blackboard: Dictionary = {}) -> Array:
	var desired_state: Dictionary = goal.get_desired_state().duplicate()
	if desired_state.is_empty(): return []
	return _find_best_plan(goal, desired_state, blackboard)

func _find_best_plan(goal: Goal, desired_state: Dictionary, blackboard: Dictionary) -> Array:
	var root := {
		"action": goal,
		"state": desired_state,
		"children": []
	}

	if _build_plans(root, blackboard.duplicate(), {}):
		var plans := _transform_tree_into_array(root, blackboard)
		return _get_cheapest_plan(plans)

	return []

## Compares plan costs and returns the cheapest sequence of actions.
func _get_cheapest_plan(plans: Array) -> Array:
	var best_plan: Dictionary
	for p in plans:
		if best_plan == null or p.cost < best_plan.cost:
			best_plan = p
	if best_plan == null: return []
	return best_plan.actions

## Builds the planning graph recursively.
## Returns true if at least one valid plan exists.
func _build_plans(step: Dictionary, blackboard: Dictionary, visited_states: Dictionary) -> bool:
	var has_followup := false

	# Prevent circular dependencies.
	var state_key := _state_key(step.state)
	if visited_states.has(state_key): return false
	visited_states[state_key] = true

	# Each node has its own desired state.
	var state: Dictionary = step.state.duplicate()

	# Remove already-satisfied conditions.
	for key in step.state.keys():
		if state[key] == blackboard.get(key):
			state.erase(key)

	# Everything satisfied.
	if state.is_empty(): return true

	for action in _actions:
		if not action.is_valid(): continue
		var should_use_action := false
		var effects: Dictionary = action.get_effects()
		var desired_state: Dictionary = state.duplicate()

		# Does this action satisfy any desired condition?
		for key in desired_state.keys():
			if desired_state[key] == effects.get(key):
				desired_state.erase(key)
				should_use_action = true

		if not should_use_action: continue

		# Add preconditions.
		var preconditions: Dictionary = action.get_preconditions()

		for key in preconditions:
			desired_state[key] = preconditions[key]

		var child := {
			"action": action,
			"state": desired_state,
			"children": []
		}

		if desired_state.is_empty() or _build_plans(
			child,
			blackboard.duplicate(),
			visited_states.duplicate()
		):
			step.children.push_back(child)
			has_followup = true

	return has_followup

## Converts the planning tree into linear action sequences.
func _transform_tree_into_array(node: Dictionary, blackboard: Dictionary) -> Array:
	var plans: Array = []

	if node.children.is_empty():
		plans.push_back({
			"actions": [node.action],
			"cost": node.action.get_cost(blackboard)
		})
		return plans

	for child in node.children:
		for child_plan in _transform_tree_into_array(child, blackboard):

			if node.action.has_method("get_cost"):
				child_plan.actions.push_back(node.action)
				child_plan.cost += node.action.get_cost(blackboard)

			plans.push_back(child_plan)

	return plans

## Creates a deterministic string key for a desired state.
## Used to detect circular dependencies.
func _state_key(state: Dictionary) -> String:
	var keys := state.keys()
	keys.sort()
	var result := ""
	for key in keys:
		result += "%s=%s;" % [str(key), str(state[key])]

	return result
