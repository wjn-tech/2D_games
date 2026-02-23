shader_type canvas_item;

uniform float time = 0.0;
uniform vec4 star_color = vec4(1.0,1.0,1.0,1.0);
uniform float star_density = 0.45;
uniform float star_blink = 0.6;
uniform vec4 nebula_color_a = vec4(0.28,0.12,0.35,0.6);
uniform vec4 nebula_color_b = vec4(0.12,0.05,0.45,0.6);

float hash(float n) { return fract(sin(n) * 43758.5453123); }

float noise(vec2 x) {
    vec2 p = floor(x);
    vec2 f = fract(x);
    float a = hash(p.x + p.y*57.0);
    float b = hash(p.x + 1.0 + p.y*57.0);
    float c = hash(p.x + (p.y+1.0)*57.0);
    float d = hash(p.x+1.0 + (p.y+1.0)*57.0);
    vec2 u = f*f*(3.0-2.0*f);
    return mix(a, b, u.x) + (c - a)*u.y*(1.0 - u.x) + (d - b)*u.x*u.y;
}

void fragment() {
    vec2 uv = SCREEN_UV;
    float t = time * 0.2;

    // Nebula layers (two overlapping bands)
    float n1 = noise((uv * vec2(1.5, 0.6) + vec2(t*0.05, -t*0.02)) * 3.0);
    float band1 = smoothstep(0.35, 0.7, n1 + 0.2*uv.y);
    float n2 = noise((uv * vec2(0.8, 1.2) + vec2(-t*0.03, t*0.06)) * 2.2);
    float band2 = smoothstep(0.4, 0.75, n2 + 0.4*(1.0-uv.y));
    vec3 neb = mix(nebula_color_a.rgb, nebula_color_b.rgb, band2);

    // Stars
    float stars = 0.0;
    float density = star_density * 0.8 + 0.2;
    float m = fract(sin(dot(uv * 1234.5, vec2(12.9898,78.233))) * 43758.5453);
    stars = step(1.0 - density, m);
    // soft blink
    float blink = sin((uv.x+uv.y*1.3+time*0.8)*6.2831)*0.5 + 0.5;
    stars *= mix(0.6, 1.0, blink*star_blink);

    vec3 bg = vec3(0.02, 0.01, 0.04);
    vec3 col = bg + neb * (band1*0.9 + band2*0.8) + star_color.rgb * stars;
    float alpha = clamp(band1*0.9 + band2*0.8 + stars*0.7, 0.0, 1.0);

    COLOR = vec4(col, alpha);
}
