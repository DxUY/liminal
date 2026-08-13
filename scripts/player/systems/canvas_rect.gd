class_name CanvasRect extends TextureRect

func get_texture_draw_rect() -> Rect2:
	var texSize = texture.get_size() if texture else Vector2.ONE
	var rectSize = size
	var actualScale = min(rectSize.x / texSize.x, rectSize.y / texSize.y)
	var drawSize = texSize * actualScale
	var offset = (rectSize - drawSize) * 0.5
	return Rect2(offset, drawSize)

func screen_to_uv(screen_position: Vector2) -> Vector2:
	var drawRect = get_texture_draw_rect()
	return ((screen_position - global_position) - drawRect.position) / drawRect.size

func screen_to_texel(screen_position: Vector2) -> Vector2i:
	return Vector2i(screen_to_uv(screen_position) * texture.get_size())
