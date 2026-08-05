#[compute]
#version 450

#extension GL_GOOGLE_include_directive : require

layout(local_size_x = 8, local_size_y = 8, local_size_z = 1) in;

#include "components/constants_and_uniforms.glslinc"
#include "components/hash_and_loader.glslinc"
#include "components/movement_logic.glslinc"
#include "components/behavior_registry.glslinc"
#include "components/winner_logic.glslinc"

void main() {
	ivec2 gid = ivec2(gl_GlobalInvocationID.xy);
	ivec2 size = imageSize(terrain_read);
	ivec2 lid = ivec2(gl_LocalInvocationID.xy);

	for (int y = lid.y; y < 12; y += 8) {
		for (int x = lid.x; x < 12; x += 8) {
			ivec2 targetGlobal = ivec2(gl_WorkGroupID.xy) * 8 + ivec2(x, y) - ivec2(2);
			ivec2 loaded = loadGlobalData(targetGlobal, size);
			CACHE(x, y) = loaded.x;
			STATE_CACHE(x, y) = loaded.y;
		}
	}

	barrier();

	s_move[lid.y * 8 + lid.x] = getDesiredMoveShared(lid, gid);
	barrier();

	if (any(greaterThanEqual(gid, size))) return;

	int currentId = getSharedElement(lid);
	if (currentId < 0) {
		imageStore(terrain_write, gid, vec4(float(currentId) / 255.0, 0.0, 0.0, 0.0));
		return;
	}

	int finalElement = 0;
	int finalState = 0;
	int winnerType = getWinnerType(lid, gid);

	if (winnerType == WINNER_STRAIGHT) {
		finalElement = getSharedElement(lid + ivec2(0, -1));
		finalState = 1; 
	} else if (winnerType == WINNER_DIAG_LEFT) {
		finalElement = getSharedElement(lid + ivec2(1, -1));
		finalState = 1;
	} else if (winnerType == WINNER_DIAG_RIGHT) {
		finalElement = getSharedElement(lid + ivec2(-1, -1));
		finalState = 1;
	} else if (winnerType == WINNER_HORIZ_LEFT) {
		finalElement = getSharedElement(lid + ivec2(1, 0));
		finalState = 1;
	} else if (winnerType == WINNER_HORIZ_RIGHT) {
		finalElement = getSharedElement(lid + ivec2(-1, 0));
		finalState = 1;
	} else if (currentId > 0) {
		ivec2 myMove = s_move[lid.y * 8 + lid.x];
        
		if (myMove == MOVE_NONE) {
			finalElement = currentId;
			finalState = 0; 
		} else {
			ivec2 localTarget = lid + myMove;
			ivec2 globalTarget = gid + myMove;

			int targetWinner = getWinnerType(localTarget, globalTarget);

			bool accepted = false;
			
			if (myMove == MOVE_DOWN && targetWinner == WINNER_STRAIGHT) accepted = true;
			if (myMove == MOVE_DIAG_LEFT && targetWinner == WINNER_DIAG_LEFT) accepted = true;
			if (myMove == MOVE_DIAG_RIGHT && targetWinner == WINNER_DIAG_RIGHT) accepted = true;
			if (myMove == MOVE_HORIZ_LEFT && targetWinner == WINNER_HORIZ_LEFT) accepted = true;
			if (myMove == MOVE_HORIZ_RIGHT && targetWinner == WINNER_HORIZ_RIGHT) accepted = true;

			if (accepted) {
				finalElement = 0;
				finalState = 0;
			} else {
				int currentType = elements_db.data[(currentId - 1) * 2 + 0];
				int currentSubIndex = elements_db.data[(currentId - 1) * 2 + 1];

				int friction = 0;
				int energyConservation = 0;

				if (currentType == 1) {
    					friction = solids_db.data[currentSubIndex * PROP_STRIDE + 3];
					energyConservation = solids_db.data[currentSubIndex * PROP_STRIDE + 4];
				} else if (currentType == 2) {
					friction = liquid_db.data[currentSubIndex * PROP_STRIDE + 3];
    					energyConservation = liquid_db.data[currentSubIndex * PROP_STRIDE + 4];
				}

				finalElement = currentId;
                
				if (friction > energyConservation) finalState = 0; 
				else finalState = 1; 
                	}
            	}
    	}

	imageStore(terrain_write, gid, vec4(float(finalElement) / 255.0, float(finalState) / 255.0, 0.0, 0.0));
}
