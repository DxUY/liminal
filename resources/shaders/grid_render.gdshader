shader_type canvas_item;

uniform sampler2D sim_texture : filter_nearest, repeat_disable;

void fragment()
{
    COLOR = texture(sim_texture, vec2(UV.x, 1.0 - UV.y));
}