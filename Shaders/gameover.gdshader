
shader_type canvas_item;
render_mode unshaded;

// ========================================
// CORES DO CORAÇÃO
// ========================================

uniform vec4 azul_sombra : source_color = vec4(0.005, 0.045, 0.14, 1.0);
uniform vec4 azul_musculo : source_color = vec4(0.025, 0.24, 0.60, 1.0);
uniform vec4 azul_luz : source_color = vec4(0.13, 0.60, 0.96, 1.0);
uniform vec4 azul_veias : source_color = vec4(0.01, 0.09, 0.28, 1.0);

// ========================================
// CONFIGURAÇÕES DO CORAÇÃO
// ========================================

uniform float tamanho : hint_range(0.3, 2.5) = 1.0;
uniform float resolucao_pixel : hint_range(80.0, 640.0) = 260.0;
uniform float velocidade_batimento : hint_range(0.0, 4.0) = 1.1;
uniform float forca_batimento : hint_range(0.0, 0.15) = 0.035;

// ========================================
// CONFIGURAÇÕES DA NÉVOA
// ========================================

uniform vec4 cor_nevoa : source_color = vec4(0.55, 0.57, 0.62, 1.0);

uniform float opacidade_nevoa : hint_range(0.0, 1.0) = 0.05;
uniform float velocidade_nevoa : hint_range(0.0, 2.0) = 0.18;
uniform float densidade_nevoa : hint_range(0.1, 3.0) = 0.5;

// ========================================
// FUNÇÕES GEOMÉTRICAS
// ========================================

float ellipse_sdf(vec2 p, vec2 c, vec2 r) {
    return (length((p - c) / r) - 1.0) * min(r.x, r.y);
}

float capsule_sdf(vec2 p, vec2 a, vec2 b, float r) {
    vec2 q = p - a;
    vec2 v = b - a;
    float h = clamp(dot(q, v) / dot(v, v), 0.0, 1.0);
    return length(q - v * h) - r;
}

// ========================================
// FORMATO ANATÔMICO DO CORAÇÃO
// ========================================

float heart_shape(vec2 p) {
    // Corpo principal volumoso
    float d = ellipse_sdf(
        p, vec2(-0.025, 0.065), vec2(0.345, 0.310)
    );

    // Ventrículo esquerdo
    d = min(d, ellipse_sdf(
        p, vec2(0.095, 0.180), vec2(0.250, 0.285)
    ));

    // Ventrículo direito
    d = min(d, ellipse_sdf(
        p, vec2(-0.170, 0.090), vec2(0.205, 0.245)
    ));

    // Região inferior
    d = min(d, ellipse_sdf(
        p, vec2(0.035, 0.260), vec2(0.235, 0.195)
    ));

    // Ponta anatômica
    d = min(d, capsule_sdf(
        p, vec2(0.015, 0.275), vec2(0.115, 0.425), 0.100
    ));

    // Átrio esquerdo
    d = min(d, ellipse_sdf(
        p, vec2(-0.180, -0.155), vec2(0.145, 0.150)
    ));

    // Átrio direito
    d = min(d, ellipse_sdf(
        p, vec2(0.155, -0.130), vec2(0.145, 0.155)
    ));

    // Aorta ascendente
    d = min(d, capsule_sdf(
        p, vec2(0.035, -0.170), vec2(0.055, -0.390), 0.060
    ));

    // Arco da aorta
    d = min(d, capsule_sdf(
        p, vec2(0.055, -0.390), vec2(-0.025, -0.465), 0.055
    ));

    d = min(d, capsule_sdf(
        p, vec2(-0.025, -0.465), vec2(-0.125, -0.405), 0.049
    ));

    // Ramos da aorta
    d = min(d, capsule_sdf(
        p, vec2(-0.010, -0.450), vec2(-0.015, -0.555), 0.023
    ));

    d = min(d, capsule_sdf(
        p, vec2(0.055, -0.430), vec2(0.085, -0.530), 0.023
    ));

    // Artéria pulmonar
    d = min(d, capsule_sdf(
        p, vec2(-0.080, -0.180), vec2(-0.110, -0.350), 0.055
    ));

    d = min(d, capsule_sdf(
        p, vec2(-0.110, -0.350), vec2(-0.300, -0.390), 0.038
    ));

    // Veia cava
    d = min(d, capsule_sdf(
        p, vec2(-0.190, -0.160), vec2(-0.220, -0.400), 0.042
    ));

    // Vasos laterais
    d = min(d, capsule_sdf(
        p, vec2(0.170, -0.120), vec2(0.300, -0.220), 0.032
    ));

    return d;
}

// ========================================
// RUÍDO PARA A NÉVOA
// ========================================

float noise_nevoa(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);

    f = f * f * (3.0 - 2.0 * f);

    float a = fract(sin(dot(i, vec2(127.1, 311.7))) * 43758.5453);
    float b = fract(sin(dot(i + vec2(1.0, 0.0), vec2(127.1, 311.7))) * 43758.5453);
    float c = fract(sin(dot(i + vec2(0.0, 1.0), vec2(127.1, 311.7))) * 43758.5453);
    float d = fract(sin(dot(i + vec2(1.0, 1.0), vec2(127.1, 311.7))) * 43758.5453);

    return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

