extends Node

## Maps element IDs to their corresponding element definitions.
var _elements: Dictionary[int, Element] = {}

## Registers all built-in elements when the registry is initialized.
func _ready() -> void:
	register(Empty.new())
	register(Sand.new())
	register(Water.new())

## Registers an element using its unique ID.
func register(element: Element) -> void:
	_elements[element.id] = element

## Returns the element associated with the given ID, or `null` if it does not exist.
func get_element(id: int) -> Element:
	return _elements.get(id)

## Returns `true` if an element with the given ID is registered.
func has_element(id: int) -> bool:
	return _elements.has(id)

## Returns all registered elements indexed by their IDs.
func get_all() -> Dictionary[int, Element]:
	return _elements

## Builds the CPU-side GPU databases used by the compute shader.
func build_gpu_databases() -> Dictionary:
	var element_data := PackedInt32Array()
	var solid_data := PackedInt32Array()
	var liquid_data := PackedInt32Array()

	var solid_index := 0
	var liquid_index := 0

	for element in _elements.values():
		if element is Empty:
			element_data.push_back(Element.Type.EMPTY)
			element_data.push_back(0)

		elif element is Solid:
			element_data.push_back(Element.Type.SOLID)
			element_data.push_back(solid_index)

			element.serialize_gpu(solid_data)
			solid_index += 1

		elif element is Liquid:
			element_data.push_back(Element.Type.LIQUID)
			element_data.push_back(liquid_index)

			element.serialize_gpu(liquid_data)
			liquid_index += 1

	return {
		"elements": element_data,
		"solids": solid_data,
		"liquid": liquid_data
	}

## Gather the rgba values of elements and put it inside a 1D image
func build_color_palette() -> Image:
	var image := Image.create(_elements.size(), 1, false, Image.FORMAT_RGBA8)

	for element: Element in _elements.values():
		image.set_pixel(element.id, 0, element.color)

	return image
