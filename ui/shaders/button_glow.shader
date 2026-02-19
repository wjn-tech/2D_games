shader_type canvas_item;

uniform vec4 glow_color : hint_color = vec4(0.48,0.78,1.0,0.9);
uniform float intensity : hint_range(0.0,2.0) = 0.9;
uniform float round_radius : hint_range(0.0,0.5) = 0.12;
uniform float falloff : hint_range(0.0,0.5) = 0.18;

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
    vec4 col = glow_color * (glow * intensity);
    COLOR = col;
}
