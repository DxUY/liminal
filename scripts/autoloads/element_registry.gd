extends Node

## Maps element colors to their corresponding element definitions.
var _elements: Dictionary[Color, Element] = {}

## Registers all built-in elements when the registry is initialized.
func _ready() -> void:
	register(Empty.new())
	register(Sand.new())

## Registers an element using its unique color.
func register(element: Element) -> void:
	_elements[element.color] = element

## Returns the element associated with the given color, or `null` if it does not exist.
func get_element(color: Color) -> Element:
	return _elements.get(color)

## Returns `true` if an element with the given color is registered.
func has_element(color: Color) -> bool:
	return _elements.has(color)

## Returns all registered elements indexed by their colors.
func get_all() -> Dictionary[Color, Element]:
	return _elements

## Builds the simplified element database for the compute shader.
func build_gpu_databases() -> Dictionary:
	var element_data := PackedInt32Array()

	# Sort keys by a deterministic property if needed (e.g., to_argb32())
	var keys: Array = _elements.keys()
	keys.sort_custom(func(a: Color, b: Color) -> bool:
		return a.to_argb32() < b.to_argb32()
	)

	for color in keys:
		var element: Element = _elements[color]
		
		# Skip based on color or type if applicable
		if element is Empty:
			continue

		match element:
			var s when s is Solid:
				element_data.push_back(Element.Type.SOLID)
			_:
				element_data.push_back(Element.Type.EMPTY)

	return {"elements": element_data}

## Gather the rgba values of elements and put it inside a 1D image
func build_color_palette() -> Image:
	var image: Image = Image.create(_elements.size(), 1, false, Image.FORMAT_RGBA8)

	var index := 0
	for element: Element in _elements.values():
		image.set_pixel(index, 0, element.color)
		index += 1

	return image
