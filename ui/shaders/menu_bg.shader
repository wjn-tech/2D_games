shader_type canvas_item;

uniform vec4 day_color : hint_color = vec4(0.53, 0.80, 0.95, 1.0); // bright daytime sky blue
uniform vec4 grad_top : hint_color = vec4(0.53, 0.80, 0.95, 1.0);
uniform vec4 grad_bottom : hint_color = vec4(0.38, 0.60, 0.90, 1.0);
uniform vec4 night_color : hint_color = vec4(0.12, 0.12, 0.14, 1.0);
uniform float time_factor : hint_range(0.0, 1.0) = 0.0;
uniform float global_time = 0.0;
uniform float ring_speed : hint_range(0.0, 1.0) = 0.16;
uniform float ring_thickness : hint_range(0.0, 0.05) = 0.010;
uniform int ring_count : hint_range(0, 16) = 6;
uniform float ring_intensity : hint_range(0.0, 4.0) = 1.8;
uniform float ring_chroma : hint_range(0.0, 1.0) = 0.14;
uniform float star_density : hint_range(0.0, 2.0) = 0.9;
uniform float star_size : hint_range(0.0, 0.02) = 0.004;
uniform float star_bloom : hint_range(0.0, 4.0) = 1.6;
uniform float nebula_strength : hint_range(0.0, 3.0) = 1.0;
uniform bool use_noise : hint_hint = true;
uniform vec2 sun_pos : hint_range(-1.0, 1.0) = vec2(0.0, -0.2);
uniform float sun_intensity : hint_range(0.0, 4.0) = 1.0;
uniform vec3 sun_color : hint_color = vec3(1.0, 0.95, 0.8);
uniform float sun_pulse : hint_range(0.0, 1.0) = 0.8;

// simple hash for star generation
float hash21(vec2 p) {
    p = fract(p * vec2(123.34, 456.21));
    p += dot(p, p + 45.32);
    return fract(p.x * p.y);
}

// fbm-like noise using hash21 for smooth clouds
float noise(vec2 p) {
    return hash21(p);
}

float fbm(vec2 p) {
    float v = 0.0;
    float a = 0.5;
    for (int i = 0; i < 5; i++) {
        v += a * noise(p);
        p *= 2.0;
        a *= 0.5;
    }
    return v;
}

// soft band/ring shape
float ring_mask(float dist, float radius, float thickness) {
    float a = smoothstep(radius - thickness, radius, dist);
    float b = smoothstep(radius, radius + thickness, dist);
    return max(0.0, a - b);
}

