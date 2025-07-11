#version 150

#moj_import <fog.glsl>

uniform sampler2D Sampler0;

uniform vec4 ColorModulator;
uniform float FogStart;
uniform float FogEnd;
uniform vec4 FogColor;
uniform float GameTime;

in float vertexDistance;
in vec4 vertexColor;
in vec2 texCoord0;
in vec2 texCoord1;
in vec4 normal;

in vec2 pos;
in vec4 worldPos0;
in vec3 worldPos;

in vec4 ogColor;

out vec4 fragColor;

#define PI 3.14159265358979323846

//drawing
float tick(float x, float y) {
    return x - mod(x, y);
}

void main() {
    vec4 texture_color = texture(Sampler0, texCoord0);
    vec4 color = texture_color * vertexColor * ColorModulator;
    if (color.a < 0.1) {
        discard;
    }

    fragColor = linear_fog(color, vertexDistance, FogStart, FogEnd, FogColor);

    if (ivec3(texture_color*255) == ivec3(230, 170, 54)) {
        if (ogColor.rgb == vec3(0, 0, 0)) {
            discard;
        }
        fragColor = ogColor;
        return;
    }

    //storm circle detection
    if (ivec3(texture_color.rgb*255) == ivec3(15,95,185)){
        vec3 anchor = worldPos0.xyz / worldPos0.w;
        float x = distance(anchor.xz, worldPos.xz);
        float y = anchor.y - worldPos.y;
        float d = length(worldPos);
        
        const vec3 borderColor = vec3(15, 95, 185)/255.;
        const vec2 panelSize = vec2(6., 4.);
        const vec2 squareSize = vec2(4./16., 4./16.);
        float Time = -fract(GameTime*(24000/20. / 5.)); // 5 seconds a loop, change the 5 to change seconds per loop
        //float trippyTime = -fract(GameTime*(24000/20. / 14.)); // 14 secs

        {
            //vec2 tileCoords = vec2(fract((x + sin((tick(y, panelSize.y))/3.+trippyTime*PI*2)) / panelSize.x), fract(y / panelSize.y));
            vec2 tileCoords = vec2(fract(x / panelSize.x), fract(y / panelSize.y));
            float tileSizeDiff = (sin((tick(y, panelSize.y))/10.+Time*PI*2)/2+0.5)/4+0.05;
            vec4 color = vec4(borderColor, 0.6);
            if (all(greaterThan(tileCoords, vec2(tileSizeDiff))) && all(lessThan(tileCoords, vec2(1-tileSizeDiff)))) {
                color += vec4(1, 1, 2, 0.5)*0.125*clamp((y+50)/40, 0, 1)*clamp((d-10)/20, 0, 1);
            }
            
            vec2 squareCoords = vec2(fract(x / squareSize.x), fract(y / squareSize.y));
            float squareSizeDiff = (sin((tick(y, squareSize.y))+tick(x, squareSize.x)/squareSize.x*0.4+Time*PI*2)/2+0.5)/4+0.05;
            if (all(greaterThan(squareCoords, vec2(squareSizeDiff))) && all(lessThan(squareCoords, vec2(1-squareSizeDiff)))) {
                color += vec4(0.2, 0.2, 3.5, 3)*0.125*clamp((15-d)/10, 0, 1);
            }

            color.a *= clamp(y/80, 0, 0.7);

            fragColor = linear_fog(color, vertexDistance, FogStart, FogEnd, FogColor);
        }
    }

    

}