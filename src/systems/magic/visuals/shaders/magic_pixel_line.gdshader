shader_type canvas_item;

uniform float line_width = 2.0;
uniform vec4 line_color : source_color;

void fragment() {
	// Simple color override
	// For better pixelation, we might use UV quantization
	// but Line2D with proper texture mode is usually enough.
	COLOR = line_color * texture(TEXTURE, UV);
}