void fragment() {
    vec2 uv = SCREEN_UV - vec2(0.5);
    float aspect = VIEWPORT_SIZE.x / VIEWPORT_SIZE.y;
    uv.x *= aspect;
    float dist = length(uv);

    // vertical gradient background (top -> bottom)
    float grad_t = clamp(uv.y + 0.5, 0.0, 1.0);
    vec3 gradient_col = mix(grad_top.rgb, grad_bottom.rgb, grad_t);
    // blend gradient with day/night mix by time_factor to allow night tinting
    vec3 base = mix(gradient_col, mix(day_color.rgb, night_color.rgb, time_factor), time_factor * 0.6);

    // Stars - multi-scale (base, glow, sharp layers)
    float stars_acc = 0.0;
    float scales[3] = float[3](60.0, 120.0, 260.0);
    float stars_glow_acc = 0.0;
    float stars_sharp_acc = 0.0;
    for (int i = 0; i < 3; i++) {
        vec2 p = uv * scales[i];
        if (use_noise) {
            p += global_time * 0.02 * float(i + 1);
        }
        float h = hash21(p);
        float s = smoothstep(1.0 - star_density, 1.0, h);
        stars_acc += pow(s, 28.0) * (1.0 / float(i + 1));
        stars_glow_acc += pow(s, 12.0) * (1.0 / float(i + 1));
        stars_sharp_acc += pow(s, 64.0) * (1.0 / float(i + 1));
    }
    float stars = clamp(stars_acc, 0.0, 1.0);
    float stars_glow = clamp(stars_glow_acc, 0.0, 1.0);
    float stars_sharp = clamp(stars_sharp_acc, 0.0, 1.0);

    // Layered nebula using multi-scale fbm for thicker volumetric feel
    float n1 = fbm(uv * 2.8 + vec2(global_time * 0.02, -global_time * 0.01));
    float n2 = fbm(uv * 1.2 + vec2(-global_time * 0.01, global_time * 0.007));
    float n3 = fbm(uv * 0.5 + vec2(global_time * 0.005, global_time * 0.002));
    float cloud = clamp(n1 * 0.6 + n2 * 0.3 + n3 * 0.2, 0.0, 1.0);
    float falloff = exp(-dist * 3.2);
    float nebula = cloud * falloff * nebula_strength;
    vec3 nebula_col = vec3(0.62, 0.42, 0.94);

    // Rings (more rings, secondary soft rings, chroma)
    float ring_total = 0.0;
    for (int i = 1; i <= ring_count; i++) {
        float idxf = float(i);
        float r = 0.12 * idxf + 0.04 * (idxf - 1.0);
        float thickness = ring_thickness * (1.0 + idxf * 0.4);
        float ang = atan(uv.y, uv.x);
        float dash = fract((ang + global_time * ring_speed * (0.25 + idxf * 0.12)) * idxf * 0.95);
        float dash_mask = smoothstep(0.0, 0.18, 1.0 - abs(dash - 0.5));
        float ring = ring_mask(dist, r, thickness) * dash_mask;
        // a soft secondary outer glow per ring
        float glow = smoothstep(r + thickness * 0.5, r + thickness * 2.4, dist);
        // a sequence of inner micro-rings for shimmer
        float micro = 0.0;
        for (int m = 1; m <= 2; m++) {
            float rr = r + float(m) * (thickness * 0.45);
            micro += ring_mask(dist, rr, thickness * 0.33) * 0.25;
        }
        ring_total += ring + micro * 0.6 + glow * 0.45 * (0.6 + 0.08 * idxf);
    }
    ring_total = clamp(ring_total, 0.0, 2.0);

    vec3 color = base;
    // layered nebula: add second, larger-scale noise layer for depth
    float nebula2 = exp(-dist * 2.6) * nebula_strength * 0.55;
    vec3 nebula_col2 = vec3(0.42, 0.28, 0.68) * 0.7;
    // reduce nebula contribution during day, preserve at night
    float night_factor = time_factor;
    float day_factor = 1.0 - night_factor;
    color += nebula_col * nebula * (0.25 * day_factor + 0.6 * night_factor);
    color += nebula_col2 * nebula2 * (0.18 * day_factor + 0.45 * night_factor);

    // rings contribute additively with chromatic tint and intensified multiplier (night-only)
    vec3 ring_base_col = vec3(0.95, 0.78, 1.0);
    vec3 ring_shift_col = vec3(1.0, 0.92, 0.9);
    vec3 ring_col_mix = mix(ring_base_col, ring_shift_col, ring_chroma);
    color += ring_col_mix * ring_total * ring_intensity * night_factor;

    // stars: soft bloom layer (night-only)
    vec3 star_glow_col = vec3(1.0, 0.95, 0.9);
    color += star_glow_col * stars_glow * star_bloom * night_factor;
    // stars: sharp bright points (night-only)
    color += vec3(1.0, 1.0, 0.98) * stars_sharp * (2.8 + 0.6 * sin(global_time * 3.1)) * night_factor;

    // small procedural sparkles for extra twinkle (very reduced during day)
    float sparkle = pow(max(0.0, hash21(uv * 420.0 + vec2(global_time * 0.6, 0.0))), 80.0);
    color += vec3(1.0, 0.92, 0.8) * sparkle * 0.9 * night_factor;

    // Sun rendering (daytime)
    // sun_pos is in SCREEN_UV space shifted to center (-0.5..0.5 -> use same uv coords)
    vec2 sun_uv = sun_pos;
    // adjust for aspect ratio
    sun_uv.x *= aspect;
    float sun_dist = length(uv - sun_uv);
    float base_radius = 0.12; // core radius
    float pulse = 1.0 + 0.12 * sin(global_time * 0.9) * sun_pulse;
    float sun_radius = base_radius * pulse;
    float sun_soft = 0.28 * (0.9 + 0.2 * (1.0 - sun_pulse)); // soft glow extent
    float core = smoothstep(sun_radius, sun_radius * 0.35, sun_dist);
    core = 1.0 - core;
    float glow = smoothstep(sun_soft, 0.0, sun_dist);
    glow = clamp(glow, 0.0, 1.0);
    // color contributions
    vec3 sun_col = sun_color;
    // add core and glow modulated by day factor and sun_intensity
    color += sun_col * core * sun_intensity * (1.0 - night_factor) * 1.2;
    color += sun_col * glow * sun_intensity * 0.9 * (1.0 - night_factor);

    // subtle sky brightening near sun (day only)
    float sky_bright = exp(-sun_dist * 3.0) * 0.6 * (1.0 - night_factor);
    color = mix(color, color + vec3(0.12, 0.08, 0.02) * sky_bright, 0.6 * (1.0 - night_factor));

    // vignette
    float vign = smoothstep(0.9, 0.6, dist);
    color = mix(color, color * 0.5, vign * 0.6);

    COLOR = vec4(color, 1.0);
}
