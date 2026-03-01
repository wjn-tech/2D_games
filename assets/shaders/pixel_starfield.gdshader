shader_type canvas_item;

uniform vec4 bg_color : source_color = vec4(0.102, 0.102, 0.18, 1.0); // #1A1A2E
uniform vec2 resolution = vec2(1920.0, 1080.0);
uniform float star_density = 0.005;
uniform float scroll_speed = 0.05;

// Hash function for randomness
float random(vec2 uv) {
    return fract(sin(dot(uv.xy, vec2(12.9898,78.233))) * 43758.5453123);
}

void fragment() {
	// Pixelate UV
	vec2 pixel_uv = floor(UV * resolution) / resolution;
	
	// Scrolling
	vec2 scrolled_uv = pixel_uv + vec2(TIME * scroll_speed * 0.1, TIME * scroll_speed * 0.05);
	
	// Star generation
	float star = 0.0;
	float rnd = random(floor(scrolled_uv * resolution)); // Random per pixel
	
	if (rnd > (1.0 - star_density)) {
		// Blinking effect
		float blink = sin(TIME * 2.0 + rnd * 100.0) * 0.5 + 0.5;
		star = step(0.5, blink); // Hard blinking for pixel feel
	}
	
	// Combine
	vec4 final_color = mix(bg_color, vec4(1.0, 1.0, 0.8, 1.0), star);
	
	COLOR = final_color;
}
