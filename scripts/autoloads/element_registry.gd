extends Node

## Maps element IDs to their corresponding element definitions.
var _elements: Dictionary[int, Element] = {}

## Registers all built-in elements when the registry is initialized.
func _ready() -> void:
	register(Empty.new())
	register(Sand.new())

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

## Builds the simplified element database for the compute shader.
func build_gpu_databases() -> Dictionary:
	var element_data := PackedInt32Array()

	var keys : Array = _elements.keys()
	keys.sort()

	for id in keys:
		var element: Element = _elements[id]
		
		if id == 0: continue

		match element:
			var e when e is Empty:
				continue
			var s when s is Solid:
				element_data.push_back(Element.Type.SOLID)
			_:
				element_data.push_back(Element.Type.EMPTY)

	return {"elements": element_data}

## Gather the rgba values of elements and put it inside a 1D image
func build_color_palette() -> Image:
	var image : Image = Image.create(_elements.size(), 1, false, Image.FORMAT_RGBA8)

	for element: Element in _elements.values():
		image.set_pixel(element.id, 0, element.color)

	return image
