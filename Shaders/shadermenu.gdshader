shader_type canvas_item;
render_mode unshaded;

uniform vec4 background_color : source_color = vec4(0.012, 0.025, 0.065, 1.0);
uniform vec4 cyan_color : source_color = vec4(0.12, 1.0, 0.78, 1.0);
uniform vec4 anomaly_color : source_color = vec4(1.0, 0.12, 0.55, 1.0);
uniform vec2 reference_resolution = vec2(1280.0, 720.0);

group_uniforms Particles;
uniform float particle_amount : hint_range(0.0, 100.0, 1.0) = 43.0;
uniform float particle_density : hint_range(2.0, 150.0, 1.0) = 70.0;
uniform float speed : hint_range(0.0, 3.0, 0.01) = 0.12;
uniform float glow_strength : hint_range(0.0, 5.0, 0.1) = 1.8;
uniform float pixel_size : hint_range(1.0, 16.0, 1.0) = 2.0;
uniform float fade_speed : hint_range(0.0, 3.0, 0.01) = 0.7;
uniform float minimum_brightness : hint_range(0.0, 1.0, 0.01) = 0.2;
uniform float initial_brightness : hint_range(0.0, 2.0, 0.01) = 0.9;
uniform float pulse_speed : hint_range(0.0, 3.0, 0.01) = 0.45;
uniform float pulse_strength : hint_range(0.0, 1.0, 0.01) = 0.65;
uniform float pulse_scale : hint_range(0.1, 20.0, 0.1) = 4.0;
group_uniforms;

group_uniforms Purple_Particles;
uniform bool enable_purple_particles = true;
uniform vec4 purple_particle_color : source_color = vec4(0.65, 0.25, 1.0, 1.0);
uniform float purple_amount : hint_range(0.0, 100.0, 1.0) = 5.0;
uniform float purple_density : hint_range(2.0, 100.0, 1.0) = 42.0;
uniform float purple_speed : hint_range(0.0, 3.0, 0.01) = 0.08;
uniform float purple_brightness : hint_range(0.0, 3.0, 0.05) = 0.65;
uniform float purple_pixel_size : hint_range(1.0, 8.0, 1.0) = 2.0;
group_uniforms;

group_uniforms Blue_Light_Rays;
uniform bool enable_rays = true;
uniform int ray_amount : hint_range(0, 30, 1) = 12;
uniform float ray_intensity : hint_range(0.0, 2.0, 0.01) = 0.22;
uniform float ray_width : hint_range(0.005, 0.15, 0.001) = 0.025;
uniform float ray_speed : hint_range(0.0, 2.0, 0.01) = 0.06;
uniform float ray_angle : hint_range(-1.0, 1.0, 0.01) = 0.30;
uniform float ray_pixel_size : hint_range(1.0, 16.0, 1.0) = 6.0;
uniform vec4 ray_color : source_color = vec4(0.05, 0.55, 1.0, 1.0);
group_uniforms;

group_uniforms Anomalies;
uniform float anomaly_strength : hint_range(0.0, 1.0, 0.01) = 0.18;
group_uniforms;

group_uniforms Magical_Plants;
uniform bool enable_plants = true;
uniform int vine_count : hint_range(0, 12, 1) = 7;
uniform float vine_length : hint_range(0.1, 0.9, 0.01) = 0.45;
uniform float vine_thickness : hint_range(0.002, 0.03, 0.001) = 0.009;
uniform float leaf_size : hint_range(0.005, 0.06, 0.001) = 0.028;
uniform float wind_strength : hint_range(0.0, 0.05, 0.001) = 0.018;
uniform float wind_speed : hint_range(0.0, 3.0, 0.01) = 0.85;
uniform bool side_plants = true;
uniform float side_plant_size : hint_range(0.05, 0.5, 0.01) = 0.28;
uniform float plant_glow : hint_range(0.0, 3.0, 0.01) = 1.2;
uniform float plant_pixel_size : hint_range(1.0, 16.0, 1.0) = 4.0;
uniform vec4 plant_dark : source_color = vec4(0.012, 0.09, 0.10, 1.0);
uniform vec4 plant_light : source_color = vec4(0.035, 0.24, 0.20, 1.0);
uniform vec4 plant_bioluminescence : source_color = vec4(0.15, 0.65, 0.50, 1.0);
group_uniforms;

