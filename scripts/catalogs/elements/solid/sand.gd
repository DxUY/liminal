class_name Sand extends Solid

func _init() -> void:
	super()
	id = 1
	name = "Sand"
	color = Color(1.0, 0.9, 0.4)
	density = 1
	hardness = 1

func serialize_gpu(data: PackedInt32Array) -> void:
	super(data)
