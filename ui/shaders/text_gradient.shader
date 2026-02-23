shader_type canvas_item;

uniform vec4 top_color : hint_color = vec4(0.98,0.85,1.0,1.0);
uniform vec4 mid_color : hint_color = vec4(0.68,0.52,1.0,1.0);
uniform vec4 bottom_color : hint_color = vec4(0.35,0.2,0.8,1.0);
uniform float time : hint_range(0.0,100.0) = 0.0;
uniform float noise_strength : hint_range(0.0,0.5) = 0.04;
uniform float glow_strength : hint_range(0.0,2.0) = 0.6;
uniform vec4 outline_color : hint_color = vec4(0.02,0.01,0.04,1.0);
uniform float outline_thickness : hint_range(0.0,0.08) = 0.008;
uniform float outline_strength : hint_range(0.0,2.0) = 1.2;
uniform float bloom_strength : hint_range(0.0,2.0) = 0.9;

// cheap hash / noise
float hash(vec2 p){ return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453123);} 
float noise(vec2 p){ vec2 i=floor(p); vec2 f=fract(p); float a=hash(i); float b=hash(i+vec2(1.0,0.0)); float c=hash(i+vec2(0.0,1.0)); float d=hash(i+vec2(1.0,1.0)); vec2 u=f*f*(3.0-2.0*f); return mix(a,b,u.x)+(c-a)*u.y*(1.0-u.x)+(d-b)*u.x*u.y; }

// multi-sample alpha for outline / soft stroke
float alpha_max_around(vec2 uv, float radius){
    float acc = 0.0;
    // 8 sample directions
    acc = max(acc, texture(TEXTURE, uv + vec2( radius, 0.0)).a);
    acc = max(acc, texture(TEXTURE, uv + vec2(-radius, 0.0)).a);
    acc = max(acc, texture(TEXTURE, uv + vec2(0.0, radius)).a);
    acc = max(acc, texture(TEXTURE, uv + vec2(0.0,-radius)).a);
    acc = max(acc, texture(TEXTURE, uv + vec2( radius, radius)).a);
    acc = max(acc, texture(TEXTURE, uv + vec2(-radius, radius)).a);
    acc = max(acc, texture(TEXTURE, uv + vec2( radius,-radius)).a);
    acc = max(acc, texture(TEXTURE, uv + vec2(-radius,-radius)).a);
    return acc;
}

void fragment(){
    vec2 uv = UV;
    float g = uv.y;
    // richer gradient mix
    vec3 grad = mix(mix(top_color.rgb, mid_color.rgb, smoothstep(0.0,0.5,g)), mix(mid_color.rgb, bottom_color.rgb, smoothstep(0.5,1.0,g)), smoothstep(0.0,1.0,g));

    // animated micro-noise for texture
    float nval = noise(uv * 90.0 + vec2(time*0.18, time*0.11));
    grad += (nval - 0.5) * noise_strength;

    // slight horizontal wave for vibrancy
    float wave = sin((uv.x + time*0.12) * 6.28318) * 0.015;
    grad = grad + wave;

    // sample glyph alpha
    vec4 tex = texture(TEXTURE, uv);
    float a = tex.a;

    // outline mask (two radii for fuller stroke)
    float m1 = alpha_max_around(uv, outline_thickness);
    float m2 = alpha_max_around(uv, outline_thickness * 2.0);
    float outline_mask = clamp((max(m1, m2) - a) * outline_strength, 0.0, 1.0);

    // rim and soft glow based on alpha
    float rim = smoothstep(0.02, 0.6, a) * 0.08;

    // bloom: sample a few nearby texels and accumulate bright contribution
    float bloom = 0.0;
    bloom += texture(TEXTURE, uv + vec2(0.0, 0.002)).a;
    bloom += texture(TEXTURE, uv + vec2(0.002, 0.0)).a;
    bloom += texture(TEXTURE, uv + vec2(-0.002, 0.0)).a;
    bloom += texture(TEXTURE, uv + vec2(0.0, -0.002)).a;
    bloom = (bloom * 0.25) * bloom_strength * a;

    // final color composition
    vec3 col = grad * a;
    // outline adds contrast behind glyph
    col = mix(col, outline_color.rgb * outline_mask, outline_mask);
    // rim highlight and bloom
    col += vec3(1.0) * rim * 0.45;
    col += grad * bloom * 0.7 * glow_strength;

    // ensure alpha follows glyph but boosted slightly for glow visibility
    float out_a = clamp(a + bloom * 0.3, 0.0, 1.0);
    COLOR = vec4(col, out_a);
}
