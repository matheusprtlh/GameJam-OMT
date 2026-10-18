shader_type canvas_item;

uniform vec4 base_color : source_color = vec4(0.0, 0.5, 1.0, 1.0);
uniform float fade_length : hint_range(0.0, 1.0) = 0.4;
uniform float hover_alpha : hint_range(0.0, 1.0) = 0.4;
uniform float modo_cromatico : hint_range(0.0, 1.0) = 0.0;
uniform float tempo_cromatico : hint_range(0.0, 1.0) = 0.0;

void fragment() {
    float fade_alpha = smoothstep(0.0, fade_length, UV.x);

    vec4 tex = texture(TEXTURE, UV);

    // degradê cromático animado: arco-íris deslizando no eixo X
    vec3 cor_arco_iris = 0.5 + 0.5 * cos(
        6.28318 * (UV.x * 1.5 + tempo_cromatico) + vec3(0.0, 2.094, 4.188)
    );

    vec3 cor_final = mix(base_color.rgb, cor_arco_iris, modo_cromatico);

    COLOR = vec4(cor_final, base_color.a) * tex;

    COLOR.a *= fade_alpha * hover_alpha;
}