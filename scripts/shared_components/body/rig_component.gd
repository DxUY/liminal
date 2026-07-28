class_name RigComponent extends Node

var points: Array[RigPoint] = []

func add_point(cell: Vector2i, parent: int = -1, length: int = 1) -> int:
	points.append(RigPoint.new(cell, parent, length))
	return points.size() - 1

func get_root() -> int:
	for i in points.size():
		if points[i].parent == -1: return i
	return -1

func get_joint_children(parent: int) -> Array[int]:
	var children: Array[int] = []

	for i in points.size():
		if points[i].parent == parent:
			children.append(i)

	return children
