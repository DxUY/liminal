shader_type canvas_item;

uniform sampler2D sim_texture;

void fragment() {
	COLOR = texture(sim_texture, UV).rgba;
	
	//COLOR = vec4(1.0, 0.0, 0.0, 1.0);
}