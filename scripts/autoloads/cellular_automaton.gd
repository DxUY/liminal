extends Node

#region Configurations

## Push constants size: int (4 bytes) + float (4 bytes) = 8 bytes (padded to 16 bytes for safety).
const PUSH_CONSTANT_SIZE: int = 8

## Compute shader used for the simulation.
const SHADER_FILE: RDShaderFile = preload("res://resources/shaders/compute/cellular_automaton.glsl")

## Simulation grid dimensions.
var SIMULATION_WIDTH: int
var SIMULATION_HEIGHT: int

#endregion

#region Rendering Device Resources

var rd: RenderingDevice
var shader: RID
var pipeline: RID

## Single In-Place Texture Resource
var terrain_texture_rid: RID
var velocity_texture_rid: RID
var uniform_set: RID

var element_buffer_rid: RID

#endregion

#region Runtime State

var elapsed := 0.0
var frame_counter := 0

#endregion

#region Lifecycle

func _ready() -> void:
	_initialize_rendering()

func _physics_process(delta: float) -> void:
	frame_counter += 1
	_dispatch_simulation(delta)

func _exit_tree() -> void:
	_free_resources()

#endregion

#region Initialization

## Creates all GPU resources required by the simulation.
func _initialize_rendering() -> void:
	rd = RenderingServer.get_rendering_device()
	shader = rd.shader_create_from_spirv(SHADER_FILE.get_spirv())
	_create_element_gpu_buffers()
	
	_recreate_texture(SIMULATION_WIDTH, SIMULATION_HEIGHT)
	pipeline = rd.compute_pipeline_create(shader)

## Creates storage buffers for elements using data from ElementRegistry
func _create_element_gpu_buffers() -> void:
	var db := ElementRegistry.build_gpu_databases()
	var element_data: PackedInt32Array = db["elements"]
	element_buffer_rid = rd.storage_buffer_create(element_data.size() * 4, element_data.to_byte_array())

#endregion

#region Simulation

## Dispatches the single-pass in-place compute shader.
func _dispatch_simulation(delta: float) -> void:
	@warning_ignore("integer_division")
	var groups := Vector2i((SIMULATION_WIDTH + 7) / 8, (SIMULATION_HEIGHT + 7) / 8)

	var pc := _create_push_constants(frame_counter, elapsed)

	var list := rd.compute_list_begin()
	rd.compute_list_bind_compute_pipeline(list, pipeline)
	rd.compute_list_bind_uniform_set(list, uniform_set, 0)
	rd.compute_list_set_push_constant(list, pc, pc.size())
	rd.compute_list_dispatch(list, groups.x, groups.y, 1)
	rd.compute_list_end()
	
	elapsed += delta

#endregion

#region Texture Management

## Recreates the single simulation texture and uniform set.
func _recreate_texture(width: int, height: int) -> void:
	if uniform_set.is_valid(): rd.free_rid(uniform_set)
	if terrain_texture_rid.is_valid(): rd.free_rid(terrain_texture_rid)
	if velocity_texture_rid.is_valid(): rd.free_rid(velocity_texture_rid)

	terrain_texture_rid = _create_storage_texture(width, height, RenderingDevice.DATA_FORMAT_R8G8B8A8_UNORM)
	velocity_texture_rid = _create_storage_texture(width, height, RenderingDevice.DATA_FORMAT_R8_SNORM)
	uniform_set = _create_uniform_set(terrain_texture_rid, velocity_texture_rid)

func _create_storage_texture(width: int, height: int, format_type: RenderingDevice.DataFormat) -> RID:
	var format := RDTextureFormat.new()
	format.format = format_type
	format.texture_type = RenderingDevice.TEXTURE_TYPE_2D
	format.width = width
	format.height = height
	format.usage_bits = RenderingDevice.TEXTURE_USAGE_STORAGE_BIT | RenderingDevice.TEXTURE_USAGE_SAMPLING_BIT | RenderingDevice.TEXTURE_USAGE_CAN_UPDATE_BIT

	return rd.texture_create(format, RDTextureView.new())

func _create_uniform_set(tex_rid: RID, vel_rid: RID) -> RID:
	var uniforms: Array[RDUniform] = [
		_create_uniform(RenderingDevice.UNIFORM_TYPE_IMAGE, 0, tex_rid),
		_create_uniform(RenderingDevice.UNIFORM_TYPE_IMAGE, 1, vel_rid),
		_create_uniform(RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER, 2, element_buffer_rid)
	]

	return rd.uniform_set_create(uniforms, shader, 0)

func _create_uniform(type: RenderingDevice.UniformType, binding: int, id: RID) -> RDUniform:
	var uniform := RDUniform.new()
	uniform.uniform_type = type
	uniform.binding = binding
	uniform.add_id(id)
	return uniform

func get_simulation_texture() -> Texture2DRD:
	var texture := Texture2DRD.new()
	texture.texture_rd_rid = terrain_texture_rid
	return texture

func set_simulation_texture(img: Image) -> void:
	SIMULATION_HEIGHT = img.get_height()
	SIMULATION_WIDTH = img.get_width()

	_recreate_texture(SIMULATION_WIDTH, SIMULATION_HEIGHT)
	rd.texture_update(terrain_texture_rid, 0, img.get_data())

#endregion

#region Push Constants

func _create_push_constants(pass_index: int, time: float) -> PackedByteArray:
	var pc := PackedByteArray()
	pc.resize(PUSH_CONSTANT_SIZE)
	pc.encode_s32(0, pass_index)
	pc.encode_float(4, time)
	return pc

#endregion

#region Cleanup

func _free_resources() -> void:
	if pipeline.is_valid(): rd.free_rid(pipeline)
	if uniform_set.is_valid(): rd.free_rid(uniform_set)
	if terrain_texture_rid.is_valid(): rd.free_rid(terrain_texture_rid)
	if velocity_texture_rid.is_valid(): rd.free_rid(velocity_texture_rid)
	if shader.is_valid(): rd.free_rid(shader)
	if element_buffer_rid.is_valid(): rd.free_rid(element_buffer_rid)

#endregion
