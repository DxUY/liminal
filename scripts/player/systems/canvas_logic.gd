class_name CanvasLogic extends Node

@export var textureRect: CanvasRect
@export var width := 320:
	set(value):
		width = value
		textureDirty = true
@export var height := 180:
	set(value):
		height = value
		textureDirty = true

const PUSH_CONSTANT_SIZE := 24
const SHADER_FILE := preload("res://resources/shaders/compute/spell_casting.glsl") as RDShaderFile

var rd: RenderingDevice
var drawingShader: RID
var drawingTexture: RID
var uniformSet: RID
var drawingPipeline: RID

var textureDirty: bool = false
var isFirstFrame := true

func initialize() -> void:
	rd = RenderingServer.get_rendering_device()
	
	var shaderSpirv: RDShaderSPIRV = SHADER_FILE.get_spirv()
	drawingShader = rd.shader_create_from_spirv(shaderSpirv)
	
	_recreate_texture()
	drawingPipeline = rd.compute_pipeline_create(drawingShader)

func process_drawing(current_mouse_pos: Vector2, previous_mouse_pos: Vector2, current_brush_size: int) -> void:
	if textureDirty:
		call_deferred("_recreate_texture")
		textureDirty = false

	if not textureRect:
		return

	var mousePos := textureRect.screen_to_texel(current_mouse_pos)
	var prevMousePos := textureRect.screen_to_texel(previous_mouse_pos)
	
	if isFirstFrame:
		prevMousePos = mousePos
		isFirstFrame = false
	
	var pc := PackedByteArray()
	pc.resize(PUSH_CONSTANT_SIZE) 
	pc.encode_s32(0, current_brush_size)
	pc.encode_s32(8, mousePos.x)
	pc.encode_s32(12, mousePos.y)
	pc.encode_s32(16, prevMousePos.x)
	pc.encode_s32(20, prevMousePos.y)
	
	var groupsX := (width + 7) / 8
	var groupsY := (height + 7) / 8
	
	var drawingComputeList := rd.compute_list_begin()
	rd.compute_list_bind_compute_pipeline(drawingComputeList, drawingPipeline)
	rd.compute_list_bind_uniform_set(drawingComputeList, uniformSet, 0)
	rd.compute_list_set_push_constant(drawingComputeList, pc, pc.size())
	rd.compute_list_dispatch(drawingComputeList, groupsX, groupsY, 1)
	rd.compute_list_end()

func _exit_tree() -> void:
	if drawingPipeline.is_valid(): rd.free_rid(drawingPipeline)
	if uniformSet.is_valid(): rd.free_rid(uniformSet)
	if drawingTexture.is_valid(): rd.free_rid(drawingTexture)
	if drawingShader.is_valid(): rd.free_rid(drawingShader)

func _recreate_texture() -> void:
	textureDirty = false
	if uniformSet.is_valid(): rd.free_rid(uniformSet)
	if drawingTexture.is_valid(): rd.free_rid(drawingTexture)

	var drawingTextureFormat := RDTextureFormat.new()
	drawingTextureFormat.format = RenderingDevice.DATA_FORMAT_R8G8_UNORM
	drawingTextureFormat.texture_type = RenderingDevice.TEXTURE_TYPE_2D
	drawingTextureFormat.width = width
	drawingTextureFormat.height = height

	drawingTextureFormat.usage_bits = \
		RenderingDevice.TEXTURE_USAGE_SAMPLING_BIT | \
		RenderingDevice.TEXTURE_USAGE_STORAGE_BIT
	drawingTexture = rd.texture_create(drawingTextureFormat, RDTextureView.new())
	
	var drawingTextureUniform := RDUniform.new()
	drawingTextureUniform.uniform_type = RenderingDevice.UNIFORM_TYPE_IMAGE
	drawingTextureUniform.binding = 0
	drawingTextureUniform.add_id(drawingTexture)
	uniformSet = rd.uniform_set_create([drawingTextureUniform], drawingShader, 0)
	
	var drawingTextureWrapper := Texture2DRD.new()
	drawingTextureWrapper.texture_rd_rid = drawingTexture
	textureRect.texture = drawingTextureWrapper
