#[compute]
#version 450

#extension GL_GOOGLE_include_directive : require

#include "../components/constants_&_uniforms.glslinc"
#include "../components/hash_&_loader.glslinc"

#include "../components/behaviors/solid.glslinc"

void main() {
	ivec2 gid = ivec2(gl_GlobalInvocationID.xy);
	ivec2 size = imageSize(terrain);

	if (isOutOfBounds(gid, size)) return;

	vec4 color = loadCellData(gid);
	if (color.a == 0.0) return;

	uint color_argb32 = (uint(color.a * 255.0) << 24) | 
	                    (uint(color.r * 255.0) << 16) | 
	                    (uint(color.g * 255.0) << 8) | 
	                    uint(color.b * 255.0);

	int element_type = 0;
	for (int i = 0; i < elements_db.data.length(); i += 2) {
		uint db_color = uint(elements_db.data[i]);
		if (db_color == color_argb32) {
			element_type = elements_db.data[i + 1];
			break;
		}
	}

	switch (element_type) {
		case 1:
			step_solid(gid);
			break;	
		default:
			break;
	}

	imageStore(terrain, gid, color);
}
