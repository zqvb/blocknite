#version 150

#moj_import <map.glsl>

uniform sampler2D Sampler0;

in vec3 Position;
in vec4 Color;
in vec2 UV0;

uniform mat4 ModelViewMat;
uniform mat4 ProjMat;

out vec4 vertexColor;
out vec2 texCoord0;

out vec2 pos;

flat out int type;
flat out vec4 ogColor;

const ivec2[] corners = ivec2[](
    ivec2(-1, -1),
    ivec2(-1, 1),
    ivec2(1, 1),
    ivec2(1, -1)
);

void main() {
    ogColor = Color;
    //vanilla
    gl_Position = ProjMat * ModelViewMat * vec4(Position, 1.0);

    vertexColor = Color;
    texCoord0 = UV0;
    //

    type = -1;
    // [ HEALTH BAR DISPLAY ]
    if (ivec4(texture(Sampler0, texCoord0) * 255) == ivec4(163, 93, 35, 58)) {

        pos = (corners[gl_VertexID % 4] / 2.) + 0.5;
        type = HEALTH_TYPE;

    }

    if (type > -1 && Position.z == 0) {
        type = DELETE_TYPE;
    }
}
