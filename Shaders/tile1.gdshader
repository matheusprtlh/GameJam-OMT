shader_type canvas_item;

// Controla a saturação: 1.0 é cor normal, 0.0 é totalmente cinza
uniform float saturacao : hint_range(0.0, 1.0) = 1.0;

void fragment() {
    vec4 tex_color = texture(TEXTURE, UV);
    
    // Calcula o valor de luminância (tom de cinza relativo)
    float gray = dot(tex_color.rgb, vec3(0.299, 0.587, 0.114));
    
    // Interpola suavemente entre a cor original e o tom de cinza
    tex_color.rgb = mix(vec3(gray), tex_color.rgb, saturacao);
    
    COLOR = tex_color;
}