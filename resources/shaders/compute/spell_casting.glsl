#[compute]
#version 450

layout(local_size_x = 8, local_size_y = 8, local_size_z = 1) in;

layout(rg8, set = 0, binding = 0) restrict uniform image2D canvas;

layout(push_constant, std430) uniform Params {
	int brushSize;
	ivec2 mousePos;
	ivec2 prevMousePos;
} params;

void main() {
	ivec2 id = ivec2(gl_GlobalInvocationID.xy);
	ivec2 size = imageSize(canvas);
    
	if (any(greaterThanEqual(id, size))) return;

	vec2 p = vec2(id);
	vec2 a = vec2(params.prevMousePos);
	vec2 b = vec2(params.mousePos);

	vec2 pa = p - a;
	vec2 ba = b - a;
	float ba_len_sq = dot(ba, ba);
	
	float h = 0.0;
	if (ba_len_sq > 0.0) {
		h = clamp(dot(pa, ba) / ba_len_sq, 0.0, 1.0);
	}
	
	float dist = length(pa - ba * h);

	if (dist <= float(params.brushSize)) {
		imageStore(canvas, id, vec4(1.0, 0.0, 0.0, 0.0));
	}
}
