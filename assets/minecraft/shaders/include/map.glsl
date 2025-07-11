vec2 coords;
int displayId;

void getInfoFromColor(vec4 color) {
    coords = color.rg;
    displayId = int(color.b * 255);
}

// in blocks
const float[] stormSizes = float[](
    1600,
    800,
    400,
    200,
    100,
    50,
    35,
    20,
    0
);

#define CHEST_LOAD_TYPE -3
#define HEALTH_TYPE -2
#define DELETE_TYPE 0
#define MAP_TYPE 1
#define MARKER_TYPE 2
#define COMPASS_TYPE 3
#define CIRCLE_TYPE 4
#define FULL_CIRCLE_TYPE 5
#define PURPLE_CIRCLE_TYPE 6
#define FULL_PURPLE_CIRCLE_TYPE 7

#define oldOffset f1
#define offset f2
#define serverTime i1

#define stormId i1
#define relX i2
#define relY i3

#define COMPASS_WIDTH 110
#define FULL_MAP_SIZE 1600
