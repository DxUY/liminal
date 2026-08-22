extends Node

#region Constants

## Push constants size: int (4 bytes) + float (4 bytes) = 8 bytes (padded to 16 bytes for safety).
const PUSH_CONSTANT_SIZE := 8

## Compute shader used for the simulation.
const SHADER_FILE := preload("res://resources/shaders/compute/cellular_automaton.glsl")

## Simulation grid dimensions.
const SIMULATION_WIDTH := 800
const SIMULATION_HEIGHT := 600

#endregion

#region Rendering Device Resources

var rd: RenderingDevice
var shader: RID
var pipeline: RID

## Single In-Place Texture Resource
var terrain_texture_rid: RID
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

	terrain_texture_rid = _create_single_texture(width, height)
	uniform_set = _create_uniform_set(terrain_texture_rid)

func _create_single_texture(width: int, height: int) -> RID:
	var format := RDTextureFormat.new()
	format.format = RenderingDevice.DATA_FORMAT_R8G8B8A8_UNORM
	format.texture_type = RenderingDevice.TEXTURE_TYPE_2D
	format.width = width
	format.height = height
	format.usage_bits = RenderingDevice.TEXTURE_USAGE_STORAGE_BIT | RenderingDevice.TEXTURE_USAGE_SAMPLING_BIT

	return rd.texture_create(format, RDTextureView.new())

func _create_uniform_set(tex_rid: RID) -> RID:
	var uniforms: Array[RDUniform] = []

	# Binding 0: Read/Write Image Texture (terrain)
	var tex_uniform := RDUniform.new()
	tex_uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_IMAGE
	tex_uniform.binding = 0
	tex_uniform.add_id(tex_rid)
	uniforms.append(tex_uniform)

	# Binding 1: Element Database Buffer
	var elem_uniform := RDUniform.new()
	elem_uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER
	elem_uniform.binding = 1
	elem_uniform.add_id(element_buffer_rid)
	uniforms.append(elem_uniform)

	return rd.uniform_set_create(uniforms, shader, 0)

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
	if shader.is_valid(): rd.free_rid(shader)
	if element_buffer_rid.is_valid(): rd.free_rid(element_buffer_rid)

#endregion

#region Helpers

func get_simulation_texture() -> Texture2DRD:
	var texture := Texture2DRD.new()
	texture.texture_rd_rid = terrain_texture_rid
	return texture

#endregion
