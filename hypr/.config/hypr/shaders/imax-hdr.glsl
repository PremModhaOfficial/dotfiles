#version 300 es
precision highp float;

// IMAX 70mm grade, HDR variant: same color science as imax.glsl but authored
// for the linear FP16 work buffer Hyprland hands the shader when the monitor
// runs cm=hdr/hdredid (the final PQ encode happens after this pass, so no PQ
// math lives here). Grade in linear light, conservative strengths: linear
// values are perceptually compressed, so the same constants that look mild in
// gamma land read far heavier here.

in vec2 v_texcoord;
uniform sampler2D tex;
out vec4 fragColor;

const vec3 shadow_tint    = vec3(0.96, 0.99, 1.03);  // milder: linear tints bite
const vec3 highlight_tint = vec3(1.03, 1.01, 0.98);
const float s_mix         = 0.30;   // S-curve blend, gentled for linear input
const float black_floor   = 0.0002; // 0.005 linear would crush real shadow detail

void main() {
    vec3 src = texture(tex, clamp(v_texcoord, 0.0, 1.0)).rgb;

    // 1. Film S-curve on linear light, heavily blended
    vec3 sc = src * src * (3.0 - 2.0 * src);
    src = mix(src, sc, s_mix);

    // 2. Kodak split toning on linear luma
    float luma = dot(src, vec3(0.2126, 0.7152, 0.0722));
    src *= mix(shadow_tint, highlight_tint, smoothstep(0.005, 0.6, luma));

    // 3. Vibrance: boost flat colors hardest, saturated ones barely
    float mx = max(src.r, max(src.g, src.b));
    float mn = min(src.r, min(src.g, src.b));
    float sat = (mx - mn) / (mx + 0.0001);
    src = mix(vec3(luma), src, 1.0 + (1.0 - sat) * 0.15 + 0.04);

    // 4. Subtractive saturation: rich colors densify like print film
    src *= 1.0 - 0.08 * clamp(sat, 0.0, 1.0);

    // 5. Inky black floor (linear-scale)
    src = max(src - black_floor, 0.0) / (1.0 - black_floor);

    // 6. Filmic highlight shoulder: Reinhard tip on linear light
    src = src / (1.0 + max(src - 0.7, 0.0) * 0.6);

    fragColor = vec4(clamp(src, 0.0, 1.0), 1.0);
}
