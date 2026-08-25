extends MeshInstance2D

func _ready() -> void:
	var test: Image = preload("res://assets/tiles/map.png")
	CellularAutomaton.set_simulation_texture(test)
	
	mesh.size = Vector2(test.get_width(), test.get_height())
	
	var sim_texture: Texture2DRD = CellularAutomaton.get_simulation_texture()
	
	var mat = self.material as ShaderMaterial
	mat.set_shader_parameter("sim_texture", sim_texture)
