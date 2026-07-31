#[compute]
#version 450

layout(local_size_x = 8, local_size_y = 8, local_size_z = 1) in;

layout(rg8, set = 0, binding = 0) uniform readonly image2D terrain_read;
layout(rg8, set = 0, binding = 1) uniform writeonly image2D terrain_write;

layout(set = 0, binding = 2, std430) buffer ElementData { int data[]; } elements_db;
layout(set = 0, binding = 3, std430) buffer SolidData { int data[]; } solids_db;

layout(push_constant, std430) uniform Params {
    int offset;
    float time;
    ivec2 mousePos;
} params;

const ivec2 MOVE_NONE = ivec2(0, 0);
const ivec2 MOVE_DOWN = ivec2(0, 1);
const ivec2 MOVE_LEFT = ivec2(-1, 1);
const ivec2 MOVE_RIGHT = ivec2(1, 1);

const int WINNER_NONE = 0;
const int WINNER_STRAIGHT = 1;
const int WINNER_DIAG_LEFT = 2;
const int WINNER_DIAG_RIGHT = 3;

shared int s_cache[144];
shared ivec2 s_move[64];

#define CACHE(x, y) s_cache[(y) * 12 + (x)]

uint murmurHash13(uvec3 src) {
    const uint M = 0x5bd1e995u;
    uint h = 1190494759u;
    src *= M; src ^= src >> 24u; src *= M;
    h *= M; h ^= src.x; h *= M; h ^= src.y; h *= M; h ^= src.z;
    h ^= h >> 13u; h *= M; h ^= h >> 15u;
    return h;
}

float hash13(vec3 src) {
    uint h = murmurHash13(floatBitsToUint(src));
    return uintBitsToFloat(h & 0x007fffffu | 0x3f800000u) - 1.0;
}

int loadGlobalElement(ivec2 id, ivec2 size) {
    if (params.mousePos == id) return 1;
    if (id.y >= size.y) return 1;
    if (id.y < 0 || id.x < 0 || id.x >= size.x) return -1;
    return int(imageLoad(terrain_read, id).r);
}

int getSharedElement(ivec2 localPos) {
    return CACHE(localPos.x + 2, localPos.y + 2);
}

int getElementDensity(int elementId) {
    if (elementId <= 0) return 0;
    if (elementId == 1) {
        return elements_db.data[0];
    }
    return 0;
}

ivec2 getDesiredMoveShared(ivec2 localPos, ivec2 globalPos) {
    int currentId = getSharedElement(localPos);
    if (currentId <= 0) return MOVE_NONE;

    int currentDensity = getElementDensity(currentId);

    int idBelow      = getSharedElement(localPos + ivec2(0, 1));
    int idBelowLeft  = getSharedElement(localPos + ivec2(-1, 1));
    int idBelowRight = getSharedElement(localPos + ivec2(1, 1));

    bool canMoveDown = (idBelow == 0) || (currentDensity > getElementDensity(idBelow));
    bool canLeft     = (idBelowLeft == 0) || (currentDensity > getElementDensity(idBelowLeft));
    bool canRight    = (idBelowRight == 0) || (currentDensity > getElementDensity(idBelowRight));

    if (canMoveDown && idBelow != -1) {
        if (idBelow == 0 || currentDensity > getElementDensity(idBelow)) {
            return MOVE_DOWN;
        }
    }

    if (canLeft && canRight) {
        float rng = hash13(vec3(globalPos, params.time));
        bool left = rng > 0.5;
        if (((globalPos.x + globalPos.y + params.offset) & 1) != 0) {
            left = !left;
        }
        return left ? MOVE_LEFT : MOVE_RIGHT;
    } else if (canLeft) {
        return MOVE_LEFT;
    } else if (canRight) {
        return MOVE_RIGHT;
    }
    
    return MOVE_NONE;
}

ivec2 getCachedOrComputedMove(ivec2 localPos, ivec2 globalPos) {
    if (localPos.x >= 0 && localPos.x < 8 && localPos.y >= 0 && localPos.y < 8) {
        return s_move[localPos.y * 8 + localPos.x];
    }
    return getDesiredMoveShared(localPos, globalPos);
}

