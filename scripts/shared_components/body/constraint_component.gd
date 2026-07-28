class_name ConstraintComponent extends Node

class JointConstraint extends RefCounted:
	## Angle the joint is allowed to bend.
	var min_angle: float = -180.0
	var max_angle: float = 180.0

	## Overall rotation limit.
	var min_rotation: float = -180.0
	var max_rotation: float = 180.0

	## Preferred bend direction.
	var preferred_direction: Vector2i = Vector2i.ZERO

	## Pole direction (elbow/knee guidance).
	var pole_direction: Vector2i = Vector2i.ZERO

	## Pin this joint to a grid cell.
	var pin: bool = false
	var pin_cell: Vector2i = Vector2i.ZERO

# One constraint per RigPoint.
var joints: Array[JointConstraint] = []