float fbm_nevoa(vec2 p) {
    float valor = 0.0;
    float amplitude = 0.5;

    for (int i = 0; i < 4; i++) {
        valor += noise_nevoa(p) * amplitude;
        p *= 2.0;
        amplitude *= 0.5;
    }

    return valor;
}

// ========================================
// FRAGMENT
// ========================================

void fragment() {
    // Pixelização
    vec2 tela = 1.0 / SCREEN_PIXEL_SIZE;

    vec2 grade = vec2(
        resolucao_pixel,
        max(1.0, resolucao_pixel * tela.y / tela.x)
    );

    vec2 uv = (floor(UV * grade) + 0.5) / grade;

    vec2 p = uv - vec2(0.5);
    p.x *= tela.x / tela.y;
    p *= 2.0;

    // ====================================
    // BATIMENTO CARDÍACO
    // ====================================

    float fase = fract(TIME * velocidade_batimento);

    float batida1 = exp(-pow((fase - 0.12) * 18.0, 2.0));
    float batida2 = exp(-pow((fase - 0.29) * 25.0, 2.0));

    float pulso = batida1 + batida2 * 0.45;

    p /= tamanho * (1.0 + pulso * forca_batimento);

    // Inclinação anatômica
    float ang = -0.12;

    mat2 rot = mat2(
        vec2(cos(ang), sin(ang)),
        vec2(-sin(ang), cos(ang))
    );

    p = rot * p;

    // ====================================
    // DESENHO DO CORAÇÃO
    // ====================================

    float d = heart_shape(p);
    float mascara = 1.0 - step(0.0, d);

    // Volume e iluminação
    float luz = clamp(
        0.52 - p.x * 0.85 - p.y * 0.35,
        0.0, 1.0
    );

    vec3 cor = mix(
        azul_sombra.rgb,
        azul_musculo.rgb,
        0.35 + luz * 0.65
    );

    // Reflexo lateral
    float reflexo = ellipse_sdf(
        p, vec2(-0.12, -0.015), vec2(0.105, 0.20)
    );

    float reflexo_mask = 1.0 - smoothstep(
        -0.02, 0.065, reflexo
    );

    cor = mix(
        cor,
        azul_luz.rgb,
        reflexo_mask * 0.34
    );

    // Textura muscular
    float textura = sin(
        p.y * 95.0 + sin(p.x * 31.0) * 2.0
    );

    cor *= 0.93 + 0.07 * textura;

    // Sulco interventricular
    float sulco = capsule_sdf(
        p, vec2(-0.005, -0.075),
        vec2(0.09, 0.34), 0.012
    );

    cor = mix(
        cor,
        azul_veias.rgb,
        (1.0 - step(0.0, sulco)) * 0.85
    );

    // Veias coronárias
    float veia1 = capsule_sdf(
        p, vec2(0.025, 0.07),
        vec2(-0.16, 0.17), 0.009
    );

    float veia2 = capsule_sdf(
        p, vec2(0.055, 0.19),
        vec2(0.20, 0.11), 0.008
    );

    float veia3 = capsule_sdf(
        p, vec2(-0.045, 0.005),
        vec2(-0.21, -0.055), 0.008
    );

    float veias = min(veia1, min(veia2, veia3));

    cor = mix(
        cor,
        azul_veias.rgb,
        (1.0 - step(0.0, veias)) * 0.75
    );

    // Brilho na aorta
    float aorta_luz = capsule_sdf(
        p, vec2(0.015, -0.20),
        vec2(0.028, -0.37), 0.012
    );

    cor = mix(
        cor,
        azul_luz.rgb,
        (1.0 - step(0.0, aorta_luz)) * 0.45
    );

    // Sombras nas bordas
    float borda = 1.0 - smoothstep(
        -0.055, -0.005, d
    );

    cor *= mix(0.65, 1.0, borda);

    // Quantização de cores
    cor = floor(cor * 32.0 + 0.5) / 32.0;

    // ====================================
    // FUNDO PRETO + CORAÇÃO
    // ====================================

    vec3 cor_final = cor * mascara;

    // ====================================
    // NÉVOA CINZA EM MOVIMENTO
    // ====================================

    // Camada 1: para a esquerda
    float nevoa_esquerda = fbm_nevoa(
        uv * vec2(3.0, 4.0) * densidade_nevoa
        + vec2(TIME * velocidade_nevoa, 0.0)
    );

    // Camada 2: para a direita
    float nevoa_direita = fbm_nevoa(
        uv * vec2(5.0, 3.0) * densidade_nevoa
        + vec2(-TIME * velocidade_nevoa * 0.65, 0.5)
    );

    // Mistura das camadas
    float nevoa = nevoa_esquerda * 0.6
                + nevoa_direita * 0.4;

    // Formato das nuvens
    nevoa = smoothstep(0.25, 0.65, nevoa);

    // Pixelização da névoa
    nevoa = floor(nevoa * 8.0 + 0.5) / 8.0;

    // Opacidade máxima de 50%
    float alpha_nevoa = nevoa * opacidade_nevoa;

    // Névoa passando na frente do coração
    cor_final = mix(
        cor_final,
        cor_nevoa.rgb,
        alpha_nevoa
    );

    COLOR = vec4(cor_final, 1.0);
}
