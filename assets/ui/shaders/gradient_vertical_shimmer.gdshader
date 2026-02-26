shader_type canvas_item;

uniform vec4 color_top : source_color = vec4(0.3, 0.6, 1.0, 1.0);
uniform vec4 color_bottom : source_color = vec4(0.8, 0.4, 1.0, 1.0);
uniform float shimmer_speed : hint_range(0.0, 5.0) = 2.0;
uniform float shimmer_size : hint_range(0.0, 1.0) = 0.15;
uniform float shimmer_intensity : hint_range(0.0, 1.0) = 0.5;

uniform vec2 uv_scale = vec2(1.0, 1.0);

// Approximate width of the title for shimmer calculation
uniform float width_pixels = 500.0;
// Approximate height of the text for vertical gradient (font_size + padding)
uniform float height_pixels = 70.0;
// Vertical offset for gradient start
uniform float offset_y = 0.0;

varying vec2 v_position;

void vertex() {
	v_position = VERTEX;
}

void fragment() {
    // 1. Texture Alpha
    // Getting the shape of the text from the font texture
	vec4 text_sample = texture(TEXTURE, UV);
    
    // 2. Vertical Gradient
    // Simple vertical gradient based on local Y coordinate.
    // If you see solid color at runtime, adjust height_pixels or offset_y.
    
    // Fallback logic: If height is suspicious (too small), use a hardcoded reasonable value for 64px font.
    float use_height = height_pixels;
    
    // Debug: If height is 0 (script hasn't run), use 70.0
    if (use_height < 1.0) {
        use_height = 70.0;
    }
    
    // Calculate vertical progress
    // VERTEX.y is local pixel coordinate.
    // Standard unscaled Label: 0 at top, H at bottom.
    // If scaled or pivoted: may be centered.
    // We try to auto-center if values seem negative.
    
    float local_y = v_position.y;
    
    // Auto-detect centered pivot (negative local coords)?
    // Hard to detect per-pixel.
    
    // IMPROVEMENT: Use UV.y as a helper if VERTEX logic fails?
    // No, UV is atlas.
    
    // Try to center the gradient dynamically? No.
    // Instead, allow negative values to map correctly if we are centered.
    // If local_y is negative, adding 0.5 * height shifts it up.
    // But standard label is 0..H.
    
    // Let's assume the gradient should cover the text height, regardless of absolute position.
    // But we need a reference point.
    
    float t_y = (local_y - offset_y) / use_height;

    // Use smoothstep for better visual if range is slighty off
	vec4 gradient_color = mix(color_top, color_bottom, clamp(t_y, 0.0, 1.0));
	
    // 3. Shimmer
    // Shimmer needs to traverse the whole text width, so we use VERTEX.x / width_pixels
    // Fallback if width is 0 protects against division by zero
    float valid_width = max(width_pixels, 1.0);
    float t_x = v_position.x / valid_width;
	float time = TIME * shimmer_speed;
	float shimmer_pos = mod(time, 3.0) - 0.5;
	float dist = abs(t_x - shimmer_pos + t_y * 0.3); 
	float shimmer_val = smoothstep(shimmer_size, 0.0, dist) * shimmer_intensity;
	
    // 4. Combine
	vec3 final_rgb = gradient_color.rgb + vec3(shimmer_val);
    
    // Output
	vec4 final_color = vec4(final_rgb, gradient_color.a) * text_sample;
    
    // We intentionally ignore COLOR.rgb (font color) to ensure our gradient is visible
    // But we preserve alpha for fade-in animations
    final_color.a *= COLOR.a; 
    COLOR = final_color;
}
