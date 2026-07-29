shader_type canvas_item;

uniform sampler2D palette;

void vertex() {
	// Called for every vertex the material is visible on.
}

void fragment() {
	float value = texture(TEXTURE, UV).r;
	int id = int(round(value * 255.0));
	float palette_u = (float(id) + 0.5) / float(textureSize(palette, 0).x);
	COLOR = texture(palette, vec2(palette_u, 0.5));
}

//void light() {
//	// Called for every pixel for every light affecting the CanvasItem.
//	// Uncomment to replace the default light processing function with this one.
//}