#version 300 es
precision highp float;

// IMAX 70mm grade, pure color science, nothing else: the mpv IMAX_Film_Grade
// grade ported to the compositor. No grain — per-pixel noise on a native-res
// panel fights the pixel grid and reads as lost resolution; the grade is the
// look, not the tooth.

in vec2 v_texcoord;
uniform sampler2D tex;
out vec4 fragColor;

const vec3 shadow_tint    = vec3(0.92, 0.98, 1.04);  // cool cyan/teal shadows
const vec3 highlight_tint = vec3(1.04, 1.01, 0.96);  // warm amber highlights
const float s_mix       = 0.65;   // full S-curve crushes dark UI text; blend it
const float black_floor = 0.005;

void main() {
    vec3 src = texture(tex, clamp(v_texcoord, 0.0, 1.0)).rgb;

    // 1. Film S-curve, blended so text keeps contrast headroom
    vec3 sc = src * src * (3.0 - 2.0 * src);
    src = mix(src, sc, s_mix);
    src = pow(src, vec3(0.95));

    // 2. Kodak split toning: cool shadows, warm highlights
    float luma = dot(src, vec3(0.2126, 0.7152, 0.0722));
    src *= mix(shadow_tint, highlight_tint, smoothstep(0.1, 0.8, luma));

    // 3. Vibrance: boost flat colors hardest, saturated ones barely
    float mx = max(src.r, max(src.g, src.b));
    float mn = min(src.r, min(src.g, src.b));
    float sat = (mx - mn) / (mx + 0.0001);
    src = mix(vec3(luma), src, 1.0 + (1.0 - sat) * 0.25 + 0.08);

    // 4. Subtractive saturation (2383 chemistry): rich colors get denser and
    // darker rather than brighter, so chroma deepens without clipping
    src *= 1.0 - 0.10 * clamp(sat, 0.0, 1.0);

    // 5. Inky black floor
    src = max(src - black_floor, 0.0) / (1.0 - black_floor);

    // 6. Soft highlight shoulder (chemical exhaustion): bright values roll off
    // like film instead of clipping flat against the 8-bit ceiling
    src = src / (1.0 + max(src - 0.85, 0.0) * 0.55);

    fragColor = vec4(clamp(src, 0.0, 1.0), 1.0);
}
