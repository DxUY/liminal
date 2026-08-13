shader_type canvas_item;

uniform sampler2D palette;
uniform float variation_strength : hint_range(0.0, 0.5) = 0.08;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453123);
}

void fragment() {
	float value = texture(TEXTURE, UV).r;
	int id = int(round(value * 255.0));

	float palette_u = (float(id) + 0.5) / float(textureSize(palette, 0).x);
	vec4 color = texture(palette, vec2(palette_u, 0.5));

	vec2 pixel = floor(UV * vec2(textureSize(TEXTURE, 0)));
	float noise = hash(pixel);

	float brightness = mix(1.0 - variation_strength, 1.0 + variation_strength, noise);
	color.rgb *= brightness;

	COLOR = color;
}