#version 150

#moj_import <fog.glsl>
#moj_import <map.glsl>
#moj_import <identifiers.glsl>

#define PI 3.1415926535

uniform sampler2D Sampler0;

uniform vec4 ColorModulator;
uniform float FogStart;
uniform float FogEnd;
uniform vec4 FogColor;
uniform vec2 ScreenSize;
uniform float GameTime;

in float vertexDistance;
in vec4 vertexColor;
in vec2 texCoord0;

in vec2 pos;

flat in float f1;
flat in float f2;
flat in int i1;
flat in int i2;
flat in int i3;

flat in float xOffset;
flat in int type;
flat in vec4 ogColor;

out vec4 fragColor;

//default = 0.5
#define ZOOM 0.5

//slider fade
#define FADE_TO 0.1
#define TICK_OFFSET 0.85 // this should be adjusted where it looks best

//storm 
#define BASE_STORM_COLOR vec4(0.863,0.133,0.902,1)
#define INNER_STORM_COLOR vec4(0.569,0.043,0.831,1)
#define LINE_NUMBERS 96
// number between -1 and 1
#define LINE_WIDTH 0.5

void alphaBlendBehind(vec4 c1) {
    if (fragColor.a == 0) {
        fragColor = c1;
        return;
    }
    vec4 c0 = fragColor;

    //alpha blend
    fragColor.a = (1 - c0.a) * c1.a + c0.a;
    fragColor.rgb = ((1 - c0.a) * c1.rgb * c1.a + c0.rgb * c0.a) / fragColor.a;
}

float getCloser(float a, float b) {
    float diff = b - a;
    if (abs(diff) > 0.5) {
        return a + sign(diff);
    } else {
        return a;
    }
}

bool around(float value, float target, float width, out float d) {
    d = value - target;
    float a = abs(d);
    if (a < width*0.5) {
        return true;
    }
    return false;
}

float aroundAA(float value, float target, float width, float solid_width, out float d) {
    if (around(value, target, width, d)) {
        d = abs(d);
        if (d < solid_width*0.5) {
            return 1;
        } else {
            return (width*0.5 - d) / (width*0.5 - solid_width*0.5);
        }
    }
    return 0;
}

bool drawCircle(vec4 circleColor, float radius, vec2 center, out float d) {
    vec2 zoomedPos = pos * (1-ZOOM);

    // distance from line
    float dist = abs((center.y-0)*pos.x-(center.x-0)*pos.y+center.x*0-center.y*0)/length(vec2(center.y-0, center.x-0));

    //circle
    float distanceFromCircle = distance(center, zoomedPos);
    float alpha = aroundAA(distanceFromCircle, radius, 0.023, 0.018, d);
    fragColor = circleColor;
    fragColor.a = 0;
    fragColor.a += alpha;
    //line 
    if (dist < 0.023 && distanceFromCircle > radius) {
        if (length(center) > distanceFromCircle && length(center) > length(zoomedPos)) {
            float d_;
            float alpha = aroundAA(dist, 0, 0.023*2, 0.018*2, d_);
            fragColor.a += alpha;
        } 
    } 

    //remove at border
    if (any(lessThan(pos/2+0.5, vec2(0.01, 0.01))) || any(greaterThan(pos/2+0.5, vec2(0.99, 0.99)))) {
        discard;
    }
    return fragColor.a == 0;
}

bool drawFullCircle(vec4 circleColor, float radius, vec2 center, out float d) {
    if (around(length(center - pos), radius, 0.01, d)) {
        fragColor = circleColor;
        return false;
    }
    return true;
}

