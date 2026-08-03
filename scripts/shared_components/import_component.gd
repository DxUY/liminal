class_name ImportComponent extends Node

## Imports a texture into an Image.
func import_texture(texture: Texture2D) -> Image:
	if texture == null:
		push_error("ImportComponent: Texture is null.")
		return null

	return texture.get_image()

## Imports a compressed texture into an Image.
func import_compressed(texture: CompressedTexture2D) -> Image:
	if texture == null:
		push_error("ImportComponent: Texture is null.")
		return null

	return texture.get_image()

## Duplicates an image.
func import_image(image: Image) -> Image:
	if image == null:
		push_error("ImportComponent: Image is null.")
		return null

	return image.duplicate()
