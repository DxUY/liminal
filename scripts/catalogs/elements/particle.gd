class_name Particle extends Element

var velocity: Vector2

func _init() -> void:
	type = Type.PARTICLE
	density = 0 
	friction = 0
	energy_conservation = 0

func serialize_gpu(data: PackedInt32Array) -> void:
	data.append(int(velocity.x))
	data.append(int(velocity.y))
