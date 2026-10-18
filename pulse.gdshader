
shader_type canvas_item;
render_mode unshaded;

uniform float progress : hint_range(0.0, 1.0) = 0.0;
uniform float pulse : hint_range(0.0, 1.0) = 0.0;

uniform vec4 core_color : source_color =
    vec4(0.25, 0.72, 1.0, 1.0);

uniform vec4 bright_blue : source_color =
    vec4(0.05, 0.45, 1.0, 1.0);

uniform vec4 deep_blue : source_color =
    vec4(0.01, 0.10, 0.32, 1.0);

uniform vec4 fade_color : source_color =
    vec4(0.0, 0.005, 0.025, 1.0);

uniform vec2 reference_resolution = vec2(1280.0, 720.0);

uniform float pixel_size : hint_range(1.0, 16.0, 1.0) = 5.0;

uniform float ring_width : hint_range(0.002, 0.05) = 0.010;

uniform float glow_strength : hint_range(0.0, 2.0) = 0.75;

uniform float detail_strength : hint_range(0.0, 2.0) = 1.0;

float hash21(vec2 p) {
    p = fract(p * vec2(123.34, 456.21));
    p += dot(p, p + 45.32);
    return fract(p.x * p.y);
}

float ring_mask(float dist, float radius, float width) {
    return 1.0 - smoothstep(
        width * 0.35,
        width,
        abs(dist - radius)
    );
}

void fragment() {

    vec2 grid = max(
        floor(reference_resolution / pixel_size),
        vec2(1.0)
    );

    vec2 uv = (floor(UV * grid) + 0.5) / grid;

    vec2 aspect = reference_resolution /
        min(reference_resolution.x, reference_resolution.y);

    vec2 p = (uv - vec2(0.5)) * aspect;

    float dist = length(p);
    float angle = atan(p.y, p.x);

float radius = pulse * 1.35;

    float distortion =
        sin(angle * 12.0 + TIME * 1.7) * 0.004 +
        sin(angle * 24.0 - TIME * 1.1) * 0.002;

    float d = dist + distortion;

float main_ring = ring_mask(
        d, radius, ring_width
    );

    float inner_ring = ring_mask(
        d, max(radius - 0.035, 0.0),
        ring_width * 0.55
    );

    float outer_ring = ring_mask(
        d, radius + 0.030,
        ring_width * 0.45
    );

    float expanded = smoothstep(
        0.04, 0.20, pulse
    );

    inner_ring *= expanded;
    outer_ring *= expanded;

float segment_id = floor(
        (angle + 3.14159265) / 6.2831853 * 48.0
    );

    float segment_noise = hash21(
        vec2(segment_id, 8.0)
    );

    float segment_mask = step(
        0.22, segment_noise
    );

    outer_ring *= segment_mask;

float rune_sector = floor(
        (angle + 3.14159265) / 6.2831853 * 16.0
    );

    float rune_angle = fract(
        (angle + 3.14159265) / 6.2831853 * 16.0
    );

    float rune_position = 1.0 - step(
        0.12,
        abs(rune_angle - 0.5)
    );

    float rune_band = 1.0 - smoothstep(
        0.005,
        0.014,
        abs(d - (radius + 0.065))
    );

    float rune_visibility = step(
        0.35,
        hash21(vec2(rune_sector, 15.0))
    );

    float runes =
        rune_position *
        rune_band *
        rune_visibility *
        expanded;

vec2 particle_cell = floor(
        uv * vec2(110.0, 62.0)
    );

    float particle_random = hash21(
        particle_cell
    );

    float fragment_band = 1.0 - smoothstep(
        0.025,
        0.10,
        abs(d - radius)
    );

    float fragments = step(
        0.92,
        particle_random
    );

    fragments *= fragment_band;
    fragments *= expanded;

float glow = 1.0 - smoothstep(
        ring_width,
        ring_width * 9.0,
        abs(d - radius)
    );

    glow *= glow_strength;

vec3 color = fade_color.rgb;

    color += deep_blue.rgb *
        outer_ring * 1.8;

    color += bright_blue.rgb *
        inner_ring * 0.8;

    color += core_color.rgb *
        main_ring * 1.2;

    color += bright_blue.rgb *
        runes * detail_strength;

    color += core_color.rgb *
        fragments * 0.75;

    color += bright_blue.rgb *
        glow * 0.55;

vec2 fade_cell = floor(
        uv * vec2(100.0, 56.0)
    );

    float fade_noise = hash21(
        fade_cell
    );

    float darkness = smoothstep(
        0.0,
        0.22,
        progress * 1.35 - fade_noise * 0.35
    );

    darkness = mix(
        darkness,
        1.0,
        smoothstep(0.88, 1.0, progress)
    );

    float visibility = 1.0 -
        smoothstep(0.88, 1.0, progress);

    color = mix(
        fade_color.rgb,
        color,
        visibility
    );

    float effect_alpha = clamp(
        main_ring +
        inner_ring * 0.6 +
        outer_ring * 0.5 +
        runes +
        fragments * 0.7 +
        glow * 0.35,
        0.0,
        1.0
    );

    float alpha = max(
        darkness,
        effect_alpha * visibility
    );

    COLOR = vec4(color, alpha);
}
