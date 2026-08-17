class_name Sand extends Solid

func _init() -> void:
	super()
	vel = Vector3(-1 if randf() > 0.5 else 1, -124.0, 0.0)
	frictionFactor = 0.9
	
	color = Color(1.0, 0.9, 0.4, 1.0)
