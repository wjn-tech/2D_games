shader_type canvas_item;

uniform vec4 top_color : hint_color = vec4(1.0, 1.0, 1.0, 0.20);
uniform vec4 bottom_color : hint_color = vec4(1.0, 1.0, 1.0, 0.04);
uniform float radius = 0.85;

// narrow moving/highlight band params
uniform float highlight_center : hint_range(0.0, 1.0) = 0.28;
uniform float highlight_width : hint_range(0.0, 0.3) = 0.03;
uniform float highlight_strength : hint_range(0.0, 2.0) = 0.8;

void fragment() {
    vec2 uv = UV;
    // vertical gradient mix
    float v = uv.y;
    vec3 col = mix(top_color.rgb, bottom_color.rgb, v);
    float a = mix(top_color.a, bottom_color.a, v);

    // softer radial falloff centered slightly above center for inner highlight
    vec2 center = vec2(0.5, 0.45);
    float d = length(uv - center);
    float radial = smoothstep(radius * 0.95, radius, d);
    float alpha = a * (1.0 - radial);

    // narrow specular/highlight band (subtle thin rim)
    float band = smoothstep(highlight_center - highlight_width, highlight_center, v) - smoothstep(highlight_center, highlight_center + highlight_width, v);
    alpha += band * highlight_strength * (1.0 - radial);

    // multiply alpha by a smooth vertical weight so top remains brighter
    float vertical_weight = smoothstep(0.0, 0.5, 1.0 - abs(v - 0.35));
    alpha *= mix(0.9, 1.1, vertical_weight);

    // Rounded rectangle mask using signed distance to rounded rect
    // radius is relative [0..0.5]
    vec2 center = vec2(0.5);
    vec2 r = vec2(radius);
    vec2 q = abs(uv - center) - (vec2(0.5) - r);
    float dist = length(max(q, 0.0)) - min(max(q.x, q.y), 0.0);
    float mask = 1.0 - smoothstep(0.0, 0.02, dist);

    COLOR = vec4(col, clamp(alpha * mask, 0.0, 1.0));
}
