#[compute]
#version 450

#extension GL_GOOGLE_include_directive : require

#include "../components/constants_&_uniforms.glslinc"
#include "../components/hash_&_loader.glslinc"

void main() {
	ivec2 gid = ivec2(gl_GlobalInvocationID.xy);
	ivec2 size = imageSize(terrain);
}
