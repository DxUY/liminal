class_name BodyAssemblyComponent extends Node

const CANVAS_SIZE := Vector2i(48, 48)

@export_file("*.aseprite")
var aseprite_file_path: String

var body_parts: Dictionary = {}

func assemble_character() -> Image:
	body_parts.clear()

	if aseprite_file_path.is_empty():
		push_error("No Aseprite file has been assigned.")
		return null

	var parser := AsepriteParser.new()
	var data := parser.parse(aseprite_file_path)

	if data.is_empty():
		return null

	if Vector2i(data.width, data.height) != CANVAS_SIZE:
		push_error("Invalid character canvas size. " + "Expected 48x48, got " + str(data.width) + "x" + str(data.height))
		return null

	for layer in data.layers:
		_add_body_part(layer)

	return _build_character_image()

func _add_body_part(layer: Dictionary) -> void:
	var layer_name: String = layer.get("name", "")

	if layer_name.is_empty(): return
	if not layer.has("image"): return

	body_parts[layer_name] = {
		"image": layer.image,
		"position": Vector2(
			layer.get("x", 0),
			layer.get("y", 0)
		),
		"z_index": layer.get("z_index", 0),
		"opacity": layer.get("opacity", 255),
		"visible": layer.get("visible", true)
	}

func _build_character_image() -> Image:
	var image := Image.create(
		CANVAS_SIZE.x,
		CANVAS_SIZE.y,
		false,
		Image.FORMAT_RGBA8
	)

	image.fill(Color.TRANSPARENT)

	var parts: Array = body_parts.values()

	parts.sort_custom(
		func(a: Dictionary, b: Dictionary) -> bool:
			return a["z_index"] < b["z_index"]
	)

	for part in parts:
		if not part["visible"]:
			continue

		var part_image: Image = part["image"]
		var position: Vector2 = part["position"]

		image.blend_rect(
			part_image,
			Rect2i(
				0,
				0,
				part_image.get_width(),
				part_image.get_height()
			),
			Vector2i(position)
		)

	return image
