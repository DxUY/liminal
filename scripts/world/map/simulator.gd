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
const SHADER_FILE := preload("res://resources/shaders/grid_simulation.glsl")

#endregion

#region Rendering Device Resources

var rd: RenderingDevice

var shader: RID
var pipeline: RID
var uniform_set: RID
var texture_rid: RID

var element_buffer_rid: RID
var solid_buffer_rid: RID

#endregion

#region Rendering Resources

var palette_texture: ImageTexture

#endregion

#region Runtime State

var elapsed := 0.0
var texture_dirty := false
var timestamp_queued := true

#endregion

#region Lifecycle

func _ready() -> void:
	_initialize_rendering()

func _physics_process(delta: float) -> void:
	_update_texture_if_needed()
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

## Creates storage buffers for elements and solids using data from ElementRegistry
func _create_element_gpu_buffers() -> void:
	var db := ElementRegistry.build_gpu_databases()
	
	var element_data: PackedInt32Array = db["elements"]
	var solid_data: PackedInt32Array = db["solids"]
	
	element_buffer_rid = rd.storage_buffer_create(element_data.size() * 4, element_data.to_byte_array())
	solid_buffer_rid = rd.storage_buffer_create(solid_data.size() * 4, solid_data.to_byte_array())

#endregion

#region Simulation

## Dispatches two compute shader passes.
func _dispatch_simulation(delta: float) -> void:
	var mouse := texture_rect.get_mouse_texel()

	var first_pass := _create_push_constants(0, elapsed, mouse)
	var second_pass := _create_push_constants(1, elapsed + delta * 0.5, mouse)
	var groups := _get_dispatch_groups()

	var list := rd.compute_list_begin()

	rd.compute_list_bind_compute_pipeline(list, pipeline)
	rd.compute_list_bind_uniform_set(list, uniform_set, 0)
	_dispatch_pass(list, first_pass, groups)
	rd.compute_list_add_barrier(list)
	_dispatch_pass(list, second_pass, groups)
	rd.compute_list_end()
	elapsed += delta

## Dispatches a single compute pass.
func _dispatch_pass(list: int, push_constants: PackedByteArray,groups: Vector2i) -> void:
	rd.compute_list_set_push_constant(list, push_constants, push_constants.size())
	rd.compute_list_dispatch(list, groups.x, groups.y, 1)

#endregion

#region Texture Management

func _mark_texture_dirty() -> void:
	texture_dirty = true

func _update_texture_if_needed() -> void:
	if not texture_dirty: return

	texture_dirty = false
	call_deferred("_recreate_texture")

## Recreates the simulation texture and uniform set.
func _recreate_texture() -> void:
	if Engine.is_editor_hint(): return

	if uniform_set.is_valid():
		rd.free_rid(uniform_set)

	if texture_rid.is_valid():
		rd.free_rid(texture_rid)

	texture_rid = _create_texture()
	uniform_set = _create_uniform_set(texture_rid)

	var wrapper := Texture2DRD.new()
	wrapper.texture_rd_rid = texture_rid

	texture_rect.texture = wrapper


func _create_texture() -> RID:
	var format := RDTextureFormat.new()

	format.format = RenderingDevice.DATA_FORMAT_R8G8_UNORM
	format.texture_type = RenderingDevice.TEXTURE_TYPE_2D
	format.width = width
	format.height = height

	format.usage_bits = \
		RenderingDevice.TEXTURE_USAGE_SAMPLING_BIT \
		| RenderingDevice.TEXTURE_USAGE_STORAGE_BIT

	return rd.texture_create(format, RDTextureView.new())

func _create_uniform_set(texture: RID) -> RID:
	var uniforms: Array[RDUniform] = []

	# Binding 0: Image Texture (Simulation Grid)
	var img_uniform := RDUniform.new()
	img_uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_IMAGE
	img_uniform.binding = 0
	img_uniform.add_id(texture)
	uniforms.append(img_uniform)

	# Binding 1: Element Database Buffer
	var elem_uniform := RDUniform.new()
	elem_uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER
	elem_uniform.binding = 1
	elem_uniform.add_id(element_buffer_rid)
	uniforms.append(elem_uniform)

	# Binding 2: Solid Properties Buffer
	var solid_uniform := RDUniform.new()
	solid_uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER
	solid_uniform.binding = 2
	solid_uniform.add_id(solid_buffer_rid)
	uniforms.append(solid_uniform)

	return rd.uniform_set_create(uniforms, shader, 0)

#endregion

#region Push Constants

## Creates the push constant block for one simulation pass.
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
	var x := (((width + 1) / 2) + 7) / 8

	@warning_ignore("integer_division")
	var y := (((height + 1) / 2) + 7) / 8

	return Vector2i(x, y)

#endregion

#region Cleanup

func _free_resources() -> void:
	rd.free_rid(pipeline)
	rd.free_rid(uniform_set)
	rd.free_rid(texture_rid)
	rd.free_rid(shader)
	rd.free_rid(element_buffer_rid)
	rd.free_rid(solid_buffer_rid)

#endregion