int getWinnerType(ivec2 localTarget, ivec2 globalTarget) {
    ivec2 srcStraight = localTarget + ivec2(0, -1);
    if (getSharedElement(srcStraight) > 0) {
        ivec2 move = getCachedOrComputedMove(srcStraight, globalTarget + ivec2(0, -1));
        if (move == MOVE_DOWN) return WINNER_STRAIGHT;
    }

    bool prioritizeLeftFirst = ((globalTarget.x + globalTarget.y + params.offset) & 1) == 0;

    if (prioritizeLeftFirst) {
        ivec2 srcDiagLeft = localTarget + ivec2(1, -1);
        if (getSharedElement(srcDiagLeft) > 0) {
            ivec2 move = getCachedOrComputedMove(srcDiagLeft, globalTarget + ivec2(1, -1));
            if (move == MOVE_LEFT) return WINNER_DIAG_LEFT;
        }
        ivec2 srcDiagRight = localTarget + ivec2(-1, -1);
        if (getSharedElement(srcDiagRight) > 0) {
            ivec2 move = getCachedOrComputedMove(srcDiagRight, globalTarget + ivec2(-1, -1));
            if (move == MOVE_RIGHT) return WINNER_DIAG_RIGHT;
        }
    } else {
        ivec2 srcDiagRight = localTarget + ivec2(-1, -1);
        if (getSharedElement(srcDiagRight) > 0) {
            ivec2 move = getCachedOrComputedMove(srcDiagRight, globalTarget + ivec2(-1, -1));
            if (move == MOVE_RIGHT) return WINNER_DIAG_RIGHT;
        }
        ivec2 srcDiagLeft = localTarget + ivec2(1, -1);
        if (getSharedElement(srcDiagLeft) > 0) {
            ivec2 move = getCachedOrComputedMove(srcDiagLeft, globalTarget + ivec2(1, -1));
            if (move == MOVE_LEFT) return WINNER_DIAG_LEFT;
        }
    }

    return WINNER_NONE;
}

void main() {
    ivec2 gid = ivec2(gl_GlobalInvocationID.xy);
    ivec2 size = imageSize(terrain_read);
    ivec2 lid = ivec2(gl_LocalInvocationID.xy);

    for (int y = lid.y; y < 12; y += 8) {
        for (int x = lid.x; x < 12; x += 8) {
            ivec2 targetGlobal = ivec2(gl_WorkGroupID.xy) * 8 + ivec2(x, y) - ivec2(2);
            CACHE(x, y) = loadGlobalElement(targetGlobal, size);
        }
    }
    barrier();

    s_move[lid.y * 8 + lid.x] = getDesiredMoveShared(lid, gid);
    barrier();

    if (any(greaterThanEqual(gid, size))) return;

    int currentId = getSharedElement(lid);
    if (currentId < 0) {
        imageStore(terrain_write, gid, vec4(float(currentId), 0.0, 0.0, 0.0));
        return;
    }

    int finalElement = 0;
    int winnerType = getWinnerType(lid, gid);

    if (winnerType == WINNER_STRAIGHT) {
        finalElement = getSharedElement(lid + ivec2(0, -1));
    } else if (winnerType == WINNER_DIAG_LEFT) {
        finalElement = getSharedElement(lid + ivec2(1, -1));
    } else if (winnerType == WINNER_DIAG_RIGHT) {
        finalElement = getSharedElement(lid + ivec2(-1, -1));
    } else if (currentId > 0) {
        ivec2 myMove = s_move[lid.y * 8 + lid.x];
        
        if (myMove == MOVE_NONE) {
            finalElement = currentId;
        } else {
            ivec2 localTarget = lid + myMove;
            ivec2 globalTarget = gid + myMove;

            int targetWinner = getWinnerType(localTarget, globalTarget);

            bool accepted = false;
            if (myMove == MOVE_DOWN && targetWinner == WINNER_STRAIGHT) accepted = true;
            if (myMove == MOVE_LEFT && targetWinner == WINNER_DIAG_LEFT) accepted = true;
            if (myMove == MOVE_RIGHT && targetWinner == WINNER_DIAG_RIGHT) accepted = true;

            if (accepted) {
                finalElement = 0;
            } else {
                finalElement = currentId;
            }
        }
    }

    imageStore(terrain_write, gid, vec4(float(finalElement), 0.0, 0.0, 0.0));
}