group_uniforms Fireflies;
uniform bool enable_fireflies = true;
uniform int firefly_count : hint_range(0, 40, 1) = 22;
uniform float firefly_size : hint_range(1.0, 6.0, 1.0) = 2.0;
uniform float firefly_brightness : hint_range(0.1, 5.0, 0.1) = 2.5;
uniform float firefly_cycle : hint_range(3.0, 18.0, 0.5) = 8.0;
uniform float firefly_flight_range : hint_range(0.02, 0.35, 0.01) = 0.13;
uniform vec4 firefly_color : source_color = vec4(0.72, 1.0, 0.35, 1.0);
group_uniforms;

float hash21(vec2 p) {
    p = fract(p * vec2(123.34, 456.21));
    p += dot(p, p + 45.32);
    return fract(p.x * p.y);
}

float noise2d(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    vec2 u = f * f * (3.0 - 2.0 * f);
    return mix(mix(hash21(i), hash21(i + vec2(1.0, 0.0)), u.x),
               mix(hash21(i + vec2(0.0, 1.0)), hash21(i + vec2(1.0, 1.0)), u.x), u.y);
}

float leaf_mask(vec2 p, vec2 c, vec2 dir, float size) {
    dir = normalize(dir);
    vec2 d = p - c;
    return 1.0 - step(1.0,
        abs(dot(d, dir)) / max(size, 0.0001) +
        abs(dot(d, vec2(-dir.y, dir.x))) / max(size * 0.55, 0.0001));
}

vec3 particle_layer(vec2 uv, float t, float scale, float seed, float amp) {
    vec2 p = uv * scale;
    p.y += t * (0.15 + seed * 0.008);
    p.x += sin(p.y * 0.6 + t * 0.4 + seed) * 0.18;
    vec2 cell = floor(p);
    vec2 local = fract(p);
    vec3 acc = vec3(0.0);
    for (int x = -1; x <= 1; x++) {
        for (int y = -1; y <= 1; y++) {
            vec2 id = cell + vec2(float(x), float(y));
            float r = hash21(id + vec2(seed));
            if (r < 1.0 - particle_amount * 0.01) { continue; }
            vec2 pos = vec2(float(x), float(y))
                + vec2(hash21(id + vec2(12.4, 7.2)), hash21(id + vec2(4.8, 19.1)))
                + vec2(sin(t * 0.7 + r * 6.283) * 0.12, cos(t * 0.5 + r * 6.283) * 0.08);
            float core = 1.0 - step(mix(0.009, 0.019, r),
                max(abs(local.x - pos.x), abs(local.y - pos.y)));
            float fade = 0.5 + 0.5 * sin(t * fade_speed * (0.6 + r * 0.8) + r * 6.283);
            float pulse = 0.5 + 0.5 * sin(t * pulse_speed * 6.283
                + hash21(floor(id / max(pulse_scale, 0.01))) * 6.283);
            vec3 pcol = mix(cyan_color.rgb, vec3(0.22, 0.88, 0.70), step(0.78, r));
            acc += pcol * (core * mix(minimum_brightness, initial_brightness, fade)
                * mix(1.0, pulse, pulse_strength) * amp);
        }
    }
    return acc;
}

vec3 purple_particle_layer(vec2 uv) {
    if (!enable_purple_particles || purple_amount <= 0.0) {
        return vec3(0.0);
    }
    vec2 grid = max(floor(reference_resolution / max(purple_pixel_size, 1.0)), vec2(1.0));
    vec2 p_uv = (floor(uv * grid) + 0.5) / grid;
    vec2 p = p_uv * purple_density;
    p.y += TIME * purple_speed * 0.5;
    p.x += sin(TIME * purple_speed + p.y * 0.4) * 0.12;
    vec2 cell = floor(p);
    vec2 local = fract(p);
    vec3 acc = vec3(0.0);
    for (int x = -1; x <= 1; x++) {
        for (int y = -1; y <= 1; y++) {
            vec2 id = cell + vec2(float(x), float(y));
            float r = hash21(id + vec2(71.3, 29.7));
            if (r > purple_amount * 0.01) { continue; }
            vec2 center = vec2(float(x), float(y))
                + vec2(hash21(id + vec2(2.3, 9.1)), hash21(id + vec2(8.7, 4.2)));
            center += vec2(sin(TIME * purple_speed * 1.7 + r * 6.283),
                cos(TIME * purple_speed * 1.3 + r * 6.283)) * 0.12;
            float d = max(abs(local.x - center.x), abs(local.y - center.y));
            float core = 1.0 - step(0.055, d);
            float pulse = 0.45 + 0.55 * (0.5 + 0.5 * sin(TIME * 1.3 + r * 19.0));
            acc += purple_particle_color.rgb * core * pulse * purple_brightness;
        }
    }
    return acc;
}

