class_name PathGenerator extends Node 

@export var map: CompressedTexture2D 

func generate() -> Image: 
	var image: Image = map.get_image() 
	image.convert(Image.FORMAT_RGBAF) 

	# TODO: # - Detect regions 
	# - Generate paths 
	# - Modify the image return image
	
	return image
