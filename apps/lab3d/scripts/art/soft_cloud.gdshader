// A soft see-through cloud (#156, 2026-11-16 user: the ink spreads as a soft blue cloud, SoftCloud):
// a few smooth lumps whose alpha fades to nothing where they turn away from the eye (their edges blur
// away) and whose colour is a little deeper where they face it (the core). Overlapping lumps add up.
// Unshaded; `tint` is linear (a Vector4, as ArtKit's yarn tint: the renderers convert Color uniforms
// differently); story_tint dims it at the story's night.
shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_never, cull_back, specular_disabled;

uniform vec4 tint = vec4(0.1, 0.2, 0.8, 1.0);   // linear rgb
uniform float density = 0.6;   // alpha where a lump faces the eye
uniform float edge = 1.6;      // how fast the alpha falls towards a lump's edge (larger: softer, smaller cloud)
uniform float core = 0.7;      // the core's colour as a share of the edge's (1: the same)

global uniform vec3 story_tint;

void fragment() {
	float facing = clamp(dot(normalize(NORMAL), normalize(VIEW)), 0.0, 1.0);
	vec3 color = tint.rgb * mix(1.0, core, facing) * story_tint;
	if (OUTPUT_IS_SRGB) {
		color = mix(1.055 * pow(max(color, vec3(0.0)), vec3(1.0 / 2.4)) - 0.055, color * 12.92, lessThan(color, vec3(0.0031308)));
	}
	ALBEDO = color;
	ALPHA = density * pow(facing, edge);
}
