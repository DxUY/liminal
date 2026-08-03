class_name ElementMappedComponent extends Node

### Converts an image into the simulator's RG8 format.
#func map(image: Image) -> Image:
	#if image == null:
		#push_error("ElementMappedComponent: Image is null.")
		#return null
#
	#var output := Image.create(image.get_width(), image.get_height(), false, Image.FORMAT_RG8)
#
	#for y in image.get_height():
		#for x in image.get_width():
			#var color := image.get_pixel(x, y)
			#var id := ElementRegistry.get_element_id_from_color(color)
			#output.set_pixel(x, y, Color8(id, 0, 0, 255))
#
	#return output
