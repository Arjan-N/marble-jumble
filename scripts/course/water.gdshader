shader_type spatial;
render_mode blend_mix, cull_disabled, diffuse_lambert, specular_schlick_ggx;

// A cheap moving-water look for the Compatibility renderer: two panning sine
// ripples fed into the normal so the surface actually catches the sun instead
// of sitting dead flat, plus a fresnel brightening at grazing angles (the
// "you can see the surface, not just the colour" cue real water has) and a
// slow colour drift between a darker base and a lit crest so it reads as
// moving liquid rather than a tinted, static plane.

uniform vec4 water_colour : source_color = vec4(0.10, 0.38, 0.46, 0.88);
uniform vec4 crest_colour : source_color = vec4(0.55, 0.82, 0.80, 0.95);
uniform float speed : hint_range(0.0, 2.0) = 0.35;
uniform float ripple_scale : hint_range(0.5, 8.0) = 2.2;
uniform float ripple_strength : hint_range(0.0, 1.0) = 0.35;
uniform float fresnel_power : hint_range(0.5, 8.0) = 3.0;

void fragment() {
	vec2 uv = UV * ripple_scale;
	float t = TIME * speed;

	// Two ripple sets at different scales/angles so the surface doesn't read
	// as one repeating stripe pattern.
	float wave_a = sin(uv.x * 3.1 + uv.y * 1.7 + t * 2.0);
	float wave_b = sin(uv.x * -1.9 + uv.y * 2.6 - t * 1.3);
	float ripple = (wave_a + wave_b) * 0.5;

	vec3 normal = normalize(vec3(ripple * ripple_strength, 1.0, wave_b * ripple_strength * 0.6));
	NORMAL = normal;

	float fresnel = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), fresnel_power);
	vec3 base = mix(water_colour.rgb, crest_colour.rgb, clamp(ripple * 0.5 + 0.5, 0.0, 1.0) * 0.4);
	ALBEDO = mix(base, crest_colour.rgb, fresnel * 0.6);
	ALPHA = mix(water_colour.a, crest_colour.a, fresnel);

	ROUGHNESS = 0.08;
	SPECULAR = 0.6;
}
