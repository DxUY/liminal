class_name GridSimulator extends Node

#region Inspector

@export var shader_file: RDShaderFile

#endregion

#region Rendering Device

var rd: RenderingDevice = RenderingServer.get_rendering_device()

#endregion

#region GPU Resources

## Compiled compute shader.
var shader: RID

## Compute pipeline.
var pipeline: RID

## Current simulation state.
var current_texture: RID

## Next simulation state.
var next_texture: RID

## Uniform buffer containing simulation constants.
var simulation_buffer: RID

## Bound resources used by the compute shader.
var uniform_set: RID

#endregion

#region Element Databases

## Storage buffer containing the element lookup table.
## Each entry maps an element ID to its behavior type and the corresponding index within its behavior-specific database.
var element_database_buffer: RID

## Storage buffer containing serialized solid element data.
var solid_database_buffer: RID

## Storage buffer containing serialized liquid element data.
var liquid_database_buffer: RID

#endregion

#region Simulation

## Simulation width in cells.
var width: int

## Simulation height in cells.
var height: int

#endregion

#region Public API

## Initializes the simulation from an image.
func initialize(image: Image) -> void:	
	width = image.get_width()
	height = image.get_height()

	shader = rd.shader_create_from_spirv(shader_file.get_spirv())
	pipeline = rd.compute_pipeline_create(shader)

	_create_textures(image)
	_create_simulation_buffer()
	_create_element_database_buffers()
	_create_uniform_set()

## Executes one simulation step.
func dispatch(delta: float) -> void:
	var compute_list: int = rd.compute_list_begin()

	rd.compute_list_bind_compute_pipeline(compute_list, pipeline)
	rd.compute_list_bind_uniform_set(compute_list, uniform_set, 0)

	var groups_x: int = (width + 7) / 8
	var groups_y: int = (height + 7) / 8

	rd.compute_list_dispatch(compute_list, groups_x, groups_y, 1)
	rd.compute_list_end()

## Returns the current simulation texture.
func get_current_texture() -> RID:
	return current_texture

#endregion

#region Texture Creation

## Creates the simulation textures.
func _create_textures(image: Image) -> void:
	var texture_view := RDTextureView.new()
	var texture_format := _create_texture_format(width, height)

	current_texture = rd.texture_create(texture_format, texture_view, [image.get_data()])
	next_texture = rd.texture_create(texture_format, texture_view)

## Creates the texture format shared by the simulation textures.
func _create_texture_format(p_width: int, p_height: int) -> RDTextureFormat:
	var texture_format := RDTextureFormat.new()

	texture_format.width = p_width
	texture_format.height = p_height

	texture_format.format = RenderingDevice.DATA_FORMAT_R32G32B32A32_SFLOAT

	texture_format.usage_bits = (
		RenderingDevice.TEXTURE_USAGE_STORAGE_BIT |
		RenderingDevice.TEXTURE_USAGE_CAN_COPY_FROM_BIT |
		RenderingDevice.TEXTURE_USAGE_SAMPLING_BIT
	)

	return texture_format

#endregion

#region Uniform Buffers

## Creates the SimulationData storage buffer.
func _create_simulation_buffer() -> void:
	simulation_buffer = _create_storage_buffer(
		PackedInt32Array([width, height])
	)

## Creates the storage buffers containing the GPU element databases.
func _create_element_database_buffers() -> void:
	var databases := ElementRegistry.build_gpu_databases()

	assert(databases["elements"].size() > 0, "Elements database is empty!")
	assert(databases["solids"].size() > 0, "Solids database is empty!")

	element_database_buffer = _create_storage_buffer(databases["elements"])
	solid_database_buffer = _create_storage_buffer(databases["solids"])
	#liquid_database_buffer = _create_storage_buffer(databases["liquids"])

## Creates a storage buffer from the given integer data.
func _create_storage_buffer(data: PackedInt32Array) -> RID:
	var bytes := data.to_byte_array()
	return rd.storage_buffer_create(bytes.size(), bytes)

#endregion

#region Uniform Sets

## Creates the compute shader uniform set.
func _create_uniform_set() -> void:
	var current_uniform := RDUniform.new()
	current_uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_IMAGE
	current_uniform.binding = 0
	current_uniform.add_id(current_texture)

	var next_uniform := RDUniform.new()
	next_uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_IMAGE
	next_uniform.binding = 1
	next_uniform.add_id(next_texture)

	var simulation_uniform := RDUniform.new()
	simulation_uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER
	simulation_uniform.binding = 2
	simulation_uniform.add_id(simulation_buffer)
	
	var element_uniform := RDUniform.new()
	element_uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER
	element_uniform.binding = 3
	element_uniform.add_id(element_database_buffer)

	var solid_uniform := RDUniform.new()
	solid_uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER
	solid_uniform.binding = 4
	solid_uniform.add_id(solid_database_buffer)

	uniform_set = rd.uniform_set_create(
		[
			current_uniform,
			next_uniform,
			simulation_uniform,
			element_uniform,
			solid_uniform,
		],
		shader, 0
	)

#endregion
