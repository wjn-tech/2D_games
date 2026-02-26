shader_type canvas_item;

uniform vec4 color_start : source_color = vec4(0.9, 0.4, 1.0, 1.0);
uniform vec4 color_end : source_color = vec4(0.4, 0.9, 1.0, 1.0);

void fragment() {
    float t = UV.x; 
    vec4 gradient_color = mix(color_start, color_end, t);
    
    // Sample the text texture (the letters themselves)
    vec4 text_color = texture(TEXTURE, UV);
    
    // Apply gradient only where the text exists
    COLOR = text_color * gradient_color;
}