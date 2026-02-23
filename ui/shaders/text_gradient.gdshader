shader_type canvas_item;

// Ensure built-in TEXTURE sampler is declared for some runtimes/editors

uniform vec4 top_color = vec4(0.98,0.85,1.0,1.0);
uniform vec4 mid_color = vec4(0.68,0.52,1.0,1.0);
uniform vec4 bottom_color = vec4(0.35,0.2,0.8,1.0);
uniform float time = 0.0;
uniform float noise_strength = 0.035;
uniform float glow_strength = 1.2;
uniform vec4 outline_color = vec4(0.04,0.02,0.06,1.0);
uniform float outline_thickness = 0.02;
uniform float outline_strength = 2.0;
uniform float bloom_strength = 1.2;

// optional external glyph mask sampler (used when rendering from a SubViewport or TextureRect)
uniform sampler2D mask_tex;

// cheap hash / noise
float hash(vec2 p){ return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453123);}
float noise(vec2 p){ vec2 i=floor(p); vec2 f=fract(p); float a=hash(i); float b=hash(i+vec2(1.0,0.0)); float c=hash(i+vec2(0.0,1.0)); float d=hash(i+vec2(1.0,1.0)); vec2 u=f*f*(3.0-2.0*f); return mix(a,b,u.x)+(c-a)*u.y*(1.0-u.x)+(d-b)*u.x*u.y; }

// multi-sample alpha for outline / soft stroke
float alpha_max_around(vec2 uv, float radius){
    float acc = 0.0;
    float a = 0.0;
    a = max(texture(mask_tex, uv + vec2( radius, 0.0)).a, texture(TEXTURE, uv + vec2( radius, 0.0)).a); acc = max(acc, a);
    a = max(texture(mask_tex, uv + vec2(-radius, 0.0)).a, texture(TEXTURE, uv + vec2(-radius, 0.0)).a); acc = max(acc, a);
    a = max(texture(mask_tex, uv + vec2(0.0, radius)).a, texture(TEXTURE, uv + vec2(0.0, radius)).a); acc = max(acc, a);
    a = max(texture(mask_tex, uv + vec2(0.0,-radius)).a, texture(TEXTURE, uv + vec2(0.0,-radius)).a); acc = max(acc, a);
    a = max(texture(mask_tex, uv + vec2( radius, radius)).a, texture(TEXTURE, uv + vec2( radius, radius)).a); acc = max(acc, a);
    a = max(texture(mask_tex, uv + vec2(-radius, radius)).a, texture(TEXTURE, uv + vec2(-radius, radius)).a); acc = max(acc, a);
    a = max(texture(mask_tex, uv + vec2( radius,-radius)).a, texture(TEXTURE, uv + vec2( radius,-radius)).a); acc = max(acc, a);
    a = max(texture(mask_tex, uv + vec2(-radius,-radius)).a, texture(TEXTURE, uv + vec2(-radius,-radius)).a); acc = max(acc, a);
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

    // sample glyph alpha preferring `mask_tex`, but fall back to the control's TEXTURE
    float a_mask = texture(mask_tex, uv).a;
    float a_tex = texture(TEXTURE, uv).a;
    float a = max(a_mask, a_tex);

    // outline mask (two radii for fuller stroke)
    float m1 = alpha_max_around(uv, outline_thickness);
    float m2 = alpha_max_around(uv, outline_thickness * 2.0);
    float outline_mask = clamp((max(m1, m2) - a) * outline_strength, 0.0, 1.0);

    // rim and soft glow based on alpha
    float rim = smoothstep(0.02, 0.6, a) * 0.14;

    // bloom: sample a few nearby texels and accumulate bright contribution
    float bloom = 0.0;
    bloom += max(texture(mask_tex, uv + vec2(0.0, 0.002)).a, texture(TEXTURE, uv + vec2(0.0, 0.002)).a);
    bloom += max(texture(mask_tex, uv + vec2(0.002, 0.0)).a, texture(TEXTURE, uv + vec2(0.002, 0.0)).a);
    bloom += max(texture(mask_tex, uv + vec2(-0.002, 0.0)).a, texture(TEXTURE, uv + vec2(-0.002, 0.0)).a);
    bloom += max(texture(mask_tex, uv + vec2(0.0, -0.002)).a, texture(TEXTURE, uv + vec2(0.0, -0.002)).a);
    bloom = (bloom * 0.25) * bloom_strength * a;

    // final color composition
    vec3 col = grad * a;
    // outline adds stronger contrast behind glyph
    col = mix(col, outline_color.rgb * outline_mask, outline_mask * 0.9);
    // rim highlight and bloom (stronger for more polish)
    col += vec3(1.0) * rim * 0.6;
    col += grad * bloom * 0.9 * glow_strength;

    // ensure alpha follows glyph but boosted slightly for glow visibility
    float out_a = clamp(a + bloom * 0.3, 0.0, 1.0);
    COLOR = vec4(col, out_a);
}