void main() {
    // vanilla 
    vec4 color = texture(Sampler0, texCoord0) * vertexColor * ColorModulator;
    if ((color.a < 0.1 && type == -1) || type == DELETE_TYPE) {
        discard;
    }
    fragColor = linear_fog(color, vertexDistance, FogStart, FogEnd, FogColor);

    // Remove sidebar background and red text (the rest is removed in position_color.fsh)
    if((isScoreboard(fragColor)) && ((ScreenSize.x - gl_FragCoord.x) < 52)) discard;

    //use switch instead?

    // map
    if (type == MAP_TYPE) {

        getInfoFromColor(ogColor);

        if (displayId == 4){
            //show nothing during the pregame island
            fragColor = vec4(1, 1, 1, 0.05);
        } else{

            vec2 c0 = texCoord0 + coords - vec2(0.5, 0.5);

            vec2 mapFrom = vec2(0, 0);
            if (displayId == 1 || displayId == 3) {
                if (coords.y > 0.5) mapFrom.y += 1;
                    else mapFrom.y -= 1;
            }
            if (displayId == 2 || displayId == 3) {
                if (coords.x > 0.5) mapFrom.x += 1;
                    else mapFrom.x -= 1;
            }

            vec2 c1 = mix(c0, coords, ZOOM);
            fragColor = texture(Sampler0, c1);

            // return opacity back to 255
            fragColor.a = 1;

            //white border
            if (any(lessThan(texCoord0, vec2(0.01, 0.01))) || any(greaterThan(texCoord0, vec2(0.99, 0.99)))) {
                if (displayId == 0) fragColor = vec4(1, 1, 1, 0.5);
                    else discard;
    
            //make the edge colors blue, since it's the color of the water
            } else if (any(lessThan(c1, mapFrom)) || any(greaterThan(c1, mapFrom + vec2(1, 1)))) {
                if (displayId == 0) {
                    // water
                    //fragColor = vec4(53/255., 110/255., 185/255., 1);
                    fragColor = vec4(1, 1, 1, 0.05);
                } else 
                    discard;
            }
        }

        //dot
        //if (all(greaterThan(texCoord0, vec2(0.49, 0.49))) && all(lessThan(texCoord0, vec2(0.51, 0.51)))) fragColor = vec4(1, 1, 1, 1);
        
    } else if (type == MARKER_TYPE) {
        fragColor = texture(Sampler0, texCoord0);
        //so background of the character is removed too when displayed in full map
        if (fragColor != vec4(1,1,1,1)) discard;
    } else if (type == COMPASS_TYPE) {
        float tickDelta = fract(GameTime * 24000 - TICK_OFFSET);
        if (serverTime != int(GameTime * 24000 - TICK_OFFSET) % 4) {
            tickDelta = 1;
        }
        if ((serverTime - 1) % 4 == int(GameTime * 24000 - TICK_OFFSET) % 4) {
            tickDelta = 0;
        }

        vec2 sliderOffset = vec2(-(COMPASS_WIDTH * 0.5)/256. + mix(oldOffset, getCloser(offset, oldOffset), tickDelta) + 0.5, 0);
        vec2 newCoord = texCoord0 * vec2(COMPASS_WIDTH/256., 1) + sliderOffset;

        fragColor = texture(Sampler0, newCoord);
        if (fragColor.a < 0.1 || fragColor * 255 == vec4(9, 185, 21, 102))
            discard;

        fragColor.a *= min(texCoord0.x/FADE_TO, 1) - max((texCoord0.x-1+FADE_TO)/FADE_TO, 0);

    } else if (type == CIRCLE_TYPE) {
        vec2 circlePos = vec2(relX, relY) / 128.; // 1 is 128 blocks
        float stormSize = stormSizes[stormId] / 128.;

        float d;
        if (drawCircle(vec4(1, 1, 1, 1), stormSize, circlePos, d)) {
            discard;
        }
    } else if (type == PURPLE_CIRCLE_TYPE) {
        vec2 circlePos = vec2(relX, relY) / 128.; // 1 is 128 blocks
        float stormSize = (i1 / 32.) / 128.;

        float d;
        if (drawCircle(BASE_STORM_COLOR, stormSize, circlePos, d) && d < 0) {
            discard;
        }

        vec4 color = BASE_STORM_COLOR;
        color.a = mix(1, 0, clamp(d*5,0,1));
        alphaBlendBehind(color);
        
        float sins = sin((pos.x + pos.y)*64);
        alphaBlendBehind(mix(BASE_STORM_COLOR, INNER_STORM_COLOR, sins*0.5+0.5) * vec4(1, 1, 1, 0.5));

        if (fragColor.a == 0) discard;
    } else if (type == FULL_CIRCLE_TYPE) {
        vec2 circlePos = vec2(relX, relY) / 1024.; // 1 is 1024 blocks
        float stormSize = stormSizes[stormId] / 1024.;

        float d;
        if (drawFullCircle(vec4(1, 1, 1, 1), stormSize, circlePos, d)) discard;
    } else if (type == FULL_PURPLE_CIRCLE_TYPE) {
        vec2 circlePos = vec2(relX, relY) / 1024.; // 1 is 1024 blocks
        float stormSize = (i1 / 2.) / 1024.;
        //float stormSize = 100 / 1024.;

        float d;
        fragColor = vec4(0);
        if (drawFullCircle(BASE_STORM_COLOR, stormSize, circlePos, d)) {
            if (d < 0) {
                discard;
            }
            float sins = sin((pos.x + pos.y)*LINE_NUMBERS);
            if (sins < LINE_WIDTH && fragColor.a == 0) {
                discard;
            }

            fragColor = mix(BASE_STORM_COLOR, INNER_STORM_COLOR, clamp(d*10,0,1));
        }
    } else if (type == HEALTH_TYPE) {

        //returns 0 to 1
        float health = ogColor.r;
        vec4 barColor;

        //health = 2
        //shield = 1
        //health display = 3

        if (ogColor.b*255. == 1.) {
            //shield color
            barColor = vec4(39/255.,158/255.,214/255.,1);
        } else if (ogColor.b*255. == 2.) {
            //health color
            barColor = vec4(90/255.,196/255.,55/255.,1);
        } else{
            barColor = vec4(90/255.,196/255.,55/255.,1);
        }

        fragColor = texture(Sampler0, texCoord0);

        //remove the corner encoded pixels
        if (fragColor.a == 58/255.) discard;

        //health bar
        //checking fragColor.a, because there's lot of empty space in the texture
        if (pos.x <= health && fragColor.a != 0) {
            fragColor = barColor;
        }

        //remove the corner encoded pixels
        if (fragColor.a == 58/255.) discard;

    } else if (type == CHEST_LOAD_TYPE){
        //progress
        float progress = ((ogColor.r) * 57)- 1;

        fragColor = vec4(1,1,1,1);

        if (pos.y > -0.98) discard;

        //x goes from -1 to 1
        if (pos.x > progress) discard;

    }
}
