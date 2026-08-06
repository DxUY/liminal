#[compute]
#version 450

#extension GL_GOOGLE_include_directive : require
#extension GL_EXT_shader_explicit_arithmetic_types : enable

layout(local_size_x = 8, local_size_y = 8, local_size_z = 1) in;

#include "components/constants_and_uniforms.glslinc"
#include "components/hash_and_loader.glslinc"
#include "components/movement_logic.glslinc"
#include "components/winner_logic.glslinc"

void main() {
	ivec2 gid = ivec2(gl_GlobalInvocationID.xy);
	ivec2 size = imageSize(terrain_read);
	ivec2 lid = ivec2(gl_LocalInvocationID.xy);

	// 1. Cooperative Workgroup Cache Loading (8x8 threads loading 12x12 tile)
	for (int y = lid.y; y < 12; y += 8) {
		for (int x = lid.x; x < 12; x += 8) {
			ivec2 targetGlobal = ivec2(gl_WorkGroupID.xy) * 8 + ivec2(x, y) - ivec2(2);
			ivec2 loaded = loadGlobalData(targetGlobal, size);
			CACHE(x, y) = loaded.x;
			STATE_CACHE(x, y) = loaded.y;
		}
	}

	barrier();

	// 2. Compute Desired Move for local thread
	s_move[lid.y * 8 + lid.x] = calculateDesiredMove(lid, gid);
	
	barrier();

	// Out of bounds check
	if (any(greaterThanEqual(gid, size))) return;

	int currentId = getSharedElement(lid);
	if (currentId < 0) { // Boundary/Wall elements
		imageStore(terrain_write, gid, vec4(float(currentId) / 255.0, 0.0, 0.0, 0.0));
		return;
	}

	int finalElement = 0;
	int finalState = 0;

	// 3. Evaluate Conflict Resolution Winner for this cell
	int winnerType = getWinnerType(lid, gid);

	if (winnerType == WINNER_STRAIGHT) {
		finalElement = getSharedElement(lid + ivec2(0, -1));
		finalState = 1; 
	} else if (winnerType == WINNER_DIAG) {
		// Parity-checked diagonal resolution
		bool checkLeftFirst = ((gid.x + gid.y + params.offset) & 1) == 0;
		int dirA = checkLeftFirst ? 1 : -1;
		int dirB = -dirA;

		ivec2 srcA = lid + ivec2(dirA, -1);
		ivec2 moveA = getCachedOrComputedMove(srcA, gid + ivec2(dirA, -1));

		if (getSharedElement(srcA) > 0 && moveA == ivec2(-dirA, 1)) {
			finalElement = getSharedElement(srcA);
		} else {
			finalElement = getSharedElement(lid + ivec2(dirB, -1));
		}
		finalState = 1;

	} else if (winnerType == WINNER_HORIZ) {
		// Parity-checked immediate horizontal resolution
		bool checkLeftFirst = ((gid.x + gid.y + params.offset) & 1) == 0;
		int dirA = checkLeftFirst ? 1 : -1;
		int dirB = -dirA;

		ivec2 srcA = lid + ivec2(dirA, 0);
		ivec2 moveA = getCachedOrComputedMove(srcA, gid + ivec2(dirA, 0));

		if (getSharedElement(srcA) > 0 && moveA == ivec2(-dirA, 0)) {
			finalElement = getSharedElement(srcA);
			finalState = 1;
		} else {
			ivec2 srcB = lid + ivec2(dirB, 0);
			ivec2 moveB = getCachedOrComputedMove(srcB, gid + ivec2(dirB, 0));
			if (getSharedElement(srcB) > 0 && moveB == ivec2(-dirB, 0)) {
				finalElement = getSharedElement(srcB);
				finalState = 1;
			}
		}

	} else if (currentId > 0) { // Cell wasn't claimed by an incoming mover
		ivec2 myMove = s_move[lid.y * 8 + lid.x];
        
		if (myMove == ivec2(0, 0)) {
			finalElement = currentId;
			finalState = 0; 
		} else {
			ivec2 localTarget = lid + myMove;
			ivec2 globalTarget = gid + myMove;

			int targetWinner = getWinnerType(localTarget, globalTarget);
			bool accepted = false;

			// Re-evaluate target priority to verify THIS specific thread was selected
			bool checkLeftFirst = ((globalTarget.x + globalTarget.y + params.offset) & 1) == 0;
			int dirA = checkLeftFirst ? 1 : -1;

			if (myMove.x == 0 && myMove.y != 0 && targetWinner == WINNER_STRAIGHT) {
				accepted = true;
			} else if (myMove.x != 0 && myMove.y != 0 && targetWinner == WINNER_DIAG) {
				bool iAmCandidateA = (myMove.x == -dirA);
				ivec2 srcA = localTarget + ivec2(dirA, -1);
				ivec2 moveA = getCachedOrComputedMove(srcA, globalTarget + ivec2(dirA, -1));
				bool candidateAValid = (getSharedElement(srcA) > 0 && moveA == ivec2(-dirA, 1));

				if (iAmCandidateA && candidateAValid) accepted = true;
				if (!iAmCandidateA && !candidateAValid) accepted = true;
			} else if (myMove.y == 0 && myMove.x != 0 && targetWinner == WINNER_HORIZ) {
				bool iAmCandidateA = (myMove.x == -dirA);
				ivec2 srcA = localTarget + ivec2(dirA, 0);
				ivec2 moveA = getCachedOrComputedMove(srcA, globalTarget + ivec2(dirA, 0));
				bool candidateAValid = (getSharedElement(srcA) > 0 && moveA == ivec2(-dirA, 0));

				if (iAmCandidateA && candidateAValid) accepted = true;
				if (!iAmCandidateA && !candidateAValid) accepted = true;
			}

			if (accepted) {
				// Vacate position
				finalElement = 0;
				finalState = 0;
			} else {
				// Rejected! Remain in place
				ElementProperties props = element_db.props[currentId - 1];
				finalElement = currentId;

				if (props.type == 2) { // Liquid
					finalState = 0;
				} else { // Solids & Particles
					finalState = (props.friction > props.energy_conservation) ? 0 : 1; 
				}
			}
		}
	}

	// 4. Output pixel to write texture
	imageStore(terrain_write, gid, vec4(float(finalElement) / 255.0, float(finalState) / 255.0, 0.0, 0.0));
}
