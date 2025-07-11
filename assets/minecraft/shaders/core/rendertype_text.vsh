#version 150

#moj_import <fog.glsl>
#moj_import <map.glsl>
#moj_import <identifiers.glsl>

in vec3 Position;
in vec4 Color;
in vec2 UV0;
in ivec2 UV2;

uniform vec2 ScreenSize;

uniform sampler2D Sampler0;
uniform sampler2D Sampler2;

uniform mat4 ModelViewMat;
uniform mat4 ProjMat;
uniform mat3 IViewRotMat;
uniform int FogShape;

out float vertexDistance;
out vec4 vertexColor;
out vec2 texCoord0;

out vec2 pos;

flat out float f1;
flat out float f2;
flat out int i1;
flat out int i2;
flat out int i3;

flat out float xOffset;
flat out int type;
flat out vec4 ogColor;

vec2 calcGuiPixel(mat4 ProjMat) {
	return vec2(ProjMat[0][0], ProjMat[1][1]) / 2.0;
}

//default - 128
const int mapSize = 300;
const int margin = 32;


const ivec2[] corners = ivec2[](
    ivec2(-1, -1),
    ivec2(-1, 1),
    ivec2(1, 1),
    ivec2(1, -1)
);

vec2 rotate(vec2 point, vec2 center, float rot) {
	float x = center.x + (point.x-center.x)*cos(rot) - (point.y-center.y)*sin(rot);
    float y = center.y + (point.x-center.x)*sin(rot) + (point.y-center.y)*cos(rot);

    return vec2(x, y);
}

#define PI 3.1415926535

//Bottom center
const int health = 10;
const int health_max = 101;
const int shield = 11;
const int shield_max = 111;
const int ammo = 12;

//Top right (below minimap)
const int time = 50;
const int alive = 51;
const int kills = 52;

//Bottom right
const int build = 30;
const int inv = 20;

//Right center (mats)
const int mat_wood = 41;
const int mat_brick = 42;
const int mat_metal = 43;

//Top left
const int player_1 = 61;
const int player_2 = 62;
const int player_3 = 63;
const int player_4 = 64;

//yaw (top UI)
const int yaw = 65;

//medkit, shields, etc
const int load = 66;

const int build_keys = 67;
const int build_toggle = 68;

const int inv_keys = 69;
const int inv_toggle = 70;

//build text guide
const int build_text = 71;
const int build_brackets = 72;
const int build_left = 73;
const int build_right = 74;
const int build_drop = 75;

const int full_map = 76;
const int victory = 77;

//Each offset has one dedicated color (?)
vec3 getColor(int i) {
  switch (i) {

    //red
    //case 1:
    //  return vec3(255, 0, 0)/255.;
    //  break;

    case shield_max:
        return vec3(186, 233, 255)/255.;
        break;

    case health_max:
        return vec3(209, 255, 196)/255.;
        break;

    case build_brackets:
        return vec3(170, 170, 170)/255.;
        break;

    case build_left:
        return vec3(255, 85, 85)/255.;
        break;

    case build_right:
        return vec3(85, 85, 255)/255.;
        break;

    case build_drop:
        return vec3(255, 255, 85)/255.;
        break;

    default:
        return vec3(1, 1, 1);
        break;
  }
}

vec2 realPixel;
vec2 guiPixel;

void OFFSET(vec2 screen, vec2 pixels, vec2 pixelScale) {
    gl_Position.xy += gl_Position.w * screen + pixels * pixelScale;
}

void NORMALIZE(vec2 screen, vec2 pixels) {
    OFFSET(screen, pixels, guiPixel);

    gl_Position.xy /= guiPixel.x;
    gl_Position.xy *= realPixel.x * 2;
}

