extends MeshInstance2D

func _ready() -> void:
	var sim_texture: Texture2DRD = CellularAutomaton.get_simulation_texture()
	
	var mat = self.material as ShaderMaterial
	mat.set_shader_parameter("sim_texture", sim_texture)
