shader_type canvas_item;

uniform vec4 glow_color = vec4(0.48,0.78,1.0,0.9);
uniform float intensity = 0.9;
uniform float round_radius = 0.12;
uniform float falloff = 0.18;

float sdRoundBox(vec2 p, vec2 b, float r) {
    vec2 d = abs(p) - b + vec2(r);
    return min(max(d.x,d.y),0.0) + length(max(d,0.0)) - r;
}

void fragment() {
    // UV ranges 0..1 inside rect
    vec2 uv = UV - vec2(0.5);
    // half-size of rect scaled by NODE scale; using 0.5 center
    vec2 half = vec2(0.5);
    float sd = sdRoundBox(uv, half - vec2(round_radius), round_radius);
    // compute glow mask: inside negative sd -> fill, outside positive -> falloff
    float glow = smoothstep(falloff, 0.0, -sd);
    // soften edge
    glow = pow(glow, 1.0);
    vec4 overlay = glow_color * (glow * intensity);
    // preserve underlying texture (text/icons) and add glow on top
    vec4 base = texture(TEXTURE, UV);
    vec3 out_rgb = base.rgb + overlay.rgb * overlay.a;
    float out_a = base.a;
    COLOR = vec4(clamp(out_rgb, 0.0, 1.0), out_a);
}