void main() {
    ogColor = Color;

    //vanilla
    gl_Position = ProjMat * ModelViewMat * vec4(Position, 1.0);
    vertexDistance = fog_distance(ModelViewMat, IViewRotMat * Position, FogShape);
    vertexColor = Color * texelFetch(Sampler2, UV2 / 16, 0);
    texCoord0 = UV0;

    // define pixels
    guiPixel = calcGuiPixel(ProjMat);
    // realPixel is used 
    realPixel = vec2(gl_Position.w / ScreenSize.x * ScreenSize.y, -gl_Position.w) / 1080;

    // this part tries to pick the best pixel size to use 
    {
        vec2 singlePixel = vec2(gl_Position.w / 2) / ScreenSize;
        float perfectY = round(realPixel.y / singlePixel.y) * singlePixel.y; // floor, round or ceil
        vec2 perfectPixel = vec2(-perfectY / singlePixel.y * singlePixel.x, perfectY);
        if (abs(perfectPixel.y * 1080) > 1) {
            realPixel = perfectPixel;
        }
    }

    // another form of realPixel
    vec2 transformedPixel = realPixel * 2 * vec2(1, -1);

    //SHADOW REMOVER Cred: PuckiSilver
    //Use this color code to remove it: #4e5c24
    if (Color.xyz == vec3(78/255., 92/255., 36/255.) && (Position.z == 0.03 || Position.z == 0.06 || Position.z == 0.12)) {
        vertexColor.rgb = texelFetch(Sampler2, UV2 / 16, 0).rgb; // remove color from no shadow marker
    } else if (Color.xyz == vec3(19/255., 23/255., 9/255.) && Position.z == 0) {
        gl_Position = vec4(2,2,2,1); // move shadow off screen
    } else if (Color == vec4(16/255., 0., 0., Color.a) && Position.z == 0) {
        //and remove load bar shadow
        //remove the color of the shadow from the yaw number text
        type = DELETE_TYPE;
        return;
    }
    //move the actionbar's shadows up
    else if ((Color == vec4(17/255., 0., 0., Color.a) || Color == vec4(18/255., 0., 0., Color.a)) && Position.z == 0) {
        NORMALIZE(vec2(0, 1), vec2(154, 144));
        OFFSET(vec2(0, -1), vec2(-154, 194), transformedPixel);

    //remove numbers from hotbar
    } else if (round(Position.z) == 200){
        vertexColor = vec4(0);
    //ITEM NAMES (move up)
    //z check is to only move the item name
    } else if (texture(Sampler0, vec2(0, 18/255.)) == vec4(237/255.,1,33/255.,1) && round(Position.z) == 0){
        NORMALIZE(vec2(0, 1), vec2(0, 116));
        OFFSET(vec2(0, -1), vec2(0, 159), transformedPixel);
    //ACTIONBAR (elim text)
    } else if (ivec4(texture(Sampler0, vec2(0, 18/255.))*255) == ivec4(35,201,151,124)){
        NORMALIZE(vec2(0, 1), vec2(0, 116));
        OFFSET(vec2(0, -1), vec2(0, 245), transformedPixel);
    }

    if (vertexColor.a == 0) {
        return;
    }

    // [ HUD ]

    // Text Offsets
    if (Color.r > 0 && Color.g == 0 && Color.b == 0) {
        vertexColor.rgb = getColor(int(Color.r*255));
        switch (int(Color.r*255)) {
            case yaw:
                NORMALIZE(vec2(0, -1), vec2(0));
                OFFSET(vec2(0, 1), vec2(7, 38), transformedPixel);
                break;

            //MATERIAL THING: change the anchor to 1,-1 to keep it still, or keep it where it is? (i sort of like how it changes positions
            //on a bigger screen)
            case mat_wood:
                NORMALIZE(vec2(-1, 0), vec2(1015, 119));
                //the .5 makes it a not-skewed shape for some reason
                OFFSET(vec2(1, 0), vec2(-251, -81.5), transformedPixel);
                break;

            case mat_brick:
                NORMALIZE(vec2(-1, 0), vec2(1015, 101));
                OFFSET(vec2(1, 0), vec2(-171, -81.5), transformedPixel);
                break;

            case mat_metal:
                NORMALIZE(vec2(-1, 0), vec2(1015, 83));
                OFFSET(vec2(1, 0), vec2(-91, -81.5), transformedPixel);
                
                break;

            case time:
                NORMALIZE(vec2(-1, 0), vec2(1028, 4));
                OFFSET(vec2(1, 1), vec2(-300, -324), transformedPixel);
                break;

            case alive:
                NORMALIZE(vec2(-1, 0), vec2(1028, 4));
                OFFSET(vec2(1, 1), vec2(-194, -306), transformedPixel);
                break;

            case kills:
                NORMALIZE(vec2(-1, 0), vec2(1028, 4));
                OFFSET(vec2(1, 1), vec2(-88, -288), transformedPixel);
                break;

            case player_1:
                NORMALIZE(vec2(-1, 0), vec2(1030, -40));
                OFFSET(vec2(-1, 1), vec2(26, -60), transformedPixel);
                break;

            case ammo:
                NORMALIZE(vec2(-1, 0), vec2(1031, 145));
                OFFSET(vec2(0, -1), vec2(-91, 205), transformedPixel);
                break;

            case shield: case shield_max:
                NORMALIZE(vec2(-1, 0), vec2(1031, 142));
                OFFSET(vec2(0, -1), vec2(-240, 131.5), transformedPixel);
                break;

            case health: case health_max:
                NORMALIZE(vec2(-1, 0), vec2(1031, 124));
                OFFSET(vec2(0, -1), vec2(-240, 103.5), transformedPixel);
                break;

            case inv:
                NORMALIZE(vec2(-1, 0), vec2(1030, 78));
                OFFSET(vec2(1, -1), vec2(-619, 153), transformedPixel);
                break;

            case build:
                NORMALIZE(vec2(-1, 0), vec2(1030, 95));
                OFFSET(vec2(1, -1), vec2(-517, 270), transformedPixel);
                break;

            case load:
                NORMALIZE(vec2(0, 1), vec2(32, 168));
                OFFSET(vec2(0, -1), vec2(-32, 235), transformedPixel);
                break;

            case build_keys:
                NORMALIZE(vec2(-1, 0), vec2(1108, 92));
                OFFSET(vec2(1, -1), vec2(-488, 314), transformedPixel);
                break;

            case build_toggle:
                NORMALIZE(vec2(-1, 0), vec2(1030, 92));
                OFFSET(vec2(1, -1), vec2(-558, 244), transformedPixel);
                break;

            case inv_keys:
                NORMALIZE(vec2(-1, 0), vec2(1122, 74));
                OFFSET(vec2(1, -1), vec2(-589, 57), transformedPixel);
                break;

            case inv_toggle:
                NORMALIZE(vec2(-1, 0), vec2(1030, 74));
                OFFSET(vec2(1, -1), vec2(-659, 123), transformedPixel);
                break;
            
            case build_text: case build_brackets: case build_left: case build_right: case build_drop:
                NORMALIZE(vec2(0, 1), vec2(154, 144));
                OFFSET(vec2(0, -1), vec2(-154, 194), transformedPixel);
                break;

            case full_map:
                //just do 0,0 for everything?
                gl_Position = ProjMat * ModelViewMat * vec4(vec3(0, 0, 1.0), 1.0);
                gl_Position.xy += guiPixel.xy * corners[gl_VertexID % 4] * 64;
                //NORMALIZE(vec2(0, 0), vec2(344, 454));
                OFFSET(vec2(0, 0), vec2(344, -300), transformedPixel);
                break;

            case victory:
                //just do 0,0 for everything?
                gl_Position = ProjMat * ModelViewMat * vec4(vec3(0, 0, 1.0), 1.0);
                gl_Position.xy += guiPixel.xy * corners[gl_VertexID % 4] * 512;
                NORMALIZE(vec2(1, -1), vec2(0,-290));
                //NORMALIZE(vec2(1, -1), vec2(505, 98));
                //OFFSET(vec2(0, 0), vec2(-505, 256), transformedPixel);
                break;

            default:
                vertexColor = vec4(vec3(0), 1.0);
                break;
        }
    }

    // [ MAP ]
    type = -1;
    bool map = texture(Sampler0, vec2(0, 0)).a == 254./255.;
    bool marker = texture(Sampler0, texCoord0) * 255 == vec4(173, 152, 193, 102);
    if (map || marker) {
        gl_Position = ProjMat * ModelViewMat * vec4(vec3(0, 0, 0), 1.0);
        gl_Position.x *= -1;

        gl_Position.x += -realPixel.x * (margin + mapSize);
        gl_Position.y += realPixel.y * (margin + mapSize);

        if (map) {
            gl_Position.xy += realPixel.xy * corners[gl_VertexID % 4] * mapSize;

            type = MAP_TYPE;
        } else if (marker) {
            //full map marker
            //this will only ever break if the player is in the bottom left corner (it'll disappear)
            //since it's 0,0
            float rot = Color.r;
            if (Color.g*255.0 > 0 || Color.b*255 > 0){
                //full map marker
                gl_Position = ProjMat * ModelViewMat * vec4(vec3(0, 0, 1.0), 1.0);

                gl_Position.x += gl_Position.w;
                gl_Position.y -= gl_Position.w;

                //gl_Position.xy += realPixel * corners[gl_VertexID % 4] * 40;
                gl_Position.z -= 0.2; // draw in front of map
                
                //extract data
                ivec3 color = ivec3(ogColor.rgb * 255);
                float x = color.g + color.r % 128 / 64 * 256;
                float y = color.b + color.r / 128 * 256;
                gl_Position.xy += realPixel.xy * (vec2(x / 512., y / 512.) - 0.5) * FULL_MAP_SIZE;
                rot = color.r % 64 / 64.;

                vertexColor = vec4(1);
                if (Position.z == 0) {
                    type = DELETE_TYPE;
                    return;
                }
            }
            vec2 center = gl_Position.xy;
            gl_Position.xy += realPixel.xy * corners[gl_VertexID % 4] * 16;
            gl_Position.xy = rotate(gl_Position.xy / realPixel.xy, center / realPixel.xy, rot*PI*2) * realPixel.xy;

            gl_Position.z -= 0.1; // draw in front of circle

            type = MARKER_TYPE;
        }
    // [ COMPASS ]
    } else if (texture(Sampler0, vec2(0, 0)) * 255 == vec4(9, 185, 21, 102)) {
        gl_Position = ProjMat * ModelViewMat * vec4(0, 0, 0, 1.0);
        gl_Position.x += gl_Position.w;
        gl_Position.y += realPixel.y * 120;
        gl_Position.xy += realPixel * corners[gl_VertexID % 4] * ivec2(COMPASS_WIDTH * 0.5, 12) * 6;


        type = COMPASS_TYPE;
        offset = (Color.r * 255 + mod(Color.b * 255, 4) * 256) / 1024.;
        oldOffset = (Color.g * 255 + (int(Color.b * 255) % 16)/ 4 * 256) / 1024.;
        serverTime = int(Color.b * 255) % 64 / 16;
    // [ PREVIEW CIRCLE ]
    } else if (ivec4(texture(Sampler0, texCoord0) * 255) == ivec4(157, 146, 163, 102) || ivec4(texture(Sampler0, texCoord0) * 255) == ivec4(157, 146, 163, 100)) {
        xOffset = gl_Position.x / guiPixel.x;

        gl_Position = ProjMat * ModelViewMat * vec4(vec3(0, 0, 0), 1.0);
        gl_Position.x *= -1;

        gl_Position.x += -realPixel.x * (margin + mapSize);
        gl_Position.y += realPixel.y * (margin + mapSize);
        gl_Position.xy += realPixel.xy * corners[gl_VertexID % 4] * mapSize;
        pos = corners[gl_VertexID % 4];

        // read data
        ivec3 c = ivec3(ogColor.rgb * 255.);
        relX = c.r + (c.b % 16) * 256 - 2048;
        relY = c.g + (c.b / 16) * 256 - 2048;
        i1 = int(round(xOffset))/2; // storm id or storm size if purple circle

        type = ivec4(texture(Sampler0, texCoord0) * 255) == ivec4(157, 146, 163, 102) ? CIRCLE_TYPE : PURPLE_CIRCLE_TYPE;
        if (type == CIRCLE_TYPE) gl_Position.z -= 0.2; // draw above purole circle

    // [ FULL CIRCLE ]
    } else if (ivec4(texture(Sampler0, texCoord0) * 255) == ivec4(109, 78, 129, 105) || ivec4(texture(Sampler0, texCoord0) * 255) == ivec4(109, 78, 129, 106)) {
        xOffset = gl_Position.x / guiPixel.x;
        gl_Position = ProjMat * ModelViewMat * vec4(vec3(0, 0, 1.0), 1.0);

        gl_Position.x += gl_Position.w;
        gl_Position.y -= gl_Position.w;

        gl_Position.xy += realPixel * corners[gl_VertexID % 4] * FULL_MAP_SIZE * 0.5;
        gl_Position.z -= 0.1; // draw in front of map

        pos = corners[gl_VertexID % 4];

        // read data
        ivec3 c = ivec3(ogColor.rgb * 255.);
        relX = (c.r + (c.b & 3) * 256) * 2 -1024;         //   3 = 0b 0000 0011
        relY = (c.g + ((c.b & 12) >> 2) * 256) * 2 -1024;  //  12 = 0b 0000 1100
        if (ivec4(texture(Sampler0, texCoord0) * 255) == ivec4(109, 78, 129, 105)) {
            type = FULL_CIRCLE_TYPE;
            stormId = (c.b & 240) >> 4;                     // 240 = 0b 1111 0000
        } else {
            type = FULL_PURPLE_CIRCLE_TYPE;
            //stormId = (c.b & 240) >> 4;                     // 240 = 0b 1111 0000
            i1 = ((c.b & 240) >> 4) + ((int(round(xOffset))/2) << 4);                     // 240 = 0b 1111 0000
        }

    // [ HEALTH BAR ]
    } else if (ivec4(texture(Sampler0, texCoord0) * 255) == ivec4(163, 93, 35, 58)) {
        //2 = health
        //1 = shield

        //make switch case?
        float h_type = Color.g*255;

        //big health bar
        if (h_type == 0.){
            if (Color.b*255. == 2.){
                NORMALIZE(vec2(-1, 0), vec2(1010, 126));
                OFFSET(vec2(0, -1), vec2(-219, 106), transformedPixel);
            } else{
                NORMALIZE(vec2(-1, 0), vec2(1010, 143));
                OFFSET(vec2(0, -1), vec2(-219, 133), transformedPixel);
            }
        //small corner health bar
        //0 = big health
        //1 = small health
        //2 = health display
        } else if (h_type == 1.){
            NORMALIZE(vec2(-1, 0), vec2(1030, -59));
            OFFSET(vec2(-1, 1), vec2(26, -79), transformedPixel);
        } /*else{
            NORMALIZE(vec2(-1, 0), vec2(1030, -59));
            OFFSET(vec2(-1, 1), vec2(26, -79), realPixel);
        }*/

        pos = (corners[gl_VertexID % 4] / 2.) + 0.5;
        type = HEALTH_TYPE;

    // [ FULL MAP ]
    } else if (vec2(Color.rg*255) == ivec2(1,1) && int(Color.b*255) <= int(64)) {
        gl_Position = ProjMat * ModelViewMat * vec4(vec3(0, 0, 1.0), 1.0);

        const float tileSize = FULL_MAP_SIZE / 8.;

        ivec2 corner = clamp(corners[gl_VertexID % 4], 0, 1); // turn [-1 to 1] into [0 to 1]
        gl_Position.xy += realPixel.xy * corner * tileSize;

        //centered
        gl_Position.x += gl_Position.w;
        gl_Position.y -= gl_Position.w;

        int tile_number = int((Color.b*255)-1);

        //extract tile position
        int tile_x = (tile_number % 8) - 4;
        int tile_y = (tile_number / 8) - 4;

        gl_Position.xy += realPixel * vec2(tile_x, tile_y) * tileSize;

        //return original color
        vertexColor = vec4(1);
    }

    // [ CHEST LOAD BAR ]
    if (ivec4(texture(Sampler0, texCoord0) * 255) == ivec4(137, 97, 160, 82)) {
        pos = corners[gl_VertexID % 4];
        type = CHEST_LOAD_TYPE;
    }

    if (type > -1 && Position.z == 0) {
        type = DELETE_TYPE;
    }
}
