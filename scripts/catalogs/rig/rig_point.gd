class_name RigPoint
extends RefCounted

## Grid cell occupied by this joint
var cell: Vector2i

## Previous grid cell
var previous_cell: Vector2i

## Parent joint (-1 = root)
var parent: int = -1

## Bone length measured in grid cells
var length: int = 1

func _init(
	grid_cell: Vector2i = Vector2i.ZERO,
	parent_index: int = -1,
	bone_length: int = 1
):
	cell = grid_cell
	previous_cell = grid_cell
	parent = parent_index
	length = bone_length
