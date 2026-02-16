shader_type canvas_item;

uniform sampler2D noise_tex : repeat_enable;
uniform vec4 base_color : source_color = vec4(0.2, 0.5, 1.0, 1.0);
uniform vec4 glow_color : source_color = vec4(1.5, 2.0, 5.0, 1.0);
uniform float flow_speed = 3.0;

void fragment() {
    // Pixelate UV for that digital/magical look
    vec2 grid_uv = floor(UV * 32.0) / 32.0;
    
    // Create dual-scrolling noise for a fluid plasma feel
    float n1 = texture(noise_tex, grid_uv + vec2(TIME * flow_speed * 0.5, 0.0)).r;
    float n2 = texture(noise_tex, grid_uv * 1.5 - vec2(TIME * flow_speed * 0.3, TIME * 0.1)).r;
    
    // Smoothly blend the two noise samples
    float combined_noise = mix(n1, n2, 0.5);
    
    // Create a high-contrast but smooth central core (The "Liquid Light")
    float pulse = sin(TIME * 10.0 + UV.x * 20.0) * 0.1 + 0.9;
    float mask = smoothstep(0.3, 0.7, combined_noise * pulse);
    
    // HDR color output
    vec4 final_color = mix(base_color, glow_color, mask);
    
    // Add a rhythmic edge flicker
    float edge = 1.0 - abs(UV.y - 0.5) * 2.0;
    final_color.a *= smoothstep(0.0, 0.2, edge);
    
    COLOR = final_color;
}
    // Circle mask
    float dist = distance(UV, vec2(0.5));
    if (dist > 0.4) discard;
    
    COLOR = final_color * flicker;
}
