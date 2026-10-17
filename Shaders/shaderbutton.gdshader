shader_type canvas_item;

uniform vec4 base_color : source_color = vec4(0.0, 0.5, 1.0, 1.0); // Azul
uniform float fade_length : hint_range(0.0, 1.0) = 0.4; // Tamanho do gradiente na esquerda
uniform float hover_alpha : hint_range(0.0, 1.0) = 0.4; // Controle da transparência geral (mouse hover)

void fragment() {
    // Calcula o alpha do gradiente horizontal
    float fade_alpha = smoothstep(0.0, fade_length, UV.x);
    
    // Pega a textura base e combina com a cor base
    vec4 tex = texture(TEXTURE, UV);
    COLOR = base_color * tex;
    
    // Multiplica o alpha da textura, do gradiente na esquerda e do hover
    COLOR.a *= fade_alpha * hover_alpha;
}