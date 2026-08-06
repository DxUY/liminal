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

## Builds the single CPU-side GPU database used by the compute shader.
func build_gpu_databases() -> PackedInt32Array:
	var gpu_database := PackedInt32Array()

	var keys := _elements.keys()
	keys.sort()

	for id in keys:
		var element: Element = _elements[id]
		
		# Skip Empty (ID 0) so element ID 1 maps to index 0 in the SSBO array
		if element is Empty or id == 0:
			continue

		# Appends the uniform 9-integer block directly for each element
		element.serialize_gpu(gpu_database)

	return gpu_database

## Gather the rgba values of elements and put it inside a 1D image
func build_color_palette() -> Image:
	var image := Image.create(_elements.size(), 1, false, Image.FORMAT_RGBA8)

	for element: Element in _elements.values():
		image.set_pixel(element.id, 0, element.color)

	return image
