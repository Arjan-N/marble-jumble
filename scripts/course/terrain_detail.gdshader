shader_type spatial;
render_mode diffuse_lambert, specular_disabled, cull_back;

// Breaks up the flat albedo of a generated surface without needing UVs.
//
// Every course mesh here is built by `SurfaceTool` from raw vertices and only
// `generate_normals` is called, so there are no texture coordinates to sample a
// texture with and no sane way to author them for a banked, variable-width
// channel. World-space value noise sidesteps that entirely: it needs nothing
// from the mesh but position and normal, and it tiles across separate meshes —
// the channel and the jungle floor below it are different `MeshInstance3D`s and
// still read as one continuous material.
//
// Two octaves on the horizontal plane only, which is four hashes each. A full
// triplanar blend would be three times that for surfaces that are, on this
// course, mostly ground.

uniform vec3 albedo : source_color = vec3(0.29, 0.35, 0.22);
// The second tone the macro noise mixes towards. Large, slow patches of it are
// what stop a hillside reading as one flat colour at distance, which is where
// the detail octave has already blurred away.
uniform vec3 albedo_alt : source_color = vec3(0.22, 0.27, 0.16);
uniform float macro_scale = 0.035;
uniform float macro_strength = 0.85;
uniform float detail_scale = 0.42;
uniform float detail_strength = 0.16;
// How much steeper faces darken. A cheap stand-in for the occlusion a bank or a
// cut face would really have, and the cue that makes a shoulder read as a slope
// rather than as a lighter shade of floor.
uniform float slope_darken = 0.35;

varying vec3 world_position;
varying vec3 world_normal;

float hash2(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453123);
}

float vnoise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	float a = hash2(i);
	float b = hash2(i + vec2(1.0, 0.0));
	float c = hash2(i + vec2(0.0, 1.0));
	float d = hash2(i + vec2(1.0, 1.0));
	return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

void vertex() {
	world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	world_normal = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
}

void fragment() {
	float macro = vnoise(world_position.xz * macro_scale);
	float detail = vnoise(world_position.xz * detail_scale);

	vec3 base = mix(albedo, albedo_alt, clamp(macro * macro_strength, 0.0, 1.0));
	base *= 1.0 + (detail - 0.5) * detail_strength;

	// `world_normal.y` is 1 on the flat and falls off as the surface tilts.
	float flatness = clamp(world_normal.y, 0.0, 1.0);
	base *= mix(1.0 - slope_darken, 1.0, flatness);

	ALBEDO = base;
	ROUGHNESS = 1.0;
	METALLIC = 0.0;
}
