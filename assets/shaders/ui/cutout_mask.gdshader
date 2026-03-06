shader_type canvas_item;

uniform vec4 target_rect; // x, y, w, h
uniform float feather : hint_range(0.0, 50.0) = 5.0;
uniform vec2 screen_size;

void fragment() {
	vec2 pixel_pos = SCREEN_UV * screen_size;
	
	vec2 tl = target_rect.xy;
	vec2 size = target_rect.zw;
	
	// Distance to rect
	vec2 center = tl + size * 0.5;
	vec2 half_size = size * 0.5;
	
	vec2 p = pixel_pos - center;
	vec2 d = abs(p) - half_size;
	float dist_sq = length(max(d, vec2(0.0)));
	float dist_in = min(max(d.x, d.y), 0.0);
	float dist = dist_sq + dist_in;
	
	float alpha = smoothstep(0.0, feather, dist);
	
	COLOR = vec4(0.0, 0.0, 0.0, 0.6 * alpha);
}