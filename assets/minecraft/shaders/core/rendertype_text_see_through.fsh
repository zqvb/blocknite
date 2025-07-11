#version 150

#moj_import <map.glsl>

uniform sampler2D Sampler0;

uniform vec4 ColorModulator;

in vec4 vertexColor;
in vec2 texCoord0;

in vec2 pos;

flat in int type;
flat in vec4 ogColor;

out vec4 fragColor;


void main() {
    //vanilla
    vec4 color = texture(Sampler0, texCoord0) * vertexColor;
    if ((color.a < 0.1 && type == -1) || type == DELETE_TYPE) {
        discard;
    }
    fragColor = color * ColorModulator;
    //

    // [ HEALTH BAR DISPLAY ]
    if (type == HEALTH_TYPE) {

        //returns 0 to 1
        float health = ogColor.r;
        vec4 barColor;

        barColor = vec4(90/255.,196/255.,55/255.,1);

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

    }

}
