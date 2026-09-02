# MPV Video Filters & Shaders Guide (Linux / Arch)

A guide for video enhancement, upscaling, and custom color grading in MPV on Linux.

---

## 1. Overview & Architecture

MPV uses libplacebo / OpenGL / Vulkan pipelines (`vo=gpu`) with GLSL user shaders and FFmpeg video filters (`vf`) to deliver real-time post-processing:

- **GPU Pipeline**: `vo=gpu` with `profile=gpu-hq` provides `ewa_lanczossharp` luma scaling and debanding.
- **GLSL Shaders**: Custom shader passes running directly on the GPU for neural upscaling, line art restoration, chroma reconstruction, and color grading.
- **Video Filters (VF)**: FFmpeg/libavfilter integration for dynamic image filters (e.g. AMD FidelityFX CAS sharpening).

---

## 2. Keybindings Reference (`~/.config/mpv/input.conf`)

| Keybind | Filter / Shader Target | Description | Best For |
|---|---|---|---|
| **`Ctrl+Y`** | **YouTube / Stream Pack** | `KrigBilateral` (chroma) + `SSimSuperRes` (edge recovery) + `SSimDownscaler` (clean downscale) | Web streams, YouTube, Twitch, 1080p/1440p content |
| **`Ctrl+I`** | **IMAX 70mm Film Grade** | `IMAX_Film_Grade.glsl` (Kodak Vision3 split toning, cubic S-curve contrast, vibrance boost, inky blacks) | Movies, cinematic trailers, live action |
| **`Ctrl+A`** | **Anime4K Pipeline** | 5-pass Anime4K CNN restoration + upscaling chain | 2D Anime, cartoons, animated content |
| **`Ctrl+F`** | **FSRCNNX Neural Upscaler** | `FSRCNNX_x2_16-0-4-1.glsl` 16-filter neural network | Live-action video upscaling (e.g. 720p/1080p to 1440p/4K) |
| **`Ctrl+C`** | **CAS Sharpening** | `vf toggle cas=0.4` (AMD FidelityFX Contrast Adaptive Sharpening) | Universal edge sharpening without haloing |
| **`Shift+I`** | **Stats Overlay** | Built-in MPV stats page (press `2` for active GLSL passes and render timings) | Diagnostics & performance profiling |

---

## 3. Configuration Files

### `mpv.conf` (`~/.config/mpv/mpv.conf`)
```ini
# base quality (vo=gpu for gpu-hq profile's ewa_lanczos options)
vo=gpu
profile=gpu-hq
scale=ewa_lanczossharp
cscale=ewa_lanczossoft
deband=yes

# keep ytdl from picking trash formats
ytdl-format=bv*[height<=?1440][vcodec!=vp9.2]+ba/b
```

### `input.conf` (`~/.config/mpv/input.conf`)
```ini
# Ctrl+Y = toggle YouTube/Stream pack (KrigBilateral chroma + SSimSuperRes + SSimDownscaler)
Ctrl+y cycle-values glsl-shaders "/home/prm/.config/mpv/shaders/KrigBilateral.glsl:/home/prm/.config/mpv/shaders/SSimSuperRes.glsl:/home/prm/.config/mpv/shaders/SSimDownscaler.glsl" "" ; show-text "YouTube/Stream Enhance toggled: ${glsl-shaders}"

# Ctrl+I = toggle IMAX 70mm Film Grade colors
Ctrl+i cycle-values glsl-shaders "/home/prm/.config/mpv/shaders/IMAX_Film_Grade.glsl" "" ; show-text "IMAX Film Grade toggled: ${glsl-shaders}"

# Ctrl+A = toggle Anime4K (anime)
Ctrl+a cycle-values glsl-shaders "/home/prm/.config/mpv/shaders/Anime4K_Clamp_Highlights.glsl:/home/prm/.config/mpv/shaders/Anime4K_Restore_CNN_M.glsl:/home/prm/.config/mpv/shaders/Anime4K_Upscale_CNN_x2_M.glsl:/home/prm/.config/mpv/shaders/Anime4K_AutoDownscalePre_x2.glsl:/home/prm/.config/mpv/shaders/Anime4K_AutoDownscalePre_x4.glsl:/home/prm/.config/mpv/shaders/Anime4K_Upscale_CNN_x2_M.glsl" "" ; show-text "Anime4K toggled: ${glsl-shaders}"

# Ctrl+F = toggle FSRCNNX (live-action)
Ctrl+f cycle-values glsl-shaders "/home/prm/.config/mpv/shaders/FSRCNNX_x2_16-0-4-1.glsl" "" ; show-text "FSRCNNX toggled: ${glsl-shaders}"

# Ctrl+C = toggle CAS sharpening
Ctrl+c vf toggle cas=0.4 ; show-text "CAS Sharpening toggled"
```

---

## 4. Custom IMAX 70mm Film Grade Shader (`IMAX_Film_Grade.glsl`)

```glsl
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
```

---

## 5. Technical Lessons & Root Cause Fixes

1. **Shader List Separator (`:` vs `;`)**:
   - In Linux/POSIX mpv, shader paths inside `glsl-shaders` and `cycle-values` must be delimited by colons (`:`) rather than semicolons (`;`). Semicolons cause mpv to treat the entire string as a single non-existent file.

2. **`vo=gpu` vs `vo=gpu-next` Compatibility**:
   - When using `profile=gpu-hq`, `cscale=ewa_lanczossoft` requires `vo=gpu`. Using `vo=gpu-next` triggers `Failed mapping filter function 'ewa_lanczossoft', no libplacebo analog?`.

3. **Single-Key Toggles vs Sequences**:
   - Multi-key sequences (e.g. `Ctrl+A` then `f`) conflict with single-key default binds (like `f` for fullscreen). Using `cycle-values` with single keypress shortcuts prevents accidental keystroke leaks.
