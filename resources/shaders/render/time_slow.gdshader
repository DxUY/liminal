shader_type canvas_item;

uniform float progress : hint_range(0.0, 1.0) = 0.0;
uniform float strength : hint_range(0.0, 0.1) = 0.08;
uniform vec2 center = vec2(0.5, 0.5);

uniform float aberration : hint_range(0.0, 1.0) = 0.425;
uniform float width : hint_range(0.0, 0.1) = 0.04;
uniform float feather : hint_range(0.0, 1.0) = 0.135;
uniform bool grayscale_enabled = false;

uniform sampler2D SCREEN_TEXTURE : hint_screen_texture;

void fragment() {
    float radius = progress;
    vec2 aspect = vec2(1.0, SCREEN_PIXEL_SIZE.y / SCREEN_PIXEL_SIZE.x);
    
    vec2 dist_center = ((SCREEN_UV - vec2(0.0, 0.5)) / aspect + vec2(0.0, 0.5)) - center;
    float dist = length(dist_center);

    float activation = smoothstep(0.001, 0.02, progress);
    float ring_mask = (1.0 - smoothstep(radius - feather, radius, dist)) *
                      smoothstep(radius - width - feather, radius - width, dist) * activation;
    float inner_mask = (1.0 - smoothstep(radius, radius + feather, dist)) * activation;

    vec2 offset = normalize(dist_center) * strength * ring_mask;
    vec2 final_st = mix(SCREEN_UV, SCREEN_UV - offset, ring_mask);
    vec2 abber_vec = offset * aberration;

    vec4 ori = texture(SCREEN_TEXTURE, final_st);
    vec4 distorted = vec4(
        texture(SCREEN_TEXTURE, final_st + abber_vec).r,
        ori.g,
        texture(SCREEN_TEXTURE, final_st - abber_vec).b,
        1.0
    );

    COLOR = mix(distorted, vec4(1.0 - ori.rgb, 1.0), inner_mask);
    
    // Only apply grayscale globally if the effect loop has finished (progress is back down to 0)
    bool is_effect_done = progress <= 0.001;
    if (grayscale_enabled && is_effect_done) {
        float gray = dot(COLOR.rgb, vec3(0.299, 0.587, 0.114));
        COLOR.rgb = vec3(gray);
    }
}