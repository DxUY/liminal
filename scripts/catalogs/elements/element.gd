class_name Element extends RefCounted

enum Type { EMPTY, SOLID, LIQUID, GAS, PLASMA, PARTICLE }

var id: int
var name: StringName
var color: Color
var type: Type = Type.EMPTY

# All possible state properties
var density: int = 0
var gravity_dir: int = 1         # 1 = Down, -1 = Up
var velocity: Vector2i = Vector2i.ZERO # Velocity vector (x, y)
var dispersion_rate: int = 0     # Spreading distance for Liquids/Gases
var friction: int = 0
var viscosity: int = 0
var energy_conservation: int = 0

# Serializes properties into a fixed 9-integer block for the GPU
func serialize_gpu(data: PackedInt32Array) -> void:
	data.push_back(type)
	data.push_back(density)
	data.push_back(gravity_dir)
	data.push_back(velocity.x)    # Replaces diagonal_slide
	data.push_back(velocity.y)    # Replaces diagonal_slide
	data.push_back(dispersion_rate)
	data.push_back(friction)
	data.push_back(viscosity)
	data.push_back(energy_conservation)
