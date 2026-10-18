
shader_type canvas_item;

render_mode unshaded;

uniform sampler2D screen_texture :
    hint_screen_texture, filter_nearest;

uniform float darkness : hint_range(0.0, 0.5) = 0.12;

uniform vec4 atmosphere_color : source_color =
    vec4(0.10, 0.16, 0.27, 1.0);

uniform float atmosphere_strength :
    hint_range(0.0, 0.5) = 0.10;

uniform vec4 firefly_color : source_color =
    vec4(0.55, 1.0, 0.85, 1.0);

uniform float firefly_intensity :
    hint_range(0.0, 2.0) = 0.75;

uniform float firefly_density :
    hint_range(2.0, 20.0) = 8.0;

uniform float firefly_size :
    hint_range(0.001, 0.02) = 0.003;

uniform float firefly_speed :
    hint_range(0.0, 2.0) = 0.25;

float hash(vec2 p) {
    return fract(
        sin(dot(p, vec2(127.1, 311.7)))
        * 43758.5453
    );
}

void fragment() {
    vec2 uv = SCREEN_UV;

    vec3 scene = texture(screen_texture, uv).rgb;

    scene *= 1.0 - darkness;

    scene = mix(
        scene,
        scene * atmosphere_color.rgb,
        atmosphere_strength
    );

    float aspect = 1.0 / SCREEN_PIXEL_SIZE.x
        * SCREEN_PIXEL_SIZE.y;

    vec2 p = vec2(uv.x * aspect, uv.y)
        * firefly_density;

    vec2 cell = floor(p);
    vec2 local = fract(p);

    vec3 glow = vec3(0.0);

    for (int x = -1; x <= 1; x++) {
        for (int y = -1; y <= 1; y++) {

            vec2 offset = vec2(float(x), float(y));
            vec2 id = cell + offset;

            float seed = hash(id);

            if (seed > 0.68) {

                float t = TIME * firefly_speed;

                vec2 movement = vec2(
                    sin(t + seed * 15.0),
                    cos(t * 0.7 + seed * 22.0)
                ) * 0.25;

                vec2 center = offset + vec2(
                    hash(id + 3.1),
                    hash(id + 7.3)
                ) + movement;

                vec2 d = local - center;
                float dist = length(d);

                float size = firefly_size
                    * firefly_density;

                float core = 1.0 - smoothstep(
                    size * 0.3,
                    size,
                    dist
                );

                float halo = exp(
                    -dist * dist /
                    max(size * size * 20.0, 0.00001)
                ) * 0.18;

                float pulse = 0.65 + 0.35 * sin(
                    TIME * 1.8 + seed * 20.0
                );

                glow += firefly_color.rgb
                    * (core + halo)
                    * pulse
                    * firefly_intensity;
            }
        }
    }

    COLOR = vec4(
        clamp(scene + glow, vec3(0.0), vec3(1.0)),
        1.0
    );
}
