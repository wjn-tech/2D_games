shader_type canvas_item;

uniform vec4 bg_color : source_color = vec4(0.02, 0.02, 0.1, 0.95);  // Deep Space Blue
uniform vec4 flow_color : source_color = vec4(0.0, 0.8, 1.0, 0.3); // Cyan Mist
uniform float speed : hint_range(0.0, 2.0) = 0.2;
uniform float star_density : hint_range(0.0, 1.0) = 0.02; // Keep low for subtlety

// Simple pseudo-random
float random(vec2 st) {
    return fract(sin(dot(st.xy, vec2(12.9898, 78.233))) * 43758.5453123);
}

void fragment() {
    vec2 uv = UV;
    
    // Background Base
    vec4 col = bg_color;
    
    // 1. Flowing Mist (layered sine waves)
    float flow = sin(uv.x * 6.0 + TIME * speed) * cos(uv.y * 6.0 + TIME * speed * 0.7);
    flow += sin(uv.x * 12.0 - TIME * speed * 1.2) * cos(uv.y * 10.0 + TIME * speed * 0.5) * 0.5;
    
    // Normalize flow to 0-1 range roughly and apply mist
    float intensity = smoothstep(0.2, 0.8, (flow + 1.5) * 0.25);
    col = mix(col, flow_color, intensity * flow_color.a);
    
    // 2. Stars
    // Grid-based star generation to avoid noise texture dependency
    vec2 grid_uv = uv * 50.0; // 50x50 grid
    vec2 cell_id = floor(grid_uv);
    vec2 cell_uv = fract(grid_uv);
    
    float rand = random(cell_id);
    
    if (rand < star_density) {
        // Star position inside cell
        vec2 star_pos = vec2(random(cell_id + vec2(1.0)), random(cell_id + vec2(2.0)));
        float dist = distance(cell_uv, star_pos);
        
        // Twinkle
        float twinkle = sin(TIME * 2.0 + rand * 10.0) * 0.5 + 0.5;
        
        // Draw star
        float star = smoothstep(0.1 + twinkle * 0.05, 0.0, dist);
        col += vec4(1.0) * star * twinkle;
    }
    
    COLOR = col;
}
