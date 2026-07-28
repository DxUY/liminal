#[compute]
#version 450

layout(local_size_x = 8, local_size_y = 8, local_size_z = 1) in;

layout(rgba32f, binding = 0) uniform readonly image2D CurrentGrid;
layout(rgba32f, binding = 1) uniform writeonly image2D NextGrid;

layout(set = 0, std430, binding = 2) readonly buffer SimulationData {
	uint Width;
	uint Height;
} sim;

struct Element {
	uint type;
	uint dataIndex;
};

layout(set = 0, std430, binding = 3) readonly buffer ElementDatabase {
	Element elements[];
} element_db;

struct Solid {
	uint hardness;
};

layout(set = 0, std430, binding = 4) readonly buffer SolidDatabase {
	Solid solids[];
} solid_db;

bool InBounds(ivec2 p) {
	return p.x >= 0 && p.y >= 0 && p.x < int(sim.Width) && p.y < int(sim.Height);
}

uint GetCell(ivec2 p) {
	return uint(imageLoad(CurrentGrid, p).r);
}

void SetCell(ivec2 p, uint element) {
	imageStore(NextGrid, p, vec4(float(element), 0.0, 0.0, 0.0));
}

void SimulatedSolid(ivec2 cell, uint elementId, Solid solid) {
	ivec2 below = cell + ivec2(0, 1);

	if (InBounds(below) && GetCell(below) == 0u) {
		SetCell(below, elementId);
		SetCell(cell, 0u);
	} else {
		SetCell(cell, elementId);
	}
}

void main() {
	ivec2 cell = ivec2(gl_GlobalInvocationID.xy);

	if (!InBounds(cell)) return;

	uint elementId = GetCell(cell);

	SetCell(cell, elementId);

	Element element = element_db.elements[elementId];

	switch (element.type) {
		case 1u:
			Solid solid = solid_db.solids[element.dataIndex];
			SimulatedSolid(cell, elementId, solid);
			break;

		case 2u:
			break;

		case 3u:
			break;
		default:
			SetCell(cell, elementId);
			break;
	}

	memoryBarrierImage();
}
