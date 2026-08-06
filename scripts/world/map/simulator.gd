extends Node

#region Editor

@export var texture_rect: MapTextureRect

@export var width := 800:
	set(value):
		width = value
		_mark_texture_dirty()

@export var height := 600:
	set(value):
		height = value
		_mark_texture_dirty()

#endregion

#region Constants

## Push constants must be a multiple of 16 bytes.
const PUSH_CONSTANT_SIZE := 16

## Compute shader used for the simulation.
const SHADER_FILE := preload("res://resources/shaders/simulation.glsl")

#endregion

#region Rendering Device Resources

var rd: RenderingDevice

var shader: RID
var pipeline: RID

# Ping-Pong Resources
var texture_rid_a: RID
var texture_rid_b: RID
var uniform_set_a: RID # Reads A, Writes B
var uniform_set_b: RID # Reads B, Writes A
var frame_toggle := false

# Unified SSBO for all elements
var element_buffer_rid: RID

#endregion

#region Rendering Resources

var palette_texture: ImageTexture

#endregion

#region Runtime State

var elapsed := 0.0
var frame_counter := 0
var texture_dirty := false

#endregion

#region Lifecycle

func _ready() -> void:
	_initialize_rendering()

func _physics_process(delta: float) -> void:
	_update_texture_if_needed()
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
	
	palette_texture = ImageTexture.create_from_image(ElementRegistry.build_color_palette())
	var material := texture_rect.material as ShaderMaterial
	material.set_shader_parameter("palette", palette_texture)
	
	_recreate_texture()
	pipeline = rd.compute_pipeline_create(shader)

## Creates the single unified element storage buffer using data from ElementRegistry
func _create_element_gpu_buffers() -> void:
	var gpu_data: PackedInt32Array = ElementRegistry.build_gpu_databases()
	element_buffer_rid = rd.storage_buffer_create(gpu_data.size() * 4, gpu_data.to_byte_array())

#endregion

#region Simulation

## Dispatches the ping-pong compute pass.
func _dispatch_simulation(delta: float) -> void:
	var mouse := texture_rect.get_mouse_texel()
	var groups := _get_dispatch_groups()

	var active_uniform_set = uniform_set_a if not frame_toggle else uniform_set_b
	var pc := _create_push_constants(frame_counter, elapsed, mouse)

	var list := rd.compute_list_begin()
	rd.compute_list_bind_compute_pipeline(list, pipeline)
	rd.compute_list_bind_uniform_set(list, active_uniform_set, 0)
	rd.compute_list_set_push_constant(list, pc, pc.size())
	rd.compute_list_dispatch(list, groups.x, groups.y, 1)
	rd.compute_list_end()

	var wrapper := texture_rect.texture as Texture2DRD
	wrapper.texture_rd_rid = texture_rid_b if not frame_toggle else texture_rid_a

	frame_toggle = not frame_toggle
	elapsed += delta

#endregion

#region Texture Management

func _mark_texture_dirty() -> void:
	texture_dirty = true

func _update_texture_if_needed() -> void:
	if not texture_dirty: return

	texture_dirty = false
	call_deferred("_recreate_texture")

## Recreates the simulation textures and ping-pong uniform sets.
func _recreate_texture() -> void:
	if Engine.is_editor_hint(): return

	if uniform_set_a.is_valid(): rd.free_rid(uniform_set_a)
	if uniform_set_b.is_valid(): rd.free_rid(uniform_set_b)
	if texture_rid_a.is_valid(): rd.free_rid(texture_rid_a)
	if texture_rid_b.is_valid(): rd.free_rid(texture_rid_b)

	texture_rid_a = _create_single_texture()
	texture_rid_b = _create_single_texture()

	# Uniform Set A: Binding 0 reads A, Binding 1 writes B
	uniform_set_a = _create_ping_pong_uniform_set(texture_rid_a, texture_rid_b)
	# Uniform Set B: Binding 0 reads B, Binding 1 writes A
	uniform_set_b = _create_ping_pong_uniform_set(texture_rid_b, texture_rid_a)

	var wrapper := Texture2DRD.new()
	wrapper.texture_rd_rid = texture_rid_a
	texture_rect.texture = wrapper

func _create_single_texture() -> RID:
	var format := RDTextureFormat.new()

	format.format = RenderingDevice.DATA_FORMAT_R8G8_UNORM
	format.texture_type = RenderingDevice.TEXTURE_TYPE_2D
	format.width = width
	format.height = height

	format.usage_bits = \
		RenderingDevice.TEXTURE_USAGE_SAMPLING_BIT \
		| RenderingDevice.TEXTURE_USAGE_STORAGE_BIT

	return rd.texture_create(format, RDTextureView.new())

func _create_ping_pong_uniform_set(read_tex: RID, write_tex: RID) -> RID:
	var uniforms: Array[RDUniform] = []

	# Binding 0: Read-only Image Texture (terrain_read)
	var read_uniform := RDUniform.new()
	read_uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_IMAGE
	read_uniform.binding = 0
	read_uniform.add_id(read_tex)
	uniforms.append(read_uniform)

	# Binding 1: Write-only Image Texture (terrain_write)
	var write_uniform := RDUniform.new()
	write_uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_IMAGE
	write_uniform.binding = 1
	write_uniform.add_id(write_tex)
	uniforms.append(write_uniform)

	# Binding 2: Unified Element Database Buffer
	var elem_uniform := RDUniform.new()
	elem_uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER
	elem_uniform.binding = 2
	elem_uniform.add_id(element_buffer_rid)
	uniforms.append(elem_uniform)

	return rd.uniform_set_create(uniforms, shader, 0)

#endregion

#region Push Constants

func _create_push_constants(pass_index: int, time: float, mouse: Vector2i) -> PackedByteArray:
	var pc := PackedByteArray()
	pc.resize(PUSH_CONSTANT_SIZE)

	pc.encode_s32(0, pass_index)
	pc.encode_float(4, time)
	pc.encode_s32(8, mouse.x)
	pc.encode_s32(12, mouse.y)

	return pc

func _get_dispatch_groups() -> Vector2i:
	@warning_ignore("integer_division")
	var x := (width + 7) / 8

	@warning_ignore("integer_division")
	var y := (height + 7) / 8

	return Vector2i(x, y)

#endregion

#region Cleanup

func _free_resources() -> void:
	if pipeline.is_valid(): rd.free_rid(pipeline)
	if uniform_set_a.is_valid(): rd.free_rid(uniform_set_a)
	if uniform_set_b.is_valid(): rd.free_rid(uniform_set_b)
	if texture_rid_a.is_valid(): rd.free_rid(texture_rid_a)
	if texture_rid_b.is_valid(): rd.free_rid(texture_rid_b)
	if shader.is_valid(): rd.free_rid(shader)
	if element_buffer_rid.is_valid(): rd.free_rid(element_buffer_rid)

#endregion
