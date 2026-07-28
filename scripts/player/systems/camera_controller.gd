class_name CameraController extends Node

@onready var camera: Camera2D = %Camera

func get_visible_world_rect() -> Rect2:
	var viewport_size: Vector2 = get_viewport().get_visible_rect().size
	var world_size: Vector2 = viewport_size / camera.zoom
	var top_left: Vector2 = camera.global_position - world_size * 0.5

	return Rect2(top_left, world_size)

func screen_to_world(screen_pos: Vector2) -> Vector2:
	return camera.get_global_transform_with_canvas().affine_inverse() * screen_pos

func world_to_screen(world_pos: Vector2) -> Vector2:
	return camera.get_global_transform_with_canvas() * world_pos
