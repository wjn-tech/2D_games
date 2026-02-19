shader_type canvas_item;

uniform vec4 top_color : hint_color = vec4(0.9, 0.8, 1.0, 1.0);
uniform vec4 bottom_color : hint_color = vec4(0.6, 0.4, 1.0, 1.0);
uniform float time = 0.0;
uniform float noise_strength = 0.06;

float hash(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453123);
}

void fragment() {
    vec2 uv = UV;
    // vertical gradient
    float g = uv.y;
    vec3 grad = mix(top_color.rgb, bottom_color.rgb, g);

    // subtle animated noise
    float n = hash(vec2(uv.x * 100.0 + time * 0.2, uv.y * 100.0));
    grad += (n - 0.5) * noise_strength;

    vec4 tex = texture(TEXTURE, UV);
    COLOR = vec4(tex.rgb * grad, tex.a * (top_color.a * mix(1.0, 1.0, g)));
}
