#version 150

vec4 linear_fog(vec4 inColor, float vertexDistance, float fogStart, float fogEnd, vec4 fogColor) {
    float fogValue = vertexDistance < fogEnd ? smoothstep(fogStart, fogEnd, vertexDistance) : 1.0;

    // [ BLINDNESS CHECK ]
    if (fogColor.rgb == vec3(0)){
        //multiplying vertexdistance by 2 to only ignore the HUD and item tints, but keep everything else tinted
        //(when you get close to a block, it would normally remove the tint)
        //only problem is that it makes the hand not tinted, so it looks a little out of place
        if (vertexDistance*2 <= fogStart) {
            return inColor;
        }
        vec4 newFogColor = vec4(186/255.,82/255.,245/255.,0.25);
        //layer the ground color with a tint of purple too
        vec3 tintedColor = vec3(inColor.r + (newFogColor.r - inColor.r) * 0.25,inColor.g + (newFogColor.g - inColor.g) * 0.25, inColor.b + (newFogColor.b - inColor.b) * 0.25);
        return vec4(mix(tintedColor.rgb, newFogColor.rgb, fogValue * newFogColor.a), inColor.a);
    } else{
        if (vertexDistance <= fogStart) {
            return inColor;
        }

        return vec4(mix(inColor.rgb, fogColor.rgb, fogValue * fogColor.a), inColor.a);
    }
}

float linear_fog_fade(float vertexDistance, float fogStart, float fogEnd) {
    if (vertexDistance <= fogStart) {
        return 1.0;
    } else if (vertexDistance >= fogEnd) {
        return 0.0;
    }

    return smoothstep(fogEnd, fogStart, vertexDistance);
}

float fog_distance(mat4 modelViewMat, vec3 pos, int shape) {
    if (shape == 0) {
        return length((modelViewMat * vec4(pos, 1.0)).xyz);
    } else {
        float distXZ = length((modelViewMat * vec4(pos.x, 0.0, pos.z, 1.0)).xyz);
        float distY = length((modelViewMat * vec4(0.0, pos.y, 0.0, 1.0)).xyz);
        return max(distXZ, distY);
    }
}