vec3 blue_light_rays(vec2 uv) {
    if (!enable_rays || ray_amount <= 0) { return vec3(0.0); }
    vec2 grid = max(floor(reference_resolution / max(ray_pixel_size, 1.0)), vec2(1.0));
    vec2 p = (floor(uv * grid) + 0.5) / grid;
    float denom = float(max(ray_amount, 1));
    vec3 acc = vec3(0.0);
    int n = min(ray_amount, 8);
    for (int i = 0; i < n; i++) {
        float fi = float(i);
        float r = hash21(vec2(fi, 7.3));
        float center = (fi + 0.5) / denom + (r - 0.5) * 0.025
            + p.y * ray_angle * (0.7 + r * 0.6)
            + sin(TIME * ray_speed + fi * 1.7) * 0.018;
        float beam = 1.0 - smoothstep(0.0, max(ray_width * (0.6 + r * 0.8), 0.001),
            abs(p.x - center));
        acc += ray_color.rgb * (beam * pow(1.0 - p.y, 1.15)
            * (0.8 + 0.2 * sin(TIME * 0.5 + fi * 2.3))
            * (0.5 + r * 0.5) * ray_intensity);
    }
    return acc;
}

vec2 vine_stem(int i, float r, float t) {
    float fi = float(i);
    float x = (fi + 0.5) / float(max(vine_count, 1)) + (r - 0.5) * 0.06
        + sin(t * 4.5 + fi) * 0.02 * t
        + sin(TIME * wind_speed + fi * 2.4 + t * 3.0) * wind_strength * t;
    return vec2(x, t * vine_length * (0.65 + r * 0.5));
}

vec4 vine_leaf(int i, float r, int j) {
    float fi = float(i);
    float t = float(j + 1) / 12.0;
    float side = mod(float(j), 2.0) < 1.0 ? -1.0 : 1.0;
    float flut = sin(TIME * (wind_speed * 2.1) + fi * 2.4 + float(j) * 1.7)
        * wind_strength * 0.65;
    vec2 dir = normalize(normalize(vec2(side, 0.5)) + vec2(flut * 5.0, 0.0));
    return vec4(vine_stem(i, r, t) + dir * leaf_size * 0.75
        + vec2(flut, flut * 0.25), dir);
}

vec4 draw_vines(vec2 uv) {
    vec3 col = vec3(0.0);
    float a = 0.0;
    if (!enable_plants) { return vec4(col, a); }
    int n = min(vine_count, 7);
    for (int i = 0; i < n; i++) {
        float fi = float(i);
        float r = hash21(vec2(fi, 4.2));
        float t = uv.y / (vine_length * (0.65 + r * 0.5));
        if (t < 0.0 || t > 1.0) { continue; }
        vec2 sp = vine_stem(i, r, t);
        if (abs(uv.x - sp.x) > leaf_size * 3.0 + 0.02) { continue; }
        float stem = 1.0 - step(vine_thickness, abs(uv.x - sp.x));
        col = mix(col, mix(plant_dark.rgb, plant_light.rgb, r * 0.65), stem);
        a = max(a, stem);
        int jn = int(floor(t * 12.0 + 0.5)) - 1;
        for (int l = -1; l <= 1; l++) {
            int j = jn + l;
            if (j < 1 || j > 10) { continue; }
            float rj = hash21(vec2(fi * 7.0, float(j) * 3.0));
            vec4 lf = vine_leaf(i, r, j);
            float leaf = leaf_mask(uv, lf.xy, lf.zw, leaf_size * (0.8 + rj * 0.4));
            col = mix(col, mix(plant_dark.rgb, plant_light.rgb, 0.5 + rj * 0.5), leaf);
            a = max(a, leaf);
            if (rj >= 0.55) {
                float dotm = 1.0 - step(0.006,
                    max(abs(uv.x - lf.x), abs(uv.y - lf.y)));
                float pulse = 0.5 + 0.5 * sin(TIME * 1.5 + fi * 2.0 + float(j));
                col = mix(col, plant_bioluminescence.rgb
                    * plant_glow * (0.5 + pulse * 0.5), dotm);
                a = max(a, dotm);
            }
        }
    }
    return vec4(col, a);
}

