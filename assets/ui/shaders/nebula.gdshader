shader_type canvas_item;

uniform vec4 nebula_color : source_color = vec4(0.5, 0.0, 0.5, 0.2);
uniform float speed = 0.02;

// Simple pseudo-random noise
float random(vec2 st) {
    return fract(sin(dot(st.xy, vec2(12.9898,78.233))) * 43758.5453123);
}

// 2D Noise based on Morgan McGuire @morgan3d
// https://www.shadertoy.com/view/4dS3Wd
float noise(vec2 st) {
    vec2 i = floor(st);
    vec2 f = fract(st);

    // Four corners in 2D of a tile
    float a = random(i);
    float b = random(i + vec2(1.0, 0.0));
    float c = random(i + vec2(0.0, 1.0));
    float d = random(i + vec2(1.0, 1.0));

    vec2 u = f*f*(3.0-2.0*f);

    return mix(a, b, u.x) +
            (c - a)* u.y * (1.0 - u.x) +
            (d - b) * u.x * u.y;
}

#define OCTAVES 4
float fbm(vec2 st) {
    float v = 0.0;
    float a = 0.5;
    vec2 shift = vec2(100.0);
    // Rotate to reduce axial bias
    mat2 rot = mat2(vec2(cos(0.5), sin(0.5)), vec2(-sin(0.5), cos(0.50)));
    for (int i = 0; i < OCTAVES; ++i) {
        v += a * noise(st);
        st = rot * st * 2.0 + shift;
        a *= 0.5;
    }
    return v;
}

void fragment() {
    vec2 st = UV * 3.0; // Scale the noise
    float t = TIME * speed;
    
    vec2 q = vec2(0.);
    q.x = fbm( st + 0.00*t);
    q.y = fbm( st + vec2(1.0));

    vec2 r = vec2(0.);
    r.x = fbm( st + 1.0*q + vec2(1.7,9.2)+ 0.15*t );
    r.y = fbm( st + 1.0*q + vec2(8.3,2.8)+ 0.126*t);

    float f = fbm(st+r);

    vec3 color = nebula_color.rgb;
    
    // Mix pattern
    color = mix(color, vec3(0.0, 0.2, 0.4), clamp(length(q),0.0,1.0));
    color = mix(color, vec3(0.1, 0.0, 0.2), clamp(length(r.x),0.0,1.0));

    COLOR = vec4((f*f*f+.6*f*f+.5*f)*color, nebula_color.a * f);
}
