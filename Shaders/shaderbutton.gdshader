shader_type canvas_item;

uniform vec4 base_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform float fade_length : hint_range(0.0, 1.0) = 0.4;
uniform float hover_alpha : hint_range(0.0, 1.0) = 0.4;

void fragment() {
    float fade_alpha = smoothstep(0.0, fade_length, UV.x);
    
    vec4 tex = texture(TEXTURE, UV);
    COLOR = base_color * tex;
    
    COLOR.a *= fade_alpha * hover_alpha;
}