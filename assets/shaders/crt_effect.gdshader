shader_type canvas_item;

uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;

uniform float aim_alpha : hint_range(0.0, 1.0) = 1.0;
uniform float scanline_alpha : hint_range(0.0, 1.0) = 0.5;
uniform float scanline_size : hint_range(0.0, 10.0) = 2.0;

uniform float flicker_speed : hint_range(0.0, 10.0) = 1.0;
uniform float flicker_intensity : hint_range(0.0, 1.0) = 0.05;

uniform float curvature : hint_range(0.0, 1.0) = 1.0;
uniform float aberration : hint_range(0.0, 1.0) = 0.02;

void fragment() {
    vec2 centered_uv = SCREEN_UV * 2.0 - 1.0;
    vec2 offset = centered_uv.yx / 5.0;
    centered_uv += centered_uv * offset * offset * curvature;
    vec2 deformed_uv = (centered_uv + 1.0) / 2.0;
    
    // Boundary check
    if (deformed_uv.x < 0.0 || deformed_uv.x > 1.0 || deformed_uv.y < 0.0 || deformed_uv.y > 1.0) {
        COLOR = vec4(0.0);
    } else {
        // Sample screen texture with chromatic aberration
        vec4 color;
        color.r = texture(SCREEN_TEXTURE, deformed_uv - vec2(aberration, 0.0)).r;
        color.g = texture(SCREEN_TEXTURE, deformed_uv).g;
        color.b = texture(SCREEN_TEXTURE, deformed_uv + vec2(aberration, 0.0)).b;
        color.a = 1.0;
        
        // Scanlines
        float scanline = sin(deformed_uv.y * 300.0 * scanline_size + TIME * 2.0);
        scanline = (scanline + 1.0) / 2.0;
        scanline = 1.0 + scanline * scanline_alpha;
        
        // Flicker
        float flicker = 1.0 + (sin(TIME * flicker_speed) * flicker_intensity);
        
        COLOR = color * vec4(vec3(scanline * flicker), aim_alpha);
    }
}
