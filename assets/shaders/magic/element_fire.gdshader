shader_type particles;

uniform float turbulence_intensity = 1.0;
uniform vec4 color_start : source_color = vec4(1.0, 0.5, 0.0, 1.0);
uniform vec4 color_end : source_color = vec4(0.2, 0.2, 0.2, 0.5);

float rand(vec2 co) {
    return fract(sin(dot(co.xy, vec2(12.9898, 78.233))) * 43758.5453);
}

void start() {
    float r = rand(vec2(float(INDEX), TIME));
    VELOCITY = vec3(0.0, -50.0 - r * 50.0, 0.0);
    COLOR = color_start;
    CUSTOM.x = 0.0; // Life progress
}

void process() {
    CUSTOM.x += DELTA * 0.5;
    if (CUSTOM.x > 1.0) {
        ACTIVE = false;
    }
    
    // Low-cost turbulence simulation
    float noise = rand(vec2(TIME, float(INDEX)));
    VELOCITY.x += (noise - 0.5) * turbulence_intensity * 10.0;
    
    COLOR = mix(color_start, color_end, CUSTOM.x);
    TRANSFORM[3].xyz += VELOCITY * DELTA;
}
