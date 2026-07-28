class_name Canvas extends Sprite2D

var world_rect: Rect2
var canvas_size: Vector2i
var image: Image

func initialize(rect: Rect2) -> void:
	world_rect = rect
	canvas_size = Vector2i(rect.size)

	image = Image.create(canvas_size.x, canvas_size.y, false, Image.FORMAT_RGBA8)
	image.fill(Color.TRANSPARENT)

	texture = ImageTexture.create_from_image(image)

func world_to_pixel(world: Vector2) -> Vector2i:
	return Vector2i((world - world_rect.position).floor())