vec2 branch_point(float fb, float ph, vec2 anchor, float Lb, float side, float t) {
    float sway = sin(TIME * wind_speed + fb * 1.8 + t * 2.2 + ph) * wind_strength * t;
    return anchor + vec2(side * Lb * t + sway, -Lb * (0.26 * t + 0.15 * t * t));
}

vec4 draw_side_plants(vec2 uv) {
    vec3 col = vec3(0.0);
    float a = 0.0;
    if (!enable_plants || !side_plants) { return vec4(col, a); }
    float m = leaf_size * 2.0 + 0.02;
    for (int s = 0; s < 2; s++) {
        float side = s == 0 ? 1.0 : -1.0;
        float edge = s == 0 ? 0.0 : 1.0;
        float ph = float(s) * 2.3;
        float tt = (1.04 - uv.y) / 0.85;
        if (tt >= 0.0 && tt <= 1.0) {
            float x = edge + side * (0.015 + 0.034 * tt)
                + side * sin(tt * 5.0 + TIME * wind_speed + ph) * wind_strength * tt;
            float trunk = 1.0 - step(max(vine_thickness * 0.85, 0.003), abs(uv.x - x));
            col = mix(col, plant_light.rgb * 0.68, trunk);
            a = max(a, trunk);
        }
        for (int b = 0; b < 5; b++) {
            float fb = float(b);
            float ta = 0.18 + fb * 0.155;
            float Lb = side_plant_size * (0.38 + 0.14 * hash21(vec2(fb, ph + 13.0)));
            vec2 anchor = vec2(edge + side * (0.015 + 0.034 * ta)
                + side * sin(ta * 5.0 + TIME * wind_speed + ph) * wind_strength * ta,
                1.04 - ta * 0.85);
            float rx = side * (uv.x - anchor.x);
            if (rx < -m || rx > Lb + m
                || uv.y > anchor.y + m || uv.y < anchor.y - 0.45 * Lb - m) { continue; }
            float t = clamp(rx / Lb, 0.0, 1.0);
            vec2 bp = branch_point(fb, ph, anchor, Lb, side, t);
            t = clamp(t + side * (uv.x - bp.x) / Lb, 0.0, 1.0);
            bp = branch_point(fb, ph, anchor, Lb, side, t);
            float stem = 1.0 - step(max(vine_thickness * (1.0 - t * 0.5), 0.0025),
                max(abs(uv.x - bp.x), abs(uv.y - bp.y)));
            col = mix(col, mix(plant_dark.rgb, plant_light.rgb, 0.65), stem);
            a = max(a, stem);
            int sn = int(floor(t * 7.0 + 0.5));
            for (int l = -1; l <= 1; l++) {
                int seg = sn + l;
                if (seg < 2 || seg > 6) { continue; }
                float fseg = float(seg);
                vec2 cp = branch_point(fb, ph, anchor, Lb, side, fseg / 7.0);
                float lside = mod(fseg, 2.0) < 1.0 ? -1.0 : 1.0;
                float flut = sin(TIME * wind_speed * 2.0 + fb * 2.3 + fseg * 1.9 + ph)
                    * wind_strength * 0.55;
                vec2 dir = normalize(vec2(side * 0.6, lside + flut * 8.0));
                vec2 lc = cp + dir * leaf_size * 0.75 + vec2(flut, 0.0);
                float leaf = leaf_mask(uv, lc, dir,
                    leaf_size * (0.8 + 0.18 * hash21(vec2(fb, fseg))));
                col = mix(col, plant_light.rgb * 0.9, leaf);
                a = max(a, leaf);
                if (hash21(vec2(fb + 9.0, fseg + ph)) >= 0.70) {
                    float dotm = 1.0 - step(0.0027,
                        max(abs(uv.x - lc.x), abs(uv.y - lc.y)));
                    float pulse = 0.70 + 0.30 * sin(TIME * 2.1 + fb + fseg);
                    col = mix(col, plant_bioluminescence.rgb * plant_glow * pulse, dotm);
                    a = max(a, dotm);
                }
            }
        }
    }
    return vec4(col, a);
}

