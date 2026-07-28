class_name Renderer extends MeshInstance2D 

var simulation_texture := Texture2DRD.new() 

func initialize(texture: RID, width: int, height: int) -> void: 
	simulation_texture.texture_rd_rid = texture 
	material.set_shader_parameter("sim_texture", simulation_texture) 
	
	var quad := mesh as QuadMesh 
	quad.size = Vector2(width, height) 
	scale = Vector2.ONE 

func update_texture(texture: RID) -> void:
	simulation_texture.texture_rd_rid = texture
