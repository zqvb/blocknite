//color comparison
bool cc(vec4 a, ivec4 b) {
    return ivec4(a * 255.0 + 0.5) == b;
}