vec3 draw_fireflies(vec2 uv, vec2 res) {
    if (!enable_fireflies || !enable_plants || vine_count <= 0 || firefly_count <= 0) {
        return vec3(0.0);
    }
    vec2 puv = (floor(uv * res) + 0.5) / res;
    vec3 acc = vec3(0.0);
    int n = min(firefly_count, 12);
    for (int i = 0; i < n; i++) {
        float fi = float(i);
        float r1 = hash21(vec2(fi, 17.3));
        float r2 = hash21(vec2(fi, 43.8));
        float r3 = hash21(vec2(fi, 91.1));
        int vi = int(floor(r1 * float(vine_count)));
        float rv = hash21(vec2(float(vi), 4.2));
        vec2 target = vine_leaf(vi, rv, 1 + int(floor(r2 * 10.0))).xy;
        float phase = fract(TIME / (firefly_cycle * (0.78 + r3 * 0.5))
            + r1 * 0.91 + r2 * 0.37);
        vec2 away = vec2(r2 < 0.5 ? -1.0 : 1.0, -0.55 - r3 * 0.55)
            * firefly_flight_range * (0.7 + r1 * 0.6);
        float land = smoothstep(0.0, 0.29, phase);
        float leave = smoothstep(0.64, 0.98, phase);
        float flying = (1.0 - land) + leave;
        vec2 pos = target + away * flying
            + vec2(sin(TIME * 4.2 + fi * 2.7), cos(TIME * 3.1 + fi * 1.9)) * 0.008 * flying;
        pos.y -= 0.0025;
        vec2 d = abs((puv - pos) * res);
        if (max(d.x, d.y) > firefly_size + 1.0) { continue; }
        float visible = smoothstep(0.0, 0.09, phase)
            * (1.0 - smoothstep(0.91, 1.0, phase));
        float core = 1.0 - step(firefly_size, max(d.x, d.y));
        float pulse = 0.78 + 0.22 * sin(TIME * 4.0 + fi * 3.1);
        acc += firefly_color.rgb * (core * visible * pulse * firefly_brightness);
    }
    return acc;
}

void fragment() {
    vec2 res = max(reference_resolution, vec2(1.0));
    vec2 grid = max(floor(res / max(pixel_size, 1.0)), vec2(1.0));
    vec2 uv = (floor(UV * grid) + 0.5) / grid;
    float t = TIME * speed;

    vec3 color = background_color.rgb + vec3(0.0, 0.035, 0.055) * (1.0 - uv.y);

    color += particle_layer(uv, t * 0.45, particle_density * 0.65, 1.0, 0.35)
        * glow_strength;
    color += particle_layer(uv, t * 0.8, particle_density, 5.0, 0.7) * glow_strength;

    color += purple_particle_layer(UV);

    color += blue_light_rays(uv);

    float event = 1.0 - smoothstep(0.0, 0.35, abs(mod(TIME, 17.0) - 14.0));
    float distortion = noise2d(uv * 15.0 + vec2(t * 2.0, 0.0));
    color += anomaly_color.rgb
        * (event * smoothstep(0.65, 0.9, distortion) * anomaly_strength);

    vec2 pgrid = max(floor(res / max(plant_pixel_size, 1.0)), vec2(1.0));
    vec2 puv = (floor(UV * pgrid) + 0.5) / pgrid;
    vec4 vines = draw_vines(puv);
    color = mix(color, vines.rgb, vines.a);
    vec4 sides = draw_side_plants(puv);
    color = mix(color, sides.rgb, sides.a);

    color += draw_fireflies(UV, res);

    vec2 c = uv * 2.0 - 1.0;
    color *= clamp(1.0 - 0.35 * dot(c, c), 0.45, 1.0);
    COLOR = vec4(color, 1.0);
}