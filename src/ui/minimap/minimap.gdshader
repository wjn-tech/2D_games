shader_type canvas_item;

uniform sampler2D fog_texture;
uniform vec2 map_center_offset; // 小地图中心相对于地图纹理中心的偏移 (0-1)
uniform float zoom = 0.5;

void fragment() {
    // 将 UV 缩放到 zoom 级别，并应用偏移
    vec2 centered_uv = (UV - 0.5) * zoom + 0.5 + map_center_offset;
    
    vec4 map_color = texture(TEXTURE, centered_uv);
    float fog_val = texture(fog_texture, centered_uv).r;
    
    // 战争迷雾：未探索部分变黑，已探索可见
    // 可以加一个渐变或者半透明效果
    vec4 final_color = map_color;
    final_color.rgb *= fog_val;
    
    // 如果是完全透明的背景（空气），显示深褐色/背景色，避免看起来像“空洞”
    if (map_color.a < 0.1) {
        // 使用一个比黑色亮一点的背景色 (深褐色表示矿洞背景)
        vec3 bg_color = vec3(0.12, 0.08, 0.05); 
        final_color = vec4(bg_color * fog_val, 0.9 * fog_val);
    }
    
    COLOR = final_color;
}
