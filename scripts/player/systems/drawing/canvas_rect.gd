class_name CanvasRect extends TextureRect

func get_texture_draw_rect() -> Rect2:
	var tex_size = texture.get_size() if texture else Vector2.ONE
	var rect_size = size
	var actual_scale = min(rect_size.x / tex_size.x, rect_size.y / tex_size.y)
	var draw_size = tex_size * actual_scale
	var offset = (rect_size - draw_size) * 0.5
	return Rect2(offset, draw_size)

func screen_to_uv(screen_position: Vector2) -> Vector2:
	return ((screen_position - global_position) - get_texture_draw_rect().position) / get_texture_draw_rect().size

func screen_to_texel(screen_position: Vector2) -> Vector2i:
	return Vector2i(screen_to_uv(screen_position) * texture.get_size())
