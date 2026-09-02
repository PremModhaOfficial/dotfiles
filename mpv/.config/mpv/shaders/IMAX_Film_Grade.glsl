//!HOOK MAIN
//!BIND HOOKED
//!DESC IMAX 70mm Cinematic Film Grade

vec4 hook() {
    vec4 color = HOOKED_texOff(0);
    vec3 rgb = color.rgb;

    // 1. Film S-Curve Contrast (Deep IMAX blacks + punchy rolloff highlights)
    rgb = clamp(rgb, 0.0, 1.0);
    rgb = rgb * rgb * (3.0 - 2.0 * rgb); // Smooth cubic S-curve
    rgb = pow(rgb, vec3(0.95));          // Lift shadow detail slightly

    // 2. Kodak 70mm / IMAX Split Toning (Cool shadows, warm/golden highlights)
    float luma = dot(rgb, vec3(0.2126, 0.7152, 0.0722));
    
    // Shadow tint: deep rich cyan/teal
    vec3 shadow_tint = vec3(0.92, 0.98, 1.04);
    // Highlight tint: rich warm amber/gold
    vec3 highlight_tint = vec3(1.04, 1.01, 0.96);
    
    vec3 grade = mix(shadow_tint, highlight_tint, smoothstep(0.1, 0.8, luma));
    rgb *= grade;

    // 3. Film Vibrance & Rich Chroma
    float max_c = max(rgb.r, max(rgb.g, rgb.b));
    float min_c = min(rgb.r, min(rgb.g, rgb.b));
    float sat = (max_c - min_c) / (max_c + 0.0001);
    
    // Boost lower saturated colors more than already saturated ones (vibrance)
    float boost = (1.0 - sat) * 0.25 + 0.08;
    rgb = mix(vec3(luma), rgb, 1.0 + boost);

    // 4. Inky black floor clamp
    rgb = max(rgb - 0.005, 0.0) / 0.995;

    return vec4(clamp(rgb, 0.0, 1.0), color.a);
}
