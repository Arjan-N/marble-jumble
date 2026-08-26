shader_type spatial;
render_mode cull_disabled, specular_disabled, diffuse_lambert;

// Flat, banded shading for the Canyon's rock and its track deck.
//
// The Home screen art this course is drawn from is painted, not rendered: light
// falls on a face in two or three discrete steps with a hard edge between them,
// and nothing has a specular sheen. Godot's default lambert gradient reads as
// smooth plastic by comparison — the first pass at this course looked like
// pastel putty from the race camera for exactly that reason, however the albedo
// was tuned. Quantising the diffuse term is what actually moves it, and it does
// so on every surface at once.
//
// Shadowed rock is *warm* in that art, not grey. That is deliberately not solved
// here: shadow is where the direct term goes to zero and only ambient is left,
// so it is the environment's ambient colour that decides it. See
// `CourseBuilder.decorate_environment`.

// Multiplied over the vertex colour, so one shader serves both the vertex-
// coloured strata and the flat-tinted props.
uniform vec4 tint : source_color = vec4(1.0, 1.0, 1.0, 1.0);

// How many steps the light is quantised into. Two is a hard day/night split,
// four starts looking like an ordinary gradient again; three is the art.
uniform int bands = 3;

// Slab joints across the deck, in metres, from the along-course UV
// `CourseBuilder._build_surface` writes. Zero disables them, which is what
// every surface that is rock rather than paving wants.
uniform float joint_spacing = 0.0;
uniform float joint_width = 0.07;
uniform vec4 joint_tint : source_color = vec4(0.42, 0.34, 0.27, 1.0);
uniform float joint_strength = 0.45;

void fragment() {
	vec3 base = tint.rgb * COLOR.rgb;

	if (joint_spacing > 0.0) {
		// Distance in metres to the nearest joint line, so `joint_width` stays
		// a real width rather than a fraction of the spacing.
		float phase = fract(UV.x / joint_spacing);
		float to_line = min(phase, 1.0 - phase) * joint_spacing;
		float line = 1.0 - smoothstep(joint_width * 0.5, joint_width, to_line);
		base = mix(base, joint_tint.rgb, line * joint_strength);
	}

	ALBEDO = base;
	ROUGHNESS = 1.0;
	METALLIC = 0.0;
}

void light() {
	float ndl = max(dot(normalize(NORMAL), normalize(LIGHT)), 0.0);
	float steps = max(float(bands), 2.0);
	// `floor` gives `steps` levels from 0 to steps-1; dividing by steps-1 puts
	// the brightest one at exactly 1.0 so lit faces reach full albedo.
	float banded = clamp(floor(ndl * steps) / (steps - 1.0), 0.0, 1.0);
	DIFFUSE_LIGHT += ALBEDO * LIGHT_COLOR * ATTENUATION * banded;
}
