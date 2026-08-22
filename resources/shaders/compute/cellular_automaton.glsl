#[compute]
#version 450

#extension GL_GOOGLE_include_directive : require

#include "../components/constants_&_uniforms.glslinc"
#include "../components/hash_&_loader.glslinc"

// Matches the 8x8 thread group dispatch blocks in your GDScript
layout(local_size_x = 8, local_size_y = 8, local_size_z = 1) in;

void main() {
	ivec2 gid = ivec2(gl_GlobalInvocationID.xy);
	ivec2 size = imageSize(terrain);
}
