class_name AsepriteParser extends RefCounted

const ASE_MAGIC := 0xA5E0
const FRAME_MAGIC := 0xF1FA

const CHUNK_LAYER := 0x2004
const CHUNK_CEL := 0x2005

const CEL_RAW := 0
const CEL_LINKED := 1
const CEL_COMPRESSED := 2

func parse(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		push_error("Aseprite file does not exist: " + path)
		return {}

	var file := FileAccess.open(path, FileAccess.READ)

	if file == null:
		push_error("Could not open Aseprite file: " + path)
		return {}

	# Aseprite uses little-endian byte order.
	file.big_endian = false

	var header := _read_header(file)
	if header.is_empty(): return {}

	var layers := _read_frame(file)
	if layers.is_empty(): return {}

	return {
		"width": header.width,
		"height": header.height,
		"frames": header.frames,
		"color_depth": header.color_depth,
		"layers": layers
	}

func _read_header(file: FileAccess) -> Dictionary:
	if file.get_length() < 128:
		push_error("Invalid Aseprite file: file is smaller than 128 bytes.")
		return {}

	var file_size := file.get_32()
	var magic := file.get_16()
	var frames := file.get_16()
	var width := file.get_16()
	var height := file.get_16()
	var color_depth := file.get_16()

	if magic != ASE_MAGIC:
		push_error("Invalid Aseprite magic number: 0x" + String.num_int64(magic, 16))
		return {}

	if color_depth != 32:
		push_error("AsepriteParser only supports RGBA 32-bit files. " + "Color depth: " + str(color_depth))
		return {}

	# Flags.
	file.get_32()

	# Deprecated frame duration.
	file.get_16()

	# Reserved.
	file.get_32()
	file.get_32()

	# Transparent palette index.
	file.get_8()

	# Reserved.
	file.get_buffer(3)

	# Number of colors.
	file.get_16()

	# Pixel aspect ratio.
	file.get_8()
	file.get_8()

	# Grid information.
	_read_s16(file)
	_read_s16(file)
	file.get_16()
	file.get_16()

	# Remaining header bytes.
	file.get_buffer(84)

	return {
		"file_size": file_size,
		"frames": frames,
		"width": width,
		"height": height,
		"color_depth": color_depth
	}

func _read_frame(file: FileAccess) -> Array:
	var frame_start := file.get_position()

	var frame_size := file.get_32()
	var frame_magic := file.get_16()

	if frame_magic != FRAME_MAGIC:
		push_error("Invalid Aseprite frame magic.")
		return []

	var old_chunk_count := file.get_16()

	# Frame duration.
	file.get_16()

	# Reserved.
	file.get_buffer(2)

	# Modern chunk count.
	var new_chunk_count := file.get_32()

	var chunk_count := new_chunk_count

	# Older Aseprite files use the 16-bit count.
	if chunk_count == 0:
		chunk_count = old_chunk_count

	var frame_end := frame_start + frame_size

	var layers: Array = []
	var cels: Array = []

	for i in range(chunk_count):
		if file.get_position() >= frame_end:
			break

		var chunk_start := file.get_position()

		var chunk_size := file.get_32()
		var chunk_type := file.get_16()

		if chunk_size < 6:
			push_error("Invalid Aseprite chunk size.")
			return []

		var chunk_end := chunk_start + chunk_size

		match chunk_type:
			CHUNK_LAYER:
				var layer := _read_layer(file)

				if not layer.is_empty():
					layer["index"] = layers.size()
					layers.append(layer)

			CHUNK_CEL:
				var cel := _read_cel(file, chunk_end)

				if not cel.is_empty():
					cels.append(cel)

		# Always move to the next chunk.
		file.seek(chunk_end)

	# Attach cel information to the appropriate layer.
	for cel in cels:
		var layer_index: int = cel.layer_index

		if layer_index < 0: continue
		if layer_index >= layers.size(): continue

		layers[layer_index].merge(cel)

	return layers

func _read_layer(file: FileAccess) -> Dictionary:
	var flags := file.get_16()
	var layer_type := file.get_16()
	var child_level := file.get_16()

	# Layer width/height.
	# Not needed because cel dimensions give us the actual pixel data.
	file.get_16()
	file.get_16()

	# Blend mode.
	file.get_16()

	# Layer opacity.
	var opacity := file.get_8()

	# Reserved.
	file.get_buffer(3)

	var name := _read_string(file)

	return {
		"name": name,
		"flags": flags,
		"type": layer_type,
		"child_level": child_level,
		"opacity": opacity,
		"visible": (flags & 1) != 0
	}

func _read_cel(file: FileAccess, chunk_end: int) -> Dictionary:

	var layer_index := file.get_16()

	var x := _read_s16(file)
	var y := _read_s16(file)

	var opacity := file.get_8()
	var cel_type := file.get_16()

	var z_index := _read_s16(file)

	# Reserved.
	file.get_buffer(5)

	match cel_type:
		CEL_RAW:
			return _read_raw_cel(
				file,
				chunk_end,
				layer_index,
				x,
				y,
				opacity,
				z_index
			)

		CEL_COMPRESSED:
			return _read_compressed_cel(
				file,
				chunk_end,
				layer_index,
				x,
				y,
				opacity,
				z_index
			)

		CEL_LINKED:
			return {}

		_:
			push_warning(
				"Unsupported Aseprite cel type: " +
				str(cel_type)
			)
			return {}

func _read_raw_cel(file: FileAccess, chunk_end: int, layer_index: int, x: int, y: int, opacity: int, z_index: int) -> Dictionary:
	var width := file.get_16()
	var height := file.get_16()

	var expected_size := width * height * 4

	if file.get_position() + expected_size > chunk_end:
		push_error("Aseprite raw cel contains insufficient pixel data.")
		return {}

	var pixels := file.get_buffer(expected_size)

	if pixels.size() != expected_size:
		push_error("Failed to read raw cel pixel data.")
		return {}

	var image := Image.create_from_data(
		width,
		height,
		false,
		Image.FORMAT_RGBA8,
		pixels
	)

	return {
		"layer_index": layer_index,
		"x": x,
		"y": y,
		"width": width,
		"height": height,
		"opacity": opacity,
		"z_index": z_index,
		"image": image
	}

func _read_compressed_cel(file: FileAccess, chunk_end: int, layer_index: int, x: int, y: int, opacity: int, z_index: int) -> Dictionary:
	var width := file.get_16()
	var height := file.get_16()

	var compressed_size := chunk_end - file.get_position()

	if compressed_size <= 0:
		push_error("Aseprite compressed cel contains no data.")
		return {}

	var compressed := file.get_buffer(compressed_size)
	var expected_size := width * height * 4
	var pixels := compressed.decompress(expected_size, FileAccess.COMPRESSION_DEFLATE)

	if pixels.is_empty():
		push_error("Failed to decompress Aseprite cel.")
		return {}

	if pixels.size() != expected_size:
		push_error("Decompressed Aseprite cel has incorrect size. " + "Expected: " + str(expected_size) + " Got: " + str(pixels.size()))
		return {}

	var image := Image.create_from_data(
		width,
		height,
		false,
		Image.FORMAT_RGBA8,
		pixels
	)

	return {
		"layer_index": layer_index,
		"x": x,
		"y": y,
		"width": width,
		"height": height,
		"opacity": opacity,
		"z_index": z_index,
		"image": image
	}

func _read_string(file: FileAccess) -> String:
	var length := file.get_16()

	if length <= 0: return ""
	var bytes := file.get_buffer(length)
	return bytes.get_string_from_utf8()

func _read_s16(file: FileAccess) -> int:
	var value := file.get_16()

	if value >= 0x8000:
		value -= 0x10000

	return value
