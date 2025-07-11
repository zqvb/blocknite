#version 150

#moj_import <light.glsl>
#moj_import <fog.glsl>

in vec3 Position;
in vec4 Color;
in vec2 UV0;
in vec2 UV1;
in ivec2 UV2;
in vec3 Normal;

uniform sampler2D Sampler2;

uniform mat4 ModelViewMat;
uniform mat4 ProjMat;
uniform mat3 IViewRotMat;
uniform int FogShape;

uniform vec3 Light0_Direction;
uniform vec3 Light1_Direction;

out float vertexDistance;
out vec4 vertexColor;
out vec2 texCoord0;
out vec2 texCoord1;
out vec2 texCoord2;
out vec4 normal;

out vec2 pos;
out vec4 worldPos0;
out vec3 worldPos;

out vec4 ogColor;

const ivec2[] corners = ivec2[](
    ivec2(0, 0),
    ivec2(0, 1),
    ivec2(1, 1),
    ivec2(1, 0)
);

void main() {
    ogColor = Color;

    gl_Position = ProjMat * ModelViewMat * vec4(Position, 1.0);

    vec2 ScrSize = ceil(2 / vec2(ProjMat[0][0], -ProjMat[1][1]));
    vec2 Pos = ModelViewMat[3].xy;

    pos = corners[gl_VertexID % 4];
    worldPos0 = vec4(0.0);
    if (gl_VertexID % 4 == 0) {
        worldPos0 = vec4(IViewRotMat * Position, 1.0);
    }
    worldPos = IViewRotMat * Position;

    if (Position.z > 100 && Position.z < 200 && Pos.y <= 0)
    {
        //dont show item
        vertexColor = vec4(0);
    } else
    {
        vertexColor = minecraft_mix_light(Light0_Direction, Light1_Direction, Normal, Color) * texelFetch(Sampler2, UV2 / 16, 0);

    }

    vertexDistance = fog_distance(ModelViewMat, IViewRotMat * Position, FogShape);
    texCoord0 = UV0;
    texCoord1 = UV1;
    texCoord2 = UV2;
    normal = ProjMat * ModelViewMat * vec4(Normal, 0.0);
}