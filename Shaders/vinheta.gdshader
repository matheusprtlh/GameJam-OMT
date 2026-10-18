shader_type canvas_item;

uniform vec4 shadow_color : source_color = vec4(0.0, 0.0, 0.0, 1.0);
uniform float outer_radius : hint_range(0.0, 2.0) = 1.0;
uniform float inner_radius : hint_range(0.0, 2.0) = 0.3;
uniform float softness : hint_range(0.0, 1.0) = 0.5;
uniform bool horizontal_only = false;

void fragment() {
    float alpha = 0.0;
    
    if (horizontal_only) {
        float dist = abs(UV.x - 0.5) * 2.0;
        alpha = smoothstep(inner_radius, outer_radius, dist);
    } else {
        float dist = distance(UV, vec2(0.5));
        alpha = smoothstep(inner_radius * 0.5, outer_radius * 0.5, dist);
    }

    COLOR = vec4(shadow_color.rgb, alpha * shadow_color.a);
}