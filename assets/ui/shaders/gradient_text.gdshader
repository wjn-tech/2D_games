shader_type canvas_item;

uniform sampler2D gradient;
uniform float angle : hint_range(0.0, 6.28318) = 0.0;

void fragment() {
    float pivot = 0.5;
    vec2 uv = UV - pivot;
    float rotated_x = uv.x * cos(angle) - uv.y * sin(angle);
    float gradient_pos = rotated_x + pivot;
    
    vec4 gradient_color = texture(gradient, vec2(gradient_pos, 0.0));
    vec4 text_color = texture(TEXTURE, UV);
    
    COLOR = text_color * gradient_color;
}