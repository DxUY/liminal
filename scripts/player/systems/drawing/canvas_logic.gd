class_name CanvasLogic extends Node

@export var texture_rect: CanvasRect
@export var width := 320
@export var height := 180

const PUSH_CONSTANT_SIZE := 24
const SHADER_FILE := preload("res://resources/shaders/compute/spell_casting.glsl") as RDShaderFile

var rd: RenderingDevice
var drawing_shader: RID
var drawing_texture: RID
var uniform_set: RID
var drawing_pipeline: RID

var is_first_frame := true

func initialize() -> void:
	rd = RenderingServer.get_rendering_device()

	if not drawing_shader.is_valid():
		var shader_spirv: RDShaderSPIRV = SHADER_FILE.get_spirv()
		drawing_shader = rd.shader_create_from_spirv(shader_spirv)
		drawing_pipeline = rd.compute_pipeline_create(drawing_shader)

	if not drawing_texture.is_valid():
		_create_texture()
	else:
		clear_canvas()

func clear_canvas() -> void:
	if rd and drawing_texture.is_valid():
		# Clear the texture data with black/zero values
		var clear_color := Color(0, 0, 0, 0)
		rd.texture_clear(drawing_texture, clear_color, 0, 1, 0, 1)
	is_first_frame = true

func process_drawing(current_mouse_pos: Vector2, previous_mouse_pos: Vector2, current_brush_size: int) -> void:
	var mouse_pos := texture_rect.screen_to_texel(current_mouse_pos)
	var prev_mouse_pos := texture_rect.screen_to_texel(previous_mouse_pos)

	if is_first_frame:
		prev_mouse_pos = mouse_pos
		is_first_frame = false

	var pc := PackedByteArray()
	pc.resize(PUSH_CONSTANT_SIZE)
	pc.encode_s32(0, current_brush_size)
	pc.encode_s32(8, mouse_pos.x)
	pc.encode_s32(12, mouse_pos.y)
	pc.encode_s32(16, prev_mouse_pos.x)
	pc.encode_s32(20, prev_mouse_pos.y)

	@warning_ignore("integer_division")
	var groups_x := (width + 7) / 8
	@warning_ignore("integer_division")
	var groups_y := (height + 7) / 8

	var drawing_compute_list := rd.compute_list_begin()
	rd.compute_list_bind_compute_pipeline(drawing_compute_list, drawing_pipeline)
	rd.compute_list_bind_uniform_set(drawing_compute_list, uniform_set, 0)
	rd.compute_list_set_push_constant(drawing_compute_list, pc, pc.size())
	rd.compute_list_dispatch(drawing_compute_list, groups_x, groups_y, 1)
	rd.compute_list_end()

func _exit_tree() -> void:
	if drawing_pipeline.is_valid(): rd.free_rid(drawing_pipeline)
	if uniform_set.is_valid(): rd.free_rid(uniform_set)
	if drawing_texture.is_valid(): rd.free_rid(drawing_texture)
	if drawing_shader.is_valid(): rd.free_rid(drawing_shader)

func _create_texture() -> void:
	var drawing_texture_format := RDTextureFormat.new()
	drawing_texture_format.format = RenderingDevice.DATA_FORMAT_R8G8_UNORM
	drawing_texture_format.texture_type = RenderingDevice.TEXTURE_TYPE_2D
	drawing_texture_format.width = width
	drawing_texture_format.height = height

	drawing_texture_format.usage_bits = \
		RenderingDevice.TEXTURE_USAGE_SAMPLING_BIT | \
		RenderingDevice.TEXTURE_USAGE_STORAGE_BIT | \
		RenderingDevice.TEXTURE_USAGE_CAN_UPDATE_BIT | \
		RenderingDevice.TEXTURE_USAGE_CAN_COPY_FROM_BIT | \
		RenderingDevice.TEXTURE_USAGE_CAN_COPY_TO_BIT

	drawing_texture = rd.texture_create(drawing_texture_format, RDTextureView.new())

	var drawing_texture_uniform := RDUniform.new()
	drawing_texture_uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_IMAGE
	drawing_texture_uniform.binding = 0
	drawing_texture_uniform.add_id(drawing_texture)
	uniform_set = rd.uniform_set_create([drawing_texture_uniform], drawing_shader, 0)

	var drawing_texture_wrapper := Texture2DRD.new()
	drawing_texture_wrapper.texture_rd_rid = drawing_texture
	texture_rect.texture = drawing_texture_wrapper
